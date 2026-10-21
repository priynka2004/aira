// FILE: api/help_center_notifier.dart
// Polls Help Center for new support replies and shows a local notification when one arrives.

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'help_center_service.dart';
import '../utils/app_session.dart';
import '../services/push_notification_service.dart';

/// Help Center Notifier.
class HelpCenterNotifier {
  HelpCenterNotifier._();
  static final HelpCenterNotifier instance = HelpCenterNotifier._();

  static const _checkInterval = Duration(seconds: 25);
  static const _lastNotifiedKey = 'help_center_last_notified_message_id';

  Timer? _timer;
  bool _checking = false;
  bool _suppressed = false;
  HelpCenterService? _service;

  /// Starts the process.
  void start(ApiService apiService) {
    _service ??= HelpCenterService(apiService);
    _timer ??= Timer.periodic(_checkInterval, (_) => _check());
  }

  /// Stops the process.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _service = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotifiedKey);
  }

  /// Sets suppressed.
  void setSuppressed(bool suppressed) {
    _suppressed = suppressed;
    if (suppressed) _markLatestAsNotified();
  }

  /// Marks latest as notified.
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
    }
  }

  /// Runs the check.
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
      if (myId != null && latest.senderId == myId) return;

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

  /// Gets last notified.
  Future<int?> _getLastNotified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastNotifiedKey);
  }

  /// Saves last notified.
  Future<void> _saveLastNotified(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastNotifiedKey, messageId);
  }
}
