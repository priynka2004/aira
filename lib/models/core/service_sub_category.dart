class ServiceSubCategory {
  final int subCategoryId;
  final int categoryId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceSubCategory({
    required this.subCategoryId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceSubCategory.fromJson(Map<String, dynamic> json) =>
      ServiceSubCategory(
        subCategoryId: json['subCategoryId'],
        categoryId: json['categoryId'],
        name: json['name'],
        description: json['description'],
        isActive: json['isActive'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}
