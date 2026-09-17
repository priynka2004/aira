class Portfolio {
  final int portfolioId;
  final int artistId;
  final String fileUrl;
  final String mediaType;
  final int subCategoryId;
  final String? caption;
  final int? approvalStatusId;
  final bool isActive;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
    portfolioId: json['portfolioId'],
    artistId: json['artistId'],
    fileUrl: json['fileUrl'],
    mediaType: json['mediaType'],
    subCategoryId: json['subCategoryId'],
    caption: json['caption'],
    approvalStatusId: json['approvalStatusId'],
    isActive: json['isActive'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
