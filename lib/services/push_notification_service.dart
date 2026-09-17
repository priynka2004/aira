import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../screens/chat_screen.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/notification_detail_screen.dart';
import '../screens/help_center_screen.dart';
import '../utils/app_session.dart';
import '../utils/nav_key.dart';
import '../utils/notification_badge.dart';
import '../utils/service_locator.dart';

/// Must be a *top-level* (or static) function — the OS spins up a fresh,
/// isolated Dart isolate to run this when a push arrives while the app is
/// fully killed/backgrounded, so it can't touch any state from main().
///
/// On Android this always draws the notification itself (for both
/// data-only and hybrid `notification`+`data` payloads), rather than
/// trusting the OS to auto-display a `notification` block. Relying on
/// that OS-level auto-draw turned out to be unreliable on heavily
/// battery-restricted OEM builds (e.g. Vivo/FuntouchOS) — the payload
/// would arrive but nothing showed while the app was backgrounded or
/// killed, because the OS silently skipped the auto-draw. Drawing it
/// ourselves here removes that dependency; the only downside is a rare
/// duplicate on devices where the OS *does* also auto-draw, which is far
/// preferable to a missing notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // A fresh isolate has no Firebase app instance yet — anything touching
  // Firebase (Firestore, etc.) in this handler needs this first. Safe to
  // call even if already initialized elsewhere; wrapped defensively since
  // a duplicate-app error here should never crash message handling.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (kDebugMode) debugPrint('[Push] Firebase.initializeApp in background isolate: $e');
  }

  if (kDebugMode) {
    debugPrint('[Push] background message: ${message.messageId} | ${message.data}');
  }

  if (!Platform.isAndroid) {
    // iOS requires `content-available`/mutable-content + a Notification
    // Service Extension to draw a tray notification from a data-only
    // background push — that's native (Xcode) config outside this repo's
    // lib/ folder, not something fixable in Dart.
    return;
  }

  try {
    // A fresh isolate — none of the singletons on [PushNotificationService]
    // exist here, so the plugin + channel are (re)created locally. Both
    // calls are safe to repeat; the plugin no-ops if already registered
    // and creating an existing channel is a harmless overwrite.
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotifications.initialize(const InitializationSettings(android: androidInit));

    const channel = AndroidNotificationChannel(
      'aira_notifications',
      'AiRA Notifications',
      description: 'Booking, chat and account updates from AiRA',
      importance: Importance.max,
    );
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Prefer the `notification` block's title/body when present (that's
    // what the sender intended to display), falling back to `data` for
    // data-only payloads. We draw this ourselves instead of trusting the
    // OS to auto-display a `notification` payload — on heavily
    // battery-restricted OEM builds (Vivo/FuntouchOS, some Xiaomi/Oppo),
    // that OS-level auto-draw can silently fail to fire while the app is
    // backgrounded/killed, even though the payload arrived. Drawing it
    // ourselves here removes that dependency; worst case on a device
    // where the OS *does* also auto-draw is a rare duplicate, which is
    // far better than a missing notification.
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'AiRA';
    final body = message.notification?.body ??
        message.data['message']?.toString() ??
        message.data['body']?.toString() ??
        '';

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      // Same shape _handleTapPayload expects — guarantees a tap on this
      // notification routes to the right screen, same as the foreground case.
      payload: jsonEncode(message.data),
    );
  } catch (e) {
    if (kDebugMode) debugPrint('[Push] failed to draw background notification: $e');
  }
}

