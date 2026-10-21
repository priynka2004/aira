// FILE: models/artist/package.dart  |  MODEL
// Service package (name, price, duration, inclusions, makeup type, brands, photo).

import 'inclusion.dart';

/// Model: Package.
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

  // New in the security & features release
  final String? makeupType;
  final List<String> brands;
  final String? productDetails;
  final String? photoUrl; // absolute URL or null
  final String? category; // derived by the server from the sub-category

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
    this.makeupType,
    this.brands = const [],
    this.productDetails,
    this.photoUrl,
    this.category,
  });

  /// Builds this object from API JSON.
  factory Package.fromJson(Map<String, dynamic> json) => Package(
        packageId: json['packageId'],
        artistId: json['artistId'],
        subCategoryId: json['subCategoryId'],
        name: json['name'],
        price: double.tryParse('${json['price']}') ?? 0,
        durationMinutes: json['durationMinutes'],
        description: json['description'],
        isActive: json['isActive'] != false,
        inclusions: ((json['inclusions'] as List?) ?? const []).map((e) => Inclusion.fromJson(e)).toList(),
        createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse('${json['updatedAt']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
        makeupType: json['makeupType'],
        brands: ((json['brands'] as List?) ?? const []).map((e) => '$e').toList(),
        productDetails: json['productDetails'],
        photoUrl: json['photoUrl'],
        category: json['category'] is Map ? (json['category']['name'])?.toString() : json['category']?.toString(),
      );
}
