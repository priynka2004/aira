enum RoleEnum {
  customer,
  artist,
  admin;

  String toJson() => name;
  static RoleEnum fromJson(String json) => values.byName(json);
}
