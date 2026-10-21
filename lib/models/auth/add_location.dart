// FILE: models/auth/add_location.dart  |  MODEL
// Request body to add a service location type.

/// Model: Add Location.
class AddLocation {
  final int locationTypeId;

  AddLocation({required this.locationTypeId});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {'location_type_id': locationTypeId};
}
