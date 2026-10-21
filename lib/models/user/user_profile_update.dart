// FILE: models/user/user_profile_update.dart  |  MODEL
// Request body for PUT /users/profile/update/.
// Only `name` and `fcm_token` may be sent. Email / phone can no longer be changed here —
// sending a different value returns 400; use the OTP flow (/users/contact/change/request/ → /verify/).

/// Model: User Profile Update.
class UserProfileUpdate {
  final String? name;
  final String? fcmToken;

  UserProfileUpdate({this.name, this.fcmToken});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };
}
