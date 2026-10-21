// FILE: models/core/service_category.dart  |  MODEL
// Master data: service category.

/// Model: Service Category.
class ServiceCategory {
  final int categoryId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceCategory({
    required this.categoryId,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds this object from API JSON.
  factory ServiceCategory.fromJson(Map<String, dynamic> json) => ServiceCategory(
    categoryId: json['categoryId'],
    name: json['name'],
    description: json['description'],
    isActive: json['isActive'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
