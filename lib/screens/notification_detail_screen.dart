import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/notification/app_notification.dart';
import '../utils/app_session.dart';
import '../utils/service_locator.dart';
import 'chat_screen.dart';
import 'booking_detail_screen.dart';

/// Full detail view for a single notification. Reached either by tapping
/// an item on [NotificationsScreen], or straight from a push notification
/// tap (foreground, background, or cold start).
///
/// Pass [notification] when you already have it (list tap — avoids a
/// refetch); otherwise pass [notificationId] and it's fetched via
/// `GET /notifications/get/`.
class NotificationDetailScreen extends StatefulWidget {
  final int notificationId;
  final AppNotification? notification;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.notification,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  bool _loading = true;
  String? _error;
  AppNotification? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.notification != null) {
      _item = widget.notification;
      _loading = false;
      _markReadIfNeeded();
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final n = await ServiceLocator.notificationService.getNotification(widget.notificationId);
      if (!mounted) return;
      setState(() {
        _item = n;
        _loading = false;
      });
      _markReadIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markReadIfNeeded() async {
    final n = _item;
    if (n == null || n.isRead) return;
    try {
      if (n.firestoreDocId != null) {
        final userId = AppSession.instance.userId;
        if (userId != null) {
          await ServiceLocator.firestoreNotificationService.markAsRead(userId, n.firestoreDocId!);
        }
      } else {
        await ServiceLocator.notificationService.markRead(n.notificationId);
      }
      if (mounted) setState(() => _item = n.copyWith(isRead: true));
    } catch (_) {
      // Best-effort — not worth surfacing an error for this.
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$min $suffix';
  }

  bool get _isChat => (_item?.type.toLowerCase().contains('chat') ?? false) && _item?.bookingId != null;

  /// Any non-chat notification that references a booking (confirmed,
  /// cancelled, reminder, etc.) — shows a "View booking" button that
  /// deep-links straight into [BookingDetailScreen] for that booking,
  /// same screen you'd reach by tapping it in the Bookings tab.
  bool get _isBooking => !_isChat && _item?.bookingId != null;

  @override
  Widget build(BuildContext context) {
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
                    child: Text('Notification', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : _error != null
                      ? AiraErrorState(message: _error!, onRetry: _load)
                      : _item == null
                          ? const SizedBox.shrink()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: AiraCard(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AiraColors.blush,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _item!.type.toUpperCase(),
                                        style: AiraText.sans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AiraColors.roseDeep,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(_item!.title, style: AiraText.serif(fontSize: 20, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 10),
                                    Text(_item!.message,
                                        style: AiraText.sans(fontSize: 14, color: AiraColors.charcoalSoft, height: 1.5)),
                                    const SizedBox(height: 16),
                                    Text(_formatDate(_item!.createdAt),
                                        style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                                    if (_isChat) ...[
                                      const SizedBox(height: 20),
                                      PrimaryButton(
                                        label: 'Open chat',
                                        icon: Icons.chat_bubble_outline,
                                        expand: true,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              bookingId: _item!.bookingId!,
                                              title: _item!.title.trim().isNotEmpty ? _item!.title.trim() : 'Chat',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_isBooking) ...[
                                      const SizedBox(height: 20),
                                      PrimaryButton(
                                        label: 'View booking',
                                        icon: Icons.calendar_today_outlined,
                                        expand: true,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => BookingDetailScreen(bookingId: _item!.bookingId!),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
