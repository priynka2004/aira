import 'inclusion.dart';

class Package {
  final int packageId;
  final int artistId;
  final int subCategoryId;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final bool isActive;
  final List<Inclusion> inclusions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Package({
    required this.packageId,
    required this.artistId,
    required this.subCategoryId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    required this.isActive,
    required this.inclusions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Package.fromJson(Map<String, dynamic> json) => Package(
    packageId: json['packageId'],
    artistId: json['artistId'],
    subCategoryId: json['subCategoryId'],
    name: json['name'],
    price: double.parse(json['price']),
    durationMinutes: json['durationMinutes'],
    description: json['description'],
    isActive: json['isActive'],
    inclusions: (json['inclusions'] as List)
        .map((e) => Inclusion.fromJson(e))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
