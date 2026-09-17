class CustomerAddressUpdate {
  final int addressId;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? pinCode;
  final bool? isDefault;

  CustomerAddressUpdate({
    required this.addressId,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.pinCode,
    this.isDefault,
  });

  Map<String, dynamic> toJson() => {
    'address_id': addressId,
    if (addressLine1 != null) 'address_line_1': addressLine1,
    if (addressLine2 != null) 'address_line_2': addressLine2,
    if (city != null) 'city': city,
    if (pinCode != null) 'pin_code': pinCode,
    if (isDefault != null) 'is_default': isDefault,
  };
}
