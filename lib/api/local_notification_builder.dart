import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification/app_notification.dart';
import '../utils/app_session.dart';
import 'api_service.dart';
import 'booking_service.dart';
import 'chat_service.dart';
import 'help_center_service.dart';
import 'notification_service.dart';

/// Builds the Notifications screen's list mostly from data the app
/// already fetches successfully elsewhere (bookings, chat messages, help
/// center replies), **plus** the real backend notification rows —
/// specifically so events with no other data source on the client (like
/// the Booking OTP, which is never returned by any booking GET) still
/// show up.
///
/// `GET /notifications/get_all/` currently always comes back with every
/// item stuck at `deliveryStatus: "failed"` / `"pending"` and
/// `failureReason: "FCM not yet configured"` — the backend creates the
/// notification row (with its real title/message already in it) but
/// never finishes *pushing* it. That failed-push status doesn't mean the
/// row's content is invalid, so this builder still reads it — it just
/// doesn't rely on it alone, since backend coverage of notification
/// types has been inconsistent (see the booking-lifecycle testing
/// history). The synthetic on-device items below fill in the gaps for
/// event types the backend doesn't reliably create rows for at all.
class LocalNotificationBuilder {
  static const _readIdsKey = 'local_notif_read_ids';

  final ApiService _apiService;
  final BookingService _bookingService;
  final ChatService _chatService;
  final HelpCenterService _helpCenterService;
  late final NotificationService _notificationService;

  LocalNotificationBuilder(
    this._apiService,
    this._bookingService,
    this._chatService,
    this._helpCenterService,
  ) {
    _notificationService = NotificationService(_apiService);
  }

  // Artist-side copy: statuses the artist didn't just set themselves
  // (they confirm/complete bookings themselves in-app, so those don't
  // need a notification) — mainly new requests and customer-initiated
  // cancellations.
  static const Map<int, _StatusCopy> _statusCopy = {
    1: _StatusCopy('new_booking_alert', 'New booking request',
        'You have a new booking request.'),
    5: _StatusCopy('booking_cancelled', 'Booking cancelled',
        'A booking was cancelled.'),
    6: _StatusCopy('booking_no_show', 'Marked as no-show',
        'A booking was marked as a no-show.'),
  };

  Future<List<AppNotification>> build() async {
    final userId = AppSession.instance.userId ?? 0;
    final items = <AppNotification>[];

    // 0) Real backend notification rows — best-effort. This is the ONLY
    // source for event types the client has no other way to reconstruct
    // (the Booking OTP above all: it's never returned by any booking GET,
    // only ever written into a notification's message). A failure here
    // (or an empty list, if the backend genuinely hasn't created any rows
    // yet) must not block the synthetic items below — this is additive.
    try {
      final page = await _notificationService.getAllNotifications(limit: 50);
      items.addAll(page.data);
    } catch (_) {
      // Backend notification list unavailable — fall through to the
      // synthetic-only feed below rather than failing the whole screen.
    }
    final realBookingIds = items.map((n) => n.bookingId).whereType<int>().toSet();

    // 1) Booking status changes — from the already-working bookings list.
    // Deliberately NOT wrapped in try/catch: if this genuinely fails
    // (network hiccup), the whole build() call should fail and the
    // caller (which does "best effort, leave existing list as-is" on
    // error) keeps showing the last good data — instead of us silently
    // swallowing the error here and returning a much smaller/empty list
    // that overwrites perfectly good data already on screen.
    final bookings = await _bookingService.getAllBookings(limit: 100);
    for (final b in bookings) {
        final copy = _statusCopy[b.statusId as int];
        if (copy == null) continue;
        // Skip the synthetic entry if a real backend notification already
        // exists for this booking — avoids showing e.g. "New booking
        // request" twice (once real, once synthesized) once the backend
        // reliably creates rows for a given event type.
        if (realBookingIds.contains(b.bookingId)) continue;
        items.add(AppNotification(
          notificationId: _stableId('booking', b.bookingId as int, copy.type),
          userId: userId,
          bookingId: b.bookingId as int,
          type: copy.type,
          title: copy.title,
          message: copy.message,
          isRead: false,
          deliveryStatus: 'local',
          createdAt: DateTime.tryParse(
                  (b.updatedAt ?? b.createdAt ?? '').toString()) ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(
                  (b.updatedAt ?? b.createdAt ?? '').toString()) ??
              DateTime.now(),
        ));
      }

    // 2) New chat messages — only for bookings where a conversation can
    // realistically exist (confirmed / in-progress / completed).
    for (final b in bookings) {
      if (![2, 3, 4].contains(b.statusId as int)) continue;
      try {
        final page = await _chatService.getMessages(
          b.bookingId as int,
          limit: 5,
          sortOrder: 'desc',
        );
        for (final m in page.data) {
          if (m.senderId == userId || m.senderId == 0) continue;
          final ts = DateTime.tryParse(m.createdAt) ?? DateTime.now();
          items.add(AppNotification(
            notificationId: _stableId('chat', m.messageId, 'chat_message'),
            userId: userId,
            bookingId: b.bookingId as int,
            type: 'chat_message',
            title: 'New message from customer',
            message: m.content,
            isRead: false,
            deliveryStatus: 'local',
            createdAt: ts,
            updatedAt: ts,
          ));
        }
      } catch (_) {
        // No conversation yet for this booking, or a network hiccup —
        // skip it, don't fail the whole list over one booking.
      }
    }

    // 3) Help Center replies.
    try {
      final convo = await _helpCenterService.getConversation();
      if (convo != null) {
        final page = await _helpCenterService.getMessages(
          convo.conversationId,
          limit: 10,
          sortOrder: 'desc',
        );
        for (final m in page.data) {
          if (m.senderId == userId || m.senderId == 0) continue;
          final ts = DateTime.tryParse(m.createdAt) ?? DateTime.now();
          items.add(AppNotification(
            notificationId: _stableId('help', m.messageId, 'help_center_reply'),
            userId: userId,
            bookingId: null,
            type: 'help_center_reply',
            title: 'Support replied to your message',
            message: m.content,
            isRead: false,
            deliveryStatus: 'local',
            createdAt: ts,
            updatedAt: ts,
          ));
        }
      }
    } catch (_) {
      // No open conversation — nothing to add.
    }

    final readIds = await _loadReadIds();
    final withReadState = items
        .map((n) => readIds.contains(n.notificationId) ? n.copyWith(isRead: true) : n)
        .toList();
    withReadState.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return withReadState;
  }

  Future<void> markRead(int notificationId) async {
    final ids = await _loadReadIds();
    ids.add(notificationId);
    await _saveReadIds(ids);
  }

  Future<void> markAllRead(List<AppNotification> current) async {
    final ids = await _loadReadIds();
    ids.addAll(current.map((n) => n.notificationId));
    await _saveReadIds(ids);
  }

  Future<Set<int>> _loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_readIdsKey) ?? [];
    return raw.map((e) => int.tryParse(e) ?? 0).toSet();
  }

  Future<void> _saveReadIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, ids.map((e) => e.toString()).toList());
  }

  /// Deterministic negative id so the same underlying event always maps
  /// to the same synthetic notificationId across rebuilds (needed for
  /// mark-as-read to stick, and to avoid clashing with any real
  /// server-side notificationId which is always positive).
  int _stableId(String source, int entityId, String type) {
    final key = '$source:$entityId:$type';
    final hash = key.hashCode & 0x7fffffff;
    return -(hash == 0 ? 1 : hash);
  }
}

class _StatusCopy {
  final String type;
  final String title;
  final String message;
  const _StatusCopy(this.type, this.title, this.message);
}
