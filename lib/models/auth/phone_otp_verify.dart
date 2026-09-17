class PhoneOtpVerify {
  final String phoneNumber;
  final String otp;

  PhoneOtpVerify({required this.phoneNumber, required this.otp});

  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    'otp': otp,
  };
}