/// One place for everything push-notification related.
///
/// Uses **both** a Firebase topic *and* a Firestore-stored token:
///  • on login, the device subscribes itself to the Firebase topic
///    `user_<userId>` (Firebase's own servers — nothing to save anywhere)
///  • the device's FCM token is also written to Firestore, collection
///    `fcm_tokens`, document id = the user's id — e.g. `fcm_tokens/8`,
///    with fields `userId`, `fcmToken`, `platform`, `isActive`. Backend
///    can read this doc directly to send a push to one specific device,
///    without needing any column in the Django database.
///  • on logout, the device unsubscribes from the topic and flips
///    `isActive` to false on its Firestore token doc
///
/// Besides that, this class also:
///  • asks for notification permission
///  • shows a local notification (tray + lock screen) when a push arrives
///    while the app is in the foreground — Android doesn't do this on its
///    own, only iOS does
///  • routes a tap on any notification (foreground, background, or a cold
///    start from a killed state) to the right screen: the chat if it's a
///    chat message, otherwise the notification detail screen
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _androidChannel = AndroidNotificationChannel(
    'aira_notifications',
    'AiRA Notifications',
    description: 'Booking, chat and account updates from AiRA',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _localNotificationsInitialized = false;
  bool _messagingInitialized = false;

  /// The topic we're currently subscribed to (`user_<userId>`), so we can
  /// cleanly unsubscribe from it on logout.
  String? _subscribedTopic;

  /// Live Firestore listener on `user/<userId>/notifications`, kept only
  /// so the bell's green dot ([NotificationBadge.hasUnread]) reflects an
  /// unread item the instant the backend writes it there — even if the
  /// Notifications screen itself is never opened. Cancelled on logout.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _badgeSub;

  // ── Step 1: local-notifications plugin (call once, early in main()) ────
  Future<void> initLocalNotifications() async {
    if (_localNotificationsInitialized) return;
    _localNotificationsInitialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we ask via FirebaseMessaging.requestPermission instead
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        _handleTapPayload(response.payload);
      },
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_androidChannel);
    // Android 13+ requires this separate runtime permission for the tray;
    // FirebaseMessaging.requestPermission() below covers it too, but this
    // makes sure it's asked even before login (e.g. from a splash retry).
    await androidImpl?.requestNotificationsPermission();
  }

  // ── Step 2: FCM itself (call once the user is logged in) ───────────────
  Future<void> initMessaging() async {
    if (_messagingInitialized) return;
    _messagingInitialized = true;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS: let the OS show its native banner/lock-screen alert itself for
    // foreground pushes. Android has no such switch — we show our own
    // local notification for foreground pushes further down.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _subscribeToOwnTopic();
    await _saveToken();
    await _printTokenForTesting();
    _listenForFirestoreBadge();

    // Keep both the Firestore doc and the backend copy fresh if FCM
    // rotates the token.
    messaging.onTokenRefresh.listen((token) => _saveToken(token));

    // App open in foreground when the push arrives.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App was in the background and the user tapped the tray notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _navigateFor(message.data));

    // App was fully killed and got opened *by* tapping a notification.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      // Let the first frame settle before pushing a route.
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateFor(initialMessage.data));
    }
  }

  Future<void> _saveToken([String? token]) async {
    final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    await Future.wait([
      _saveTokenToFirestore(fcmToken),
      _saveTokenToBackend(fcmToken),
    ]);
  }

  Future<void> _saveTokenToFirestore([String? token]) async {
    final userId = AppSession.instance.userId;
    if (userId == null) return;
    try {
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await _firestore.collection('fcm_tokens').doc(userId.toString()).set({
        'userId': userId,
        'fcmToken': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'isActive': true,
      }, SetOptions(merge: true));
      if (kDebugMode) debugPrint('[Push] token saved to fcm_tokens/$userId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] failed to save token to Firestore: $e');
    }
  }

  /// Sends the token to the backend through the real
  /// PUT /users/profile/update/ endpoint (see [UserService.updateFcmToken])
  /// so it's stored in the Django DB against this user, alongside the
  /// Firestore copy. Best-effort — a failure here never blocks push setup.
  Future<void> _saveTokenToBackend(String fcmToken) async {
    if (AppSession.instance.userId == null) return;
    try {
      await ServiceLocator.userService.updateFcmToken(fcmToken);
      if (kDebugMode) debugPrint('[Push] token sent to backend via profile update');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] failed to send token via profile update: $e');
    }
  }

  /// TESTING ONLY — prints the raw FCM device token to the debug console
  /// so you can copy it into Firebase Console → Cloud Messaging →
  /// "Send test message" and confirm delivery to this exact device.
  /// Safe to remove once testing is done; it does nothing in release
  /// builds (kDebugMode-gated) and never sends the token anywhere.
  Future<void> _printTokenForTesting() async {
    if (!kDebugMode) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('=================== FCM TOKEN ===================');
      debugPrint(token);
      debugPrint('==================================================');
    } catch (e) {
      debugPrint('[Push] failed to fetch FCM token for testing: $e');
    }
  }

  /// Subscribes this device to `user_<userId>` on Firebase directly — no
  /// backend call, no database column. Whoever triggers a push for this
  /// user just needs to send to that same topic name.
  Future<void> _subscribeToOwnTopic() async {
    final userId = AppSession.instance.userId;
    if (userId == null) return;
    final topic = 'user_$userId';
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      _subscribedTopic = topic;
      if (kDebugMode) debugPrint('[Push] subscribed to topic: $topic');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] failed to subscribe to topic $topic: $e');
    }
  }

  /// Keeps the bell's green dot in sync with Firestore in real time: any
  /// unread doc under `user/<userId>/notifications` (however it got
  /// there — backend write, cloud function, anything) lights up the dot
  /// immediately, without waiting for a push or a screen refresh.
  void _listenForFirestoreBadge() {
    final userId = AppSession.instance.userId;
    if (userId == null) return;
    _badgeSub?.cancel();
    _badgeSub = _firestore
        .collection('user')
        .doc(userId.toString())
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
        if (snapshot.docs.isNotEmpty) NotificationBadge.instance.markUnread();
      },
      onError: (e) {
        if (kDebugMode) debugPrint('[Push] Firestore badge listener error: $e');
      },
    );
  }

  /// Call on logout — unsubscribes from this user's topic, flips this
  /// device's Firestore token doc to inactive, and resets so a different
  /// artist logging in on the same device subscribes/writes *their* own
  /// topic/token instead of silently no-op'ing because init already ran.
  Future<void> resetForLogout() async {
    await _badgeSub?.cancel();
    _badgeSub = null;

    final userId = AppSession.instance.userId;
    if (userId != null) {
      try {
        await _firestore
            .collection('fcm_tokens')
            .doc(userId.toString())
            .set({'isActive': false}, SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) debugPrint('[Push] failed to deactivate token doc: $e');
      }
    }

    final topic = _subscribedTopic;
    if (topic != null) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      } catch (e) {
        if (kDebugMode) debugPrint('[Push] failed to unsubscribe from $topic: $e');
      }
      _subscribedTopic = null;
    }
    _messagingInitialized = false;
  }

  // ── Foreground push → show it ourselves + flip the bell's green dot ───
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Log the raw payload the instant it arrives — before any
    // title/body parsing — so nothing the backend sends is ever hidden.
    // Useful for spotting fields the notification model doesn't
    // explicitly read yet (e.g. an OTP embedded in an unexpected key).
    if (kDebugMode) {
      debugPrint('[Push] foreground message: ${message.messageId} | data=${message.data} | notification.title=${message.notification?.title} | notification.body=${message.notification?.body}');
    }

    NotificationBadge.instance.markUnread();

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String? ?? 'AiRA';
    final body = notification?.body ?? message.data['message'] as String? ?? '';

    if (!Platform.isAndroid) {
      // iOS already shows its native alert (see setForegroundNotificationPresentationOptions).
      return;
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          // Ensures it shows in full on the lock screen, not hidden.
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleTapPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFor(data.map((k, v) => MapEntry(k, v?.toString())));
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] bad tap payload: $payload ($e)');
    }
  }

  /// Fires a local tray notification for a Help Center reply — used by
  /// [HelpCenterNotifier] as a stand-in for a real backend push (Help
  /// Center has no server-sent push of its own; see that file). Reuses
  /// the same channel/tap handling as any other push, so tapping this
  /// routes through [_navigateFor] into Help Center exactly like a real one.
  Future<void> showHelpCenterReply(String body) async {
    await initLocalNotifications();
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Support replied',
      body.isEmpty ? 'You have a new message from support.' : body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: jsonEncode({'type': 'help_center'}),
    );
  }

  /// Routes a tap to the right screen:
  ///  • a chat-type push with a `booking_id` → straight into that chat,
  ///    titled with the sender's real name when the payload includes one
  ///    (never a hardcoded/generic label if a real name is available)
  ///  • a booking-type push (new booking, confirmed, cancelled, reminder,
  ///    etc.) with a `booking_id` → straight into [BookingDetailScreen]
  ///    for that booking, same screen reached from the Bookings tab
  ///  • anything else with a `notification_id` → the notification detail
  ///    screen (which itself marks it read and can hand off to chat/booking)
  void _navigateFor(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (kDebugMode) debugPrint('[Push] tap payload: $data');

    final type = (data['type'] ?? data['notification_type'] ?? data['notificationType'] ?? '')
        .toString()
        .toLowerCase();
    final bookingId = int.tryParse(
        '${data['booking_id'] ?? data['bookingId'] ?? data['booking'] ?? ''}');
    final notificationId = int.tryParse(
        '${data['notification_id'] ?? data['notificationId'] ?? data['id'] ?? ''}');

    if (type.contains('help')) {
      nav.push(MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
      return;
    }

    // Some backends label a chat push "chat", "chat_message", "message",
    // "new_message" etc — match any of those rather than only the exact
    // string "chat", so a real chat push never silently falls through to
    // "do nothing" just because the label doesn't match one hardcoded word.
    final looksLikeChat =
        type.contains('chat') || type.contains('message');
    // Same idea for booking-type pushes — "booking", "booking_confirmed",
    // "new_booking", "booking_cancelled", "booking_reminder", etc.
    final looksLikeBooking = type.contains('book');

    if (looksLikeChat && bookingId != null) {
      // Whoever sent the message — could be the artist's customer, or
      // (if this build is ever used by a customer) the artist. Each
      // conversation's other participant is a different person/id, so
      // pull whatever name the backend included rather than a static
      // label like "Chat".
      final senderName = (data['sender_name'] ??
          data['senderName'] ??
          data['customer_name'] ??
          data['customerName'] ??
          data['artist_name'] ??
          data['artistName'])
          ?.toString();
      nav.push(MaterialPageRoute(
        builder: (_) => ChatScreen(
          bookingId: bookingId,
          title: (senderName != null && senderName.trim().isNotEmpty) ? senderName.trim() : 'Chat',
        ),
      ));
      return;
    }

    if (looksLikeBooking && bookingId != null) {
      // BookingDetailScreen is self-sufficient with just a bookingId — it
      // fetches the booking, package, statuses and customer name itself
      // (see its doc comment), so no BookingSlot needs to be built here.
      nav.push(MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: bookingId)));
      return;
    }

    if (notificationId != null) {
      nav.push(MaterialPageRoute(builder: (_) => NotificationDetailScreen(notificationId: notificationId)));
      return;
    }

    if (bookingId != null) {
      // Type wasn't recognizable as chat or booking, but there's still a
      // bookingId — the booking detail screen is the safer generic
      // fallback (it's read-only/informational either way), rather than
      // assuming this was a chat push.
      nav.push(MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: bookingId)));
    }
  }
}
