// FILE: models/artist/kyc_document.dart  |  MODEL
// KYC document (Aadhaar / PAN) data.

/// Model: Kyc Document.
class KycDocument {
  final int? kycId;
  final int artistId;
  final String? aadharNumber;
  final String? aadharImageUrl;
  final String? aadharBackImageUrl;
  final String? panNumber;
  final String? panImageUrl;
  final String? bankImageUrl;
  final int? approvalStatusId;
  final String? createdAt;
  final String? updatedAt;

  KycDocument({
    this.kycId,
    required this.artistId,
    this.aadharNumber,
    this.aadharImageUrl,
    this.aadharBackImageUrl,
    this.panNumber,
    this.panImageUrl,
    this.bankImageUrl,
    this.approvalStatusId,
    this.createdAt,
    this.updatedAt,
  });

  /// Builds this object from API JSON.
  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      kycId: (json['kycId'] ?? json['kyc_id']) as int?,
      artistId: (json['artistId'] ?? json['artist_id'] ?? 0) as int,
      aadharNumber: (json['aadharNumber'] ?? json['aadhar_number'])?.toString(),
      aadharImageUrl: (json['aadharImageUrl'] ?? json['aadhar_image_url'])?.toString(),
      aadharBackImageUrl: (json['aadharBackImageUrl'] ?? json['aadhar_back_image_url'])?.toString(),
      panNumber: (json['panNumber'] ?? json['pan_number'])?.toString(),
      panImageUrl: (json['panImageUrl'] ?? json['pan_image_url'])?.toString(),
      bankImageUrl: (json['bankImageUrl'] ?? json['bank_document_image_url'])?.toString(),
      approvalStatusId: (json['approvalStatusId'] ?? json['approval_status_id']) as int?,
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString(),
    );
  }
}
