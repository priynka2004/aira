class UserProfile {
  final int userId;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final bool isActive;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    this.email,
    this.phoneNumber,
    this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'],
    name: json['name'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    role: json['role'],
    isActive: json['isActive'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
