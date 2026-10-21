// FILE: api/local_notification_builder.dart
// Builds the title/body of local notifications for bookings, chat and help-center events.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification/app_notification.dart';
import '../utils/app_session.dart';
import 'api_service.dart';
import 'booking_service.dart';
import 'chat_service.dart';
import 'help_center_service.dart';
import 'notification_service.dart';

/// Local Notification Builder.
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

  static const Map<int, _StatusCopy> _statusCopy = {
    1: _StatusCopy('new_booking_alert', 'New Booking Request',
        'You Have A New Booking Request.'),
    5: _StatusCopy('booking_cancelled', 'Booking Cancelled',
        'A Booking Was Cancelled.'),
    6: _StatusCopy('booking_no_show', 'Marked As No-Show',
        'A Booking Was Marked As A No-Show.'),
  };

  /// Builds the UI.
  Future<List<AppNotification>> build() async {
    final userId = AppSession.instance.userId ?? 0;
    final items = <AppNotification>[];

    try {
      final page = await _notificationService.getAllNotifications(limit: 50);
      items.addAll(page.data);
    } catch (_) {
    }
    // Paid bookings only (the server filters). Notifications of UNPAID bookings are dropped.
    final bookings = await _bookingService.getAllBookings(limit: 100);
    try {
      final unpaid = (await _bookingService.getAllBookings(limit: 100, paymentFilter: 'unpaid'))
          .map((b) => b.bookingId)
          .toSet();
      items.removeWhere((n) => n.bookingId != null && unpaid.contains(n.bookingId));
    } catch (_) {}
    final realBookingIds = items.map((n) => n.bookingId).whereType<int>().toSet();
    for (final b in bookings) {
        final copy = _statusCopy[b.statusId as int];
        if (copy == null) continue;
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
            title: 'New Message From Customer',
            message: m.content,
            isRead: false,
            deliveryStatus: 'local',
            createdAt: ts,
            updatedAt: ts,
          ));
        }
      } catch (_) {

      }
    }

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
            title: 'Support Replied To Your Message',
            message: m.content,
            isRead: false,
            deliveryStatus: 'local',
            createdAt: ts,
            updatedAt: ts,
          ));
        }
      }
    } catch (_) {
    }

    final relevant = _onlyArtistRelevant(items);
    final readIds = await _loadReadIds();
    final withReadState = relevant
        .map((n) => readIds.contains(n.notificationId) ? n.copyWith(isRead: true) : n)
        .toList();
    withReadState.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return withReadState;
  }

  /// Types that never help the artist do their work (promotions, tips, generic broadcasts).
  static const _noiseMarkers = ['promo', 'marketing', 'offer', 'discount', 'campaign', 'newsletter', 'welcome', 'tip', 'general'];

  /// Keeps only what the artist needs to act on, and shows each repeated message only once.
  List<AppNotification> _onlyArtistRelevant(List<AppNotification> all) {
    final newestFirst = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = <String>{};
    final out = <AppNotification>[];
    for (final n in newestFirst) {
      final t = n.type.toLowerCase();
      final isBooking = n.bookingId != null;
      if (!isBooking && _noiseMarkers.any(t.contains)) continue;
      if (n.title.trim().isEmpty && n.message.trim().isEmpty) continue;
      // Same title + message repeated (e.g. "Payout account updated" saved twice) → keep only the latest.
      final key = isBooking ? '${n.bookingId}|$t|${n.title}' : '$t|${n.title.trim().toLowerCase()}|${n.message.trim().toLowerCase()}';
      if (!seen.add(key)) continue;
      out.add(n);
    }
    return out;
  }

  /// Marks read.
  Future<void> markRead(int notificationId) async {
    final ids = await _loadReadIds();
    ids.add(notificationId);
    await _saveReadIds(ids);
  }

  /// Marks all read.
  Future<void> markAllRead(List<AppNotification> current) async {
    final ids = await _loadReadIds();
    ids.addAll(current.map((n) => n.notificationId));
    await _saveReadIds(ids);
  }

  /// Loads read IDs.
  Future<Set<int>> _loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_readIdsKey) ?? [];
    return raw.map((e) => int.tryParse(e) ?? 0).toSet();
  }

  /// Saves read IDs.
  Future<void> _saveReadIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, ids.map((e) => e.toString()).toList());
  }

  /// Stable id.
  int _stableId(String source, int entityId, String type) {
    final key = '$source:$entityId:$type';
    final hash = key.hashCode & 0x7fffffff;
    return -(hash == 0 ? 1 : hash);
  }
}

/// Status Copy.
class _StatusCopy {
  final String type;
  final String title;
  final String message;
  const _StatusCopy(this.type, this.title, this.message);
}
