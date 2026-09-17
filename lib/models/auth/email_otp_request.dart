import '../enums/role_enum.dart';

class EmailOtpRequest {
  final String email;
  final RoleEnum? role;

  EmailOtpRequest({required this.email, this.role});

  Map<String, dynamic> toJson() => {
    'email': email,
    if (role != null) 'role': role!.toJson(),
  };
}
