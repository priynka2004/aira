class StatusItem {
  final int statusId;
  final String name;
  final String? description;

  StatusItem({
    required this.statusId,
    required this.name,
    this.description,
  });

  /// Was silently crashing (and taking down the ENTIRE bookings load with
  /// it — see CoreService.getBookingStatuses being awaited together with
  /// the bookings/profile calls in Future.wait) whenever the backend sent
  /// `status_id`/`status` instead of `statusId`/`name` — every other model
  /// in this app (Booking, etc.) already accepts both shapes; this one
  /// didn't, and a single bad StatusItem killed the whole dashboard load,
  /// which in turn made every status lookup across the app (booking list,
  /// Insights completion rate, Finance) resolve to nothing.
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
