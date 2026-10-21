// FILE: models/artist/portfolio.dart  |  MODEL
// One portfolio item (photo/video + caption + approval status).

/// Model: Portfolio.
class Portfolio {
  final int portfolioId;
  final int artistId;
  final String fileUrl;
  final String mediaType;
  final int subCategoryId;
  final String? caption;
  final int? approvalStatusId;
  final bool isActive;
  final bool isWorkSample;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Portfolio({
    required this.portfolioId,
    required this.artistId,
    required this.fileUrl,
    required this.mediaType,
    required this.subCategoryId,
    this.caption,
    this.approvalStatusId,
    required this.isActive,
    this.isWorkSample = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds this object from API JSON.
  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
    portfolioId: json['portfolioId'],
    artistId: json['artistId'],
    fileUrl: json['fileUrl'],
    mediaType: json['mediaType'],
    subCategoryId: json['subCategoryId'],
    caption: json['caption'],
    approvalStatusId: json['approvalStatusId'],
    isActive: json['isActive'] != false,
    isWorkSample: json['isWorkSample'] == true,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
