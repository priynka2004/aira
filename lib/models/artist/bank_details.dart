// FILE: models/artist/bank_details.dart  |  MODEL
// Bank / payout details (+ update request body).

/// Model: Bank Details.
class BankDetails {
  final int? bankDetailsId;
  final int artistId;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String? bankName;
  final int? approvalStatusId;

  BankDetails({
    this.bankDetailsId,
    required this.artistId,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    this.bankName,
    this.approvalStatusId,
  });

  /// Builds this object from API JSON.
  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankDetailsId: (json['bankDetailsId'] ?? json['bank_details_id']) as int?,
      artistId: (json['artistId'] ?? json['artist_id'] ?? 0) as int,
      accountHolderName: (json['accountHolderName'] ?? json['account_holder_name'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? json['account_number'] ?? '').toString(),
      ifscCode: (json['ifscCode'] ?? json['ifsc_code'] ?? '').toString(),
      bankName: (json['bankName'] ?? json['bank_name'])?.toString(),
      approvalStatusId: (json['approvalStatusId'] ?? json['approval_status_id']) as int?,
    );
  }
}

/// Model: Bank Details Update.
class BankDetailsUpdate {
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String? bankName;

  BankDetailsUpdate({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    this.bankName,
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        if (bankName != null && bankName!.isNotEmpty) 'bank_name': bankName,
      };
}
