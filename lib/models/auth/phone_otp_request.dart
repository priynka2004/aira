import '../enums/role_enum.dart';

class PhoneOtpRequest {
  final String phoneNumber;
  final RoleEnum? role;

  PhoneOtpRequest({required this.phoneNumber, this.role});

  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    if (role != null) 'role': role!.toJson(),
  };
}
