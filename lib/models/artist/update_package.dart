class UpdatePackage {
  final int packageId;
  final int? subCategoryId;
  final String? name;
  final double? price;
  final int? durationMinutes;
  final String? description;
  final bool? isActive;
  final List<String>? inclusions;

  UpdatePackage({
    required this.packageId,
    this.subCategoryId,
    this.name,
    this.price,
    this.durationMinutes,
    this.description,
    this.isActive,
    this.inclusions,
  });

  Map<String, dynamic> toJson() => {
    'package_id': packageId,
    if (subCategoryId != null) 'sub_category_id': subCategoryId,
    if (name != null) 'name': name,
    if (price != null) 'price': price?.toStringAsFixed(2),
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
    if (description != null) 'description': description,
    if (isActive != null) 'is_active': isActive,
    if (inclusions != null) 'inclusions': inclusions,
  };
}
