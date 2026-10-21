// FILE: utils/notification_badge.dart
// Unread-notification dot (ValueNotifier) shown on the bell icon.

import 'package:flutter/foundation.dart';
import 'service_locator.dart';

/// Notification Badge.
class NotificationBadge {
  NotificationBadge._();
  static final NotificationBadge instance = NotificationBadge._();
  final ValueNotifier<bool> hasUnread = ValueNotifier<bool>(false);
  final ValueNotifier<int> newNotificationTick = ValueNotifier<int>(0);
  /// Reloads the data.
  /// API: localNotificationBuilder.build
  Future<void> refresh() async {
    try {
      final list = await ServiceLocator.localNotificationBuilder.build();
      hasUnread.value = list.any((n) => !n.isRead);
    } catch (_) {
    }
  }

  /// Marks unread.
  void markUnread() {
    hasUnread.value = true;
    newNotificationTick.value++;
  }

  /// Clears stored data.
  void clear() => hasUnread.value = false;
}
