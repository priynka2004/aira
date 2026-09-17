class AddService {
  final int subCategoryId;
  final double? customPrice;
  final int? customDurationMinutes;

  AddService({
    required this.subCategoryId,
    this.customPrice,
    this.customDurationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'sub_category_id': subCategoryId,
    if (customPrice != null) 'custom_price': customPrice?.toStringAsFixed(2),
    if (customDurationMinutes != null)
      'custom_duration_minutes': customDurationMinutes,
  };
}
