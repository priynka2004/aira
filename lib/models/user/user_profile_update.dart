class UserProfileUpdate {
  final String? name;
  final String? email;
  final String? phoneNumber;
  // Backend's user profile already returns this field (see GET
  // /users/profile/get/ → "fcmToken"), so PUT /users/profile/update/ is
  // the real, existing endpoint to push a new token through — there's no
  // separate /users/fcm-token/update/ endpoint on this backend.
  final String? fcmToken;

  UserProfileUpdate({this.name, this.email, this.phoneNumber, this.fcmToken});

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (fcmToken != null) 'fcm_token': fcmToken,
  };
}
