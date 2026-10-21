// FILE: models/auth/email_otp_request.dart  |  MODEL
// Request body: send OTP to email.

import '../enums/role_enum.dart';

/// Model: Email Otp Request.
class EmailOtpRequest {
  final String email;
  final RoleEnum? role;

  EmailOtpRequest({required this.email, this.role});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'email': email,
    if (role != null) 'role': role!.toJson(),
  };
}
