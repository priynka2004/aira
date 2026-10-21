// FILE: models/core/service_sub_category.dart  |  MODEL
// Master data: service sub-category.

/// Model: Service Sub Category.
class ServiceSubCategory {
  final int subCategoryId;
  final int categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceSubCategory({
    required this.subCategoryId,
    required this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds this object from API JSON.
  factory ServiceSubCategory.fromJson(Map<String, dynamic> json) =>
      ServiceSubCategory(
        subCategoryId: json['subCategoryId'],
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        name: json['name'],
        description: json['description'],
        isActive: json['isActive'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}