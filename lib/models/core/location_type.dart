class LocationType {
  final int locationTypeId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationType({
    required this.locationTypeId,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationType.fromJson(Map<String, dynamic> json) => LocationType(
    locationTypeId: json['locationTypeId'],
    name: json['name'],
    description: json['description'],
    isActive: json['isActive'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
