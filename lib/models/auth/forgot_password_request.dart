// FILE: models/auth/forgot_password_request.dart  |  MODEL
// Request body: forgot password. API: POST /auth/forgot-password/  { username }

/// Model: Forgot Password Request.
class ForgotPasswordRequest {
  /// Email or phone number.
  final String identifier;

  ForgotPasswordRequest({required this.identifier});

  /// Returns true if email.
  bool get isEmail => identifier.contains('@');

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {'username': identifier.trim()};
}
