// FILE: models/auth/google_auth.dart  |  MODEL
// Request body: Google sign-in.

import '../enums/role_enum.dart';

/// Model: Google Auth.
class GoogleAuth {
  final String idToken;
  final RoleEnum? role;

  GoogleAuth({required this.idToken, this.role});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'id_token': idToken,
    if (role != null) 'role': role!.toJson(),
  };
}
