// FILE: models/core/status_item.dart  |  MODEL
// Master data: status item (id + name) used for booking/approval/payment.

/// Model: Status Item.
class StatusItem {
  final int statusId;
  final String name;
  final String? description;

  StatusItem({
    required this.statusId,
    required this.name,
    this.description,
  });

  /// Builds this object from API JSON.
  factory StatusItem.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return StatusItem(
      statusId: parseId(json['statusId'] ?? json['status_id'] ?? json['id']),
      name: (json['name'] ?? json['status'] ?? json['label'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }
}
