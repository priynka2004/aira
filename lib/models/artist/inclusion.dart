class Inclusion {
  final int inclusionId;
  final String inclusionText;
  final int order;

  Inclusion({
    required this.inclusionId,
    required this.inclusionText,
    required this.order,
  });

  factory Inclusion.fromJson(Map<String, dynamic> json) => Inclusion(
    inclusionId: json['inclusionId'],
    inclusionText: json['inclusionText'],
    order: json['order'],
  );
}
