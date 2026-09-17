import 'package:flutter/foundation.dart';
import 'service_locator.dart';

/// Tiny global singleton that tracks whether the user has any unread
/// notification, so the bell icon's green dot can update from *anywhere*
/// in the app — a push arriving in the foreground, the notifications list
/// being opened, a single notification being marked read, etc — without
/// having to thread state through every screen.
class NotificationBadge {
  NotificationBadge._();
  static final NotificationBadge instance = NotificationBadge._();

  /// True as soon as there's at least one unread notification. The bell
  /// icon listens to this and shows/hides the green dot.
  final ValueNotifier<bool> hasUnread = ValueNotifier<bool>(false);

  /// Bumped by one every time a push notification arrives while the app
  /// is open. [NotificationsScreen] listens to this so a notification
  /// that arrives while the list is already open shows up there live,
  /// instead of only updating the bell and waiting for a manual
  /// pull-to-refresh.
  final ValueNotifier<int> newNotificationTick = ValueNotifier<int>(0);

  /// Re-checks the server for any unread notification. Safe to call
  /// repeatedly (app resume, after login, pull-to-refresh, etc).
  Future<void> refresh() async {
    try {
      final list = await ServiceLocator.localNotificationBuilder.build();
      hasUnread.value = list.any((n) => !n.isRead);
    } catch (_) {
      // Best-effort — leave the badge as-is on a network hiccup.
    }
  }

  /// Called the moment a push notification arrives while the app is open.
  void markUnread() {
    hasUnread.value = true;
    newNotificationTick.value++;
  }

  /// Called as soon as the user opens/looks at their notifications —
  /// the dot disappears the instant they've "seen" it, regardless of
  /// whether every individual item has been tapped/read yet.
  void clear() => hasUnread.value = false;
}
