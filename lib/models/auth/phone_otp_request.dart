// FILE: models/auth/phone_otp_request.dart  |  MODEL
// Request body: send OTP to phone.

import '../enums/role_enum.dart';

/// Model: Phone Otp Request.
class PhoneOtpRequest {
  final String phoneNumber;
  final RoleEnum? role;

  PhoneOtpRequest({required this.phoneNumber, this.role});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    if (role != null) 'role': role!.toJson(),
  };
}
