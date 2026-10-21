// FILE: models/auth/reset_password_request.dart  |  MODEL
// Request body: reset password. API: POST /auth/reset-password/  { username, otp, new_password }

/// Model: Reset Password Request.
class ResetPasswordRequest {
  /// Email or phone number.
  final String identifier;
  final String otp;
  final String newPassword;

  ResetPasswordRequest({
    required this.identifier,
    required this.otp,
    required this.newPassword,
  });

  /// Returns true if email.
  bool get isEmail => identifier.contains('@');

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        'username': identifier.trim(),
        'otp': otp,
        'new_password': newPassword,
      };
}
