// FILE: models/enums/role_enum.dart  |  MODEL
// Enum: user role.

/// Enum: Role Enum values.
enum RoleEnum {
  customer,
  artist,
  admin;

  String toJson() => name;
  static RoleEnum fromJson(String json) => values.byName(json);
}
