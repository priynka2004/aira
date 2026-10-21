// FILE: models/auth/phone_otp_verify.dart  |  MODEL
// Request body: verify phone OTP.

/// Model: Phone Otp Verify.
class PhoneOtpVerify {
  final String phoneNumber;
  final String otp;

  PhoneOtpVerify({required this.phoneNumber, required this.otp});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    'otp': otp,
  };
}
