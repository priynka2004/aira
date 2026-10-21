// FILE: models/auth/auth_response.dart  |  MODEL
// Login / register response (tokens + user info).

/// Model: Auth Response.
class AuthResponse {
  final int userId;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.userId,
    required this.name,
    this.email,
    this.phoneNumber,
    this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  /// Builds this object from API JSON.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> j = json;
    for (final key in ['data', 'result']) {
      final v = j[key];
      if (v is Map<String, dynamic>) {
        j = v;
        break;
      }
    }

    Map<String, dynamic> tokenSrc = j;
    final nestedTokens = j['tokens'] ?? j['token'];
    if (nestedTokens is Map<String, dynamic>) {
      tokenSrc = nestedTokens;
    }

    Map<String, dynamic> userSrc = j;
    final nestedUser = j['user'];
    if (nestedUser is Map<String, dynamic>) {
      userSrc = nestedUser;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is double) return v.toInt();
      return 0;
    }

    String _toStr(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      return v.toString();
    }

    String _findToken(Map<String, dynamic> src, List<String> keys) {
      for (final k in keys) {
        final v = src[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return '';
    }

    return AuthResponse(
      userId: _toInt(userSrc['user_id'] ?? userSrc['id'] ?? j['user_id'] ?? j['id']),
      name: _toStr(userSrc['name'] ?? j['name']),
      email: (userSrc['email'] ?? j['email'])?.toString(),
      phoneNumber: (userSrc['phone_number'] ?? userSrc['phone'] ?? j['phone_number'] ?? j['phone'])?.toString(),
      role: (userSrc['role'] ?? j['role'])?.toString(),
      accessToken: _findToken(tokenSrc, ['access_token', 'access', 'token', 'accessToken']),
      refreshToken: _findToken(tokenSrc, ['refresh_token', 'refresh', 'refreshToken']),
    );
  }

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'role': role,
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };
}
