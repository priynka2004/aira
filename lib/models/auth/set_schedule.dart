// FILE: models/auth/set_schedule.dart  |  MODEL
// Request body: set weekly working hours for a day.

/// Model: Set Schedule.
class SetSchedule {
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int? locationTypeId;

  SetSchedule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.locationTypeId,
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    if (locationTypeId != null) 'location_type_id': locationTypeId,
  };
}
