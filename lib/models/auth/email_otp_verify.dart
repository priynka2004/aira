class EmailOtpVerify {
  final String email;
  final String otp;

  EmailOtpVerify({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
  };
}
