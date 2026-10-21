// FILE: models/artist/update_portfolio.dart  |  MODEL
// Request body to update a portfolio item (caption).

/// Model: Update Portfolio.
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

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'portfolio_id': portfolioId,
    if (caption != null) 'caption': caption,
    if (subCategoryId != null) 'sub_category_id': subCategoryId,
    if (isActive != null) 'is_active': isActive,
  };
}
