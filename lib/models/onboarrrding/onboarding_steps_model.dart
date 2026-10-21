// FILE: models/onboarrrding/onboarding_steps_model.dart  |  MODEL
// Data collected in each onboarding step (identity, artistry, KYC, payout).

import 'package:image_picker/image_picker.dart';

/// Enum: Gov ID Type values.
enum GovIdType {
  aadhaar('Aadhaar Card'),
  voterId('Voter ID'),
  passport('Passport'),
  drivingLicense('Driving Licence');

  final String label;
  const GovIdType(this.label);
}

/// Model: Step One Identity Data.
class StepOneIdentityData {
  String fullName;
  String displayName;
  bool sameAsFullName;
  DateTime? dob;
  String instagramLink;

  StepOneIdentityData({
    this.fullName = '',
    this.displayName = '',
    this.sameAsFullName = false,
    this.dob,
    this.instagramLink = '',
  });
}

/// Model: Step Two Artistry Data.
class StepTwoArtistryData {
  String? experience;
  final Set<String> specialities = {};
  final List<XFile> workPhotos = [];
}

/// Model: Step Three Kyc Data.
class StepThreeKycData {
  GovIdType idType = GovIdType.aadhaar;
  String idNumber = '';
  XFile? idFront;
  XFile? idBack;
  String panNumber = '';
  XFile? panImage;
}

/// Model: Step Four Payout Agreement Data.
class StepFourPayoutAgreementData {
  String accountHolder = '';
  String accountNumber = '';
  String confirmAccountNumber = '';
  String ifscCode = '';
  String bankName = '';
  String upiId = '';
  bool agreeTerms = false;
}