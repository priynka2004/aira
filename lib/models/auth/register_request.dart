// FILE: models/auth/register_request.dart  |  MODEL
// Request body: register a new artist.

import '../enums/role_enum.dart';

/// Model: Register Request.
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

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) 'phone_number': phoneNumber!.trim(),
    'password': password,
    'role': role.toJson(),
  };
}
