class UpdatePortfolio {
  final int portfolioId;
  final String? caption;
  final int? subCategoryId;
  final bool? isActive;

  UpdatePortfolio({
    required this.portfolioId,
    this.caption,
    this.subCategoryId,
    this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'portfolio_id': portfolioId,
    if (caption != null) 'caption': caption,
    if (subCategoryId != null) 'sub_category_id': subCategoryId,
    if (isActive != null) 'is_active': isActive,
  };
}
