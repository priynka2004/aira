import '../enums/role_enum.dart';

class GoogleAuth {
  final String idToken;
  final RoleEnum? role;

  GoogleAuth({required this.idToken, this.role});

  Map<String, dynamic> toJson() => {
    'id_token': idToken,
    if (role != null) 'role': role!.toJson(),
  };
}
