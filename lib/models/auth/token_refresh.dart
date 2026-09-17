class TokenRefresh {
  final String refreshToken;

  TokenRefresh({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}
