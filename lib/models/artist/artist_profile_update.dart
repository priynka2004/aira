class ArtistProfileUpdate {
  final String? bio;
  final int? yearsExperience;
  final String? city;
  final int? serviceRadiusKm;

  ArtistProfileUpdate({
    this.bio,
    this.yearsExperience,
    this.city,
    this.serviceRadiusKm,
  });

  Map<String, dynamic> toJson() => {
    if (bio != null) 'bio': bio,
    if (yearsExperience != null) 'years_experience': yearsExperience,
    if (city != null) 'city': city,
    if (serviceRadiusKm != null) 'service_radius_km': serviceRadiusKm,
  };
}
