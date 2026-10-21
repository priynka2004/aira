// FILE: models/artist/add_service.dart  |  MODEL
// Request body to add a service to the artist.

/// Model: Add Service.
class AddService {
  final int subCategoryId;
  final double? customPrice;
  final int? customDurationMinutes;
  final String? description;

  AddService({
    required this.subCategoryId,
    this.customPrice,
    this.customDurationMinutes,
    this.description,
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'sub_category_id': subCategoryId,
    if (customPrice != null) 'custom_price': customPrice?.toStringAsFixed(2),
    if (customDurationMinutes != null)
      'custom_duration_minutes': customDurationMinutes,
    if (description != null && description!.isNotEmpty) 'description': description,
  };
}
