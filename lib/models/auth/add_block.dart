// FILE: models/auth/add_block.dart  |  MODEL
// Request body to block a date/time off.
// startTime / endTime (HH:MM:SS) are optional — without them the whole day is blocked.

/// Model: Add Block.
class AddBlock {
  final String blockDate;
  final String? note;
  final String? startTime;
  final String? endTime;

  AddBlock({required this.blockDate, this.note, this.startTime, this.endTime});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'block_date': blockDate,
    if (note != null) 'note': note,
    if (startTime != null) 'start_time': startTime,
    if (endTime != null) 'end_time': endTime,
  };
}