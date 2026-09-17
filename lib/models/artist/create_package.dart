class CreatePackage {
  final int subCategoryId;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final List<String>? inclusions;

  CreatePackage({
    required this.subCategoryId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.inclusions,
  });

  Map<String, dynamic> toJson() => {
    'sub_category_id': subCategoryId,
    'name': name,
    'price': price.toStringAsFixed(2),
    'duration_minutes': durationMinutes,
    if (description != null) 'description': description,
    if (inclusions != null) 'inclusions': inclusions,
  };
}
