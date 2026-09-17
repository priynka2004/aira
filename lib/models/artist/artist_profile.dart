class ArtistProfile {
  final int artistId;
  final int userId;
  final String? bio;
  final int yearsExperience;
  final String? city;
  final int serviceRadiusKm;
  final double avgRating;
  final int totalReviews;
  final double commissionRate;
  final int? approvalStatusId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArtistProfile({
    required this.artistId,
    required this.userId,
    this.bio,
    required this.yearsExperience,
    this.city,
    required this.serviceRadiusKm,
    required this.avgRating,
    required this.totalReviews,
    required this.commissionRate,
    this.approvalStatusId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtistProfile.fromJson(Map<String, dynamic> json) => ArtistProfile(
    artistId: json['artistId'],
    userId: json['userId'],
    bio: json['bio'],
    yearsExperience: json['yearsExperience'],
    city: json['city'],
    serviceRadiusKm: json['serviceRadiusKm'],
    avgRating: double.parse(json['avgRating']),
    totalReviews: json['totalReviews'],
    commissionRate: double.parse(json['commissionRate']),
    approvalStatusId: json['approvalStatusId'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
