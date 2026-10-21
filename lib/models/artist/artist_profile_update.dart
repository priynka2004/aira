// FILE: models/artist/artist_profile_update.dart  |  MODEL
// Request body for PUT /artists/profile/update/.
// Commission, approval and rating fields are ignored by the server if sent.

/// Model: Artist Profile Update.
class ArtistProfileUpdate {
  final String? bio;
  final int? yearsExperience;
  final String? city;
  final String? displayName; // max 100
  final String? dateOfBirth; // YYYY-MM-DD, age >= 18
  final String? instagramUrl; // https://instagram.com/<handle>
  final String? profileType; // freelance | studio
  final int? travelTimeBeforeMinutes; // 0-240
  final int? returnBufferMinutes; // 0-240
  final int? baseAddressId;

  ArtistProfileUpdate({
    this.bio,
    this.yearsExperience,
    this.city,
    this.displayName,
    this.dateOfBirth,
    this.instagramUrl,
    this.profileType,
    this.travelTimeBeforeMinutes,
    this.returnBufferMinutes,
    this.baseAddressId,
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        if (bio != null) 'bio': bio,
        if (yearsExperience != null) 'years_experience': yearsExperience,
        if (city != null) 'city': city,
        if (displayName != null) 'display_name': displayName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (instagramUrl != null) 'instagram_url': instagramUrl,
        if (profileType != null) 'profile_type': profileType,
        if (travelTimeBeforeMinutes != null) 'travel_time_before_minutes': travelTimeBeforeMinutes,
        if (returnBufferMinutes != null) 'return_buffer_minutes': returnBufferMinutes,
        if (baseAddressId != null) 'base_address_id': baseAddressId,
      };
}
