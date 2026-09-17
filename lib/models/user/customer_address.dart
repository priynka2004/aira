class CustomerAddress {
  final int addressId;
  final int userId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String pinCode;
  final bool isDefault;
  final DateTime createdAt;

  CustomerAddress({
    required this.addressId,
    required this.userId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.pinCode,
    required this.isDefault,
    required this.createdAt,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) => CustomerAddress(
    addressId: json['addressId'],
    userId: json['userId'],
    addressLine1: json['addressLine1'],
    addressLine2: json['addressLine2'],
    city: json['city'],
    pinCode: json['pinCode'],
    isDefault: json['isDefault'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
