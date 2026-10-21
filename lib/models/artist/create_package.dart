// FILE: models/artist/create_package.dart  |  MODEL
// Request body to create a package. Price must be > 500; brands max 10 (50 chars each).

/// Model: Create Package.
class CreatePackage {
  final int subCategoryId;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final List<String>? inclusions;
  final String? makeupType; // max 50 chars
  final List<String>? brands; // free-text, max 10
  final String? productDetails;

  CreatePackage({
    required this.subCategoryId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.inclusions,
    this.makeupType,
    this.brands,
    this.productDetails,
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        'sub_category_id': subCategoryId,
        'name': name,
        'price': price.toStringAsFixed(2),
        'duration_minutes': durationMinutes,
        if (description != null) 'description': description,
        if (inclusions != null) 'inclusions': inclusions,
        if (makeupType != null && makeupType!.isNotEmpty) 'makeup_type': makeupType,
        if (brands != null) 'brands': brands,
        if (productDetails != null && productDetails!.isNotEmpty) 'product_details': productDetails,
      };
}
