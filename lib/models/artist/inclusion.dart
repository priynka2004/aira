// FILE: models/artist/inclusion.dart  |  MODEL
// One inclusion line inside a package.

/// Model: Inclusion.
class Inclusion {
  final int inclusionId;
  final String inclusionText;
  final int order;

  Inclusion({
    required this.inclusionId,
    required this.inclusionText,
    required this.order,
  });

  /// Builds this object from API JSON.
  factory Inclusion.fromJson(Map<String, dynamic> json) => Inclusion(
    inclusionId: json['inclusionId'],
    inclusionText: json['inclusionText'],
    order: json['order'],
  );
}
