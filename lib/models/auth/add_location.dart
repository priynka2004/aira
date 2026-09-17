class AddLocation {
  final int locationTypeId;

  AddLocation({required this.locationTypeId});

  Map<String, dynamic> toJson() => {'location_type_id': locationTypeId};
}
