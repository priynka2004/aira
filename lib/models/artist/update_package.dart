// FILE: models/artist/update_package.dart  |  MODEL
// Request body to update a package. `brands: []` clears brands; existing bookings keep their snapshot.

/// Model: Update Package.
class UpdatePackage {
  final int packageId;
  final int? subCategoryId;
  final String? name;
  final double? price;
  final int? durationMinutes;
  final String? description;
  final bool? isActive;
  final List<String>? inclusions;
  final String? makeupType;
  final List<String>? brands;
  final String? productDetails;

  UpdatePackage({
    required this.packageId,
    this.subCategoryId,
    this.name,
    this.price,
    this.durationMinutes,
    this.description,
    this.isActive,
    this.inclusions,
    this.makeupType,
    this.brands,
    this.productDetails,
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        'package_id': packageId,
        if (subCategoryId != null) 'sub_category_id': subCategoryId,
        if (name != null) 'name': name,
        if (price != null) 'price': price?.toStringAsFixed(2),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (description != null) 'description': description,
        if (isActive != null) 'is_active': isActive,
        if (inclusions != null) 'inclusions': inclusions,
        if (makeupType != null) 'makeup_type': makeupType,
        if (brands != null) 'brands': brands,
        if (productDetails != null) 'product_details': productDetails,
      };
}
