import '../enums/role_enum.dart';

class RegisterRequest {
  final String name;
  final String? email;
  final String? phoneNumber;
  final String password;
  final RoleEnum role;

  RegisterRequest({
    required this.name,
    this.email,
    this.phoneNumber,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'password': password,
    'role': role.toJson(),
  };
}
