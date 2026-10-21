// FILE: utils/onboarding_draft.dart
// Saves / loads half-filled onboarding forms on device.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_session.dart';

/// Onboarding Draft.
class OnboardingDraft {
  static String _key(String step) =>
      'onboarding_draft_${step}_${AppSession.instance.userId ?? 0}';

  /// Saves the entered data.
  static Future<void> save(String step, Map<String, dynamic> data) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key(step), jsonEncode(data));
    } catch (_) {}
  }

  /// Loads this screen's data.
  static Future<Map<String, dynamic>> load(String step) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key(step));
      if (raw == null || raw.isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Clears stored data.
  static Future<void> clear(String step) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_key(step));
    } catch (_) {}
  }
}
