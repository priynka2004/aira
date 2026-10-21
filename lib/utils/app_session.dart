// FILE: utils/app_session.dart
// Login session: tokens, user id, name, role (stored in SharedPreferences).

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Session.
class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  static const _kAccessToken  = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId       = 'user_id';
  static const _kName         = 'user_name';
  static const _kRole         = 'user_role';

  String? accessToken;
  String? refreshToken;
  int?    userId;
  String? name;
  String? role;

  /// Loads this screen's data.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    accessToken  = p.getString(_kAccessToken);
    refreshToken = p.getString(_kRefreshToken);
    userId       = p.getInt(_kUserId);
    name         = p.getString(_kName);
    role         = p.getString(_kRole);
    if (kDebugMode) {
      debugPrint('[AppSession] loaded -> token='
          '${accessToken == null ? "null" : (accessToken!.isEmpty ? "empty" : "present")}');
    }
  }

  /// Saves the entered data.
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String name,
    required String role,
  }) async {
    this.accessToken  = accessToken;
    this.refreshToken = refreshToken;
    this.userId       = userId;
    this.name         = name;
    this.role         = role;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccessToken,  accessToken);
    await p.setString(_kRefreshToken, refreshToken);
    await p.setInt   (_kUserId,       userId);
    await p.setString(_kName,         name);
    await p.setString(_kRole,         role);
    if (kDebugMode) {
      debugPrint('[AppSession] saved -> token='
          '${accessToken.isEmpty ? "EMPTY (!)" : "present (${accessToken.length} chars)"}');
    }
  }

  /// Clears stored data.
  Future<void> clear() async {
    accessToken = refreshToken = name = role = null;
    userId = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccessToken);
    await p.remove(_kRefreshToken);
    await p.remove(_kUserId);
    await p.remove(_kName);
    await p.remove(_kRole);
  }

  /// Returns true if logged in.
  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;
}
