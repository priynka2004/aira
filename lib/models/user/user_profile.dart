// FILE: models/user/user_profile.dart  |  MODEL
// User profile returned by GET /users/profile/get/.
// Your own profile has everything; for another user only userId, name and role come back
// (email, phoneNumber, isActive, createdAt, fcmToken may be absent) — so those are optional.

/// Model: User Profile.
class UserProfile {
  final int userId;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final bool isActive;
  final DateTime? createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.isActive = true,
    this.createdAt,
  });

  /// Builds this object from API JSON.
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: (json['userId'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        email: json['email'],
        phoneNumber: json['phoneNumber'],
        role: json['role'],
        isActive: json['isActive'] != false,
        createdAt: json['createdAt'] == null ? null : DateTime.tryParse('${json['createdAt']}'),
      );
}
