import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/notification/app_notification.dart';
import '../utils/app_feedback.dart';
import '../utils/app_session.dart';
import '../utils/service_locator.dart';
import '../utils/notification_badge.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  // Two sources, merged for display — see [_merged]:
  //  • _restItems: GET /notifications/get_all/ (existing backend flow)
  //  • _liveItems: live Firestore user/<userId>/notifications stream
  //    (updates instantly, no refresh needed — mirrors the reference
  //    implementation the client shared).
  List<AppNotification> _restItems = [];
  List<AppNotification> _liveItems = [];
  StreamSubscription<List<AppNotification>>? _liveSub;

  @override
  void initState() {
    super.initState();
    _load();
    _listenLive();
    // A push notification can arrive while this screen is already open —
    // refresh the REST list live instead of making the user pull-to-refresh.
    // (Firestore items already update on their own via _listenLive.)
    NotificationBadge.instance.newNotificationTick.addListener(_onPushArrived);
  }

  @override
  void dispose() {
    NotificationBadge.instance.newNotificationTick.removeListener(_onPushArrived);
    _liveSub?.cancel();
    super.dispose();
  }

  void _listenLive() {
    final userId = AppSession.instance.userId;
    if (userId == null) return;
    _liveSub = ServiceLocator.firestoreNotificationService.notificationsStream(userId).listen(
          (items) {
        if (!mounted) return;
        setState(() => _liveItems = items);
        NotificationBadge.instance.clear();
      },
      onError: (e) {
        // Best-effort — the REST list still works on its own.
      },
    );
  }

  /// Every notification type is shown here now — this used to be an
  /// allow-list of only booking-status types (new_booking_alert /
  /// booking_cancelled / booking_no_show), which was silently hiding
  /// booking_otp_issued and chat_message too. Per backend: chat and OTP
  /// notifications should surface through this same feed exactly like
  /// booking/help-center ones do — there's no separate API for them, so
  /// there's no reason for this screen to filter them out client-side.
  bool _isBookingNotification(AppNotification n) => true;

  /// Combines REST + Firestore items into one list, newest first. When
  /// both sides carry the same non-zero `notificationId`, the Firestore
  /// copy wins (it's the live one) so a mark-as-read there is reflected
  /// immediately without waiting on the next REST refresh.
  List<AppNotification> get _merged {
    final byKey = <String, AppNotification>{};
    for (final n in _restItems) {
      if (!_isBookingNotification(n)) continue;
      byKey[n.notificationId > 0 ? 'id:${n.notificationId}' : 'rest:${n.hashCode}'] = n;
    }
    for (final n in _liveItems) {
      if (!_isBookingNotification(n)) continue;
      byKey[n.notificationId > 0 ? 'id:${n.notificationId}' : 'doc:${n.firestoreDocId}'] = n;
    }
    final list = byKey.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _onPushArrived() {
    if (!mounted) return;
    _refreshQuiet();
  }

  /// Same as [_load] but skips the full-screen spinner so a background
  /// refresh (triggered by a live push) doesn't flash the loading state
  /// over a list the user is already looking at.
  Future<void> _refreshQuiet() async {
    try {
      final list = await ServiceLocator.localNotificationBuilder.build();
      if (!mounted) return;
      setState(() => _restItems = list);
      NotificationBadge.instance.clear();
    } catch (_) {
      // Best-effort — leave the current list as-is on a network hiccup.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ServiceLocator.localNotificationBuilder.build();
      if (!mounted) return;
      setState(() {
        _restItems = list;
        _loading = false;
      });
      // The user has now "seen" their notifications — clear the bell's
      // green dot regardless of whether every item is individually read.
      NotificationBadge.instance.clear();
    } catch (e) {
      if (!mounted) return;
      // The REST call failing shouldn't blank the screen if Firestore
      // already has live items to show.
      setState(() {
        _loading = false;
        if (_liveItems.isEmpty) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    if (n.firestoreDocId != null) {
      final userId = AppSession.instance.userId;
      setState(() {
        _liveItems = _liveItems
            .map((x) => x.firestoreDocId == n.firestoreDocId ? x.copyWith(isRead: true) : x)
            .toList();
      });
      if (userId != null) {
        try {
          await ServiceLocator.firestoreNotificationService.markAsRead(userId, n.firestoreDocId!);
        } catch (_) {
          // best-effort — local state already flipped
        }
      }
      return;
    }
    setState(() {
      _restItems =
          _restItems.map((x) => x.notificationId == n.notificationId ? x.copyWith(isRead: true) : x).toList();
    });
    try {
      await ServiceLocator.localNotificationBuilder.markRead(n.notificationId);
    } catch (_) {
      // best-effort — local state already flipped
    }
  }

  /// Tapping a notification opens its full detail screen (which also
  /// marks it read). We optimistically flip the local read state too so
  /// the list looks right immediately.
  Future<void> _openDetail(AppNotification n) async {
    _markRead(n);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationDetailScreen(notificationId: n.notificationId, notification: n)),
    );
  }

  Future<void> _markAllRead() async {
    setState(() {
      _restItems = _restItems.map((x) => x.copyWith(isRead: true)).toList();
      _liveItems = _liveItems.map((x) => x.copyWith(isRead: true)).toList();
    });
    final userId = AppSession.instance.userId;
    try {
      await Future.wait([
        ServiceLocator.localNotificationBuilder.markAllRead(_restItems),
        if (userId != null) ServiceLocator.firestoreNotificationService.markAllAsRead(userId),
      ]);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final items = _merged;
    final unread = items.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Notifications', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                  if (unread > 0)
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Text('Mark all read',
                          style: AiraText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : (_error != null && items.isEmpty)
                  ? AiraErrorState(message: _error!, onRetry: _load)
                  : items.isEmpty
                  ? Center(
                child: Text("You're all caught up ✨",
                    style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft)),
              )
                  : RefreshIndicator(
                onRefresh: _load,
                color: AiraColors.rose,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return AiraCard(
                      padding: const EdgeInsets.all(14),
                      borderColor: n.isRead ? AiraColors.hair : AiraColors.goldSoft,
                      onTap: () => _openDetail(n),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: n.isRead ? Colors.transparent : AiraColors.rose,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title,
                                    style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(n.message,
                                    style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
                                const SizedBox(height: 6),
                                Text(_timeAgo(n.createdAt),
                                    style: AiraText.sans(fontSize: 11, color: AiraColors.charcoalSoft)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
