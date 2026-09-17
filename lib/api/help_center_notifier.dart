import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'help_center_service.dart';
import '../utils/app_session.dart';
import '../services/push_notification_service.dart';

/// Help Center has no WebSocket, and [HelpCenterScreen]'s own polling only
/// runs while that screen is on-screen (see its docs) — so an artist who
/// isn't sitting there has no way to know support replied unless the
/// backend sends a push for it. Until that exists server-side, this runs a
/// light periodic check while the app is open and fires a local tray
/// notification the first time it sees a reply it hasn't shown yet.
///
/// This only covers the app-in-foreground case — it's a Dart `Timer`, not
/// a real push, so it can't wake the app from killed/backgrounded state.
/// The full fix still needs the backend to send an actual FCM push (e.g.
/// type `help_center`) when an admin replies; [PushNotificationService]
/// already knows how to receive and route that the moment it exists.
class HelpCenterNotifier {
  HelpCenterNotifier._();
  static final HelpCenterNotifier instance = HelpCenterNotifier._();

  static const _checkInterval = Duration(seconds: 25);
  static const _lastNotifiedKey = 'help_center_last_notified_message_id';

  Timer? _timer;
  bool _checking = false;
  bool _suppressed = false; // true while HelpCenterScreen itself is open
  HelpCenterService? _service;

  void start(ApiService apiService) {
    _service ??= HelpCenterService(apiService);
    _timer ??= Timer.periodic(_checkInterval, (_) => _check());
  }

  /// Call on logout so a different user logging in on the same device
  /// doesn't inherit the previous user's "last notified" state.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _service = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotifiedKey);
  }

  /// Call `true` from [HelpCenterScreen.initState] and `false` from its
  /// dispose — no point popping a tray notification for a reply the user
  /// is already looking at, and it marks whatever's currently newest as
  /// "seen" so leaving the screen doesn't immediately re-notify for it.
  void setSuppressed(bool suppressed) {
    _suppressed = suppressed;
    if (suppressed) _markLatestAsNotified();
  }

  Future<void> _markLatestAsNotified() async {
    final service = _service;
    if (service == null) return;
    try {
      final conversation = await service.getConversation();
      if (conversation == null) return;
      final history = await service.getMessages(
        conversation.conversationId,
        pageNum: 1,
        limit: 1,
        sortOrder: 'desc',
      );
      if (history.data.isNotEmpty) {
        await _saveLastNotified(history.data.first.messageId);
      }
    } catch (_) {
      // Best-effort — worst case the next _check() notifies once more.
    }
  }

  Future<void> _check() async {
    if (_checking || _suppressed) return;
    final service = _service;
    if (service == null) return;

    _checking = true;
    try {
      final conversation = await service.getConversation();
      if (conversation == null) return;

      final history = await service.getMessages(
        conversation.conversationId,
        pageNum: 1,
        limit: 1,
        sortOrder: 'desc',
      );
      if (history.data.isEmpty) return;

      final latest = history.data.first;
      final myId = AppSession.instance.userId;
      if (myId != null && latest.senderId == myId) return; // my own message

      final lastNotified = await _getLastNotified();
      if (lastNotified != null && latest.messageId <= lastNotified) return;

      await _saveLastNotified(latest.messageId);
      await PushNotificationService.instance.showHelpCenterReply(latest.content);
    } catch (e) {
      if (kDebugMode) print('[HelpCenterNotifier] check failed: $e');
    } finally {
      _checking = false;
    }
  }

  Future<int?> _getLastNotified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastNotifiedKey);
  }

  Future<void> _saveLastNotified(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastNotifiedKey, messageId);
  }
}
