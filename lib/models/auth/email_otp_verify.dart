// FILE: models/auth/email_otp_verify.dart  |  MODEL
// Request body: verify email OTP.

/// Model: Email Otp Verify.
class EmailOtpVerify {
  final String email;
  final String otp;

  EmailOtpVerify({required this.email, required this.otp});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
  };
}
