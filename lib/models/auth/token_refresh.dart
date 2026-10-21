// FILE: models/auth/token_refresh.dart  |  MODEL
// Request body: refresh access token.

/// Model: Token Refresh.
class TokenRefresh {
  final String refreshToken;

  TokenRefresh({required this.refreshToken});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}
