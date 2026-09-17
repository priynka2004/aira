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

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap common envelope shapes: { data: {...} }, { result: {...} }
    Map<String, dynamic> j = json;
    for (final key in ['data', 'result']) {
      final v = j[key];
      if (v is Map<String, dynamic>) {
        j = v;
        break;
      }
    }

    // Tokens may be flat (access_token/refresh_token) or nested
    // under a `tokens` / `token` object (common DRF SimpleJWT pattern):
    // { "tokens": { "access": "...", "refresh": "..." } }
    Map<String, dynamic> tokenSrc = j;
    final nestedTokens = j['tokens'] ?? j['token'];
    if (nestedTokens is Map<String, dynamic>) {
      tokenSrc = nestedTokens;
    }

    // User info may itself be nested under `user`
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
