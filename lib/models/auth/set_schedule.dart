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

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    if (locationTypeId != null) 'location_type_id': locationTypeId,
  };
}
