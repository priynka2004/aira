// FILE: models/booking/booking_reschedule.dart  |  MODEL
// Reschedule request data (who asked, status, old/new time) + date formatting.

/// Enum: Reschedule By values.
enum RescheduleBy { artist, customer }

/// Enum: Reschedule Status values.
enum RescheduleStatus { requested, accepted, declined, counterProposed, withdrawn }

/// Model: Booking Reschedule.
class BookingReschedule {
  final int bookingId;
  final RescheduleBy requestedBy;
  final DateTime oldStart;
  final DateTime newStart;
  final String reason;
  final String note;
  final RescheduleStatus status;
  final DateTime createdAt;
  final DateTime? suggestedStart;

  const BookingReschedule({
    required this.bookingId,
    required this.requestedBy,
    required this.oldStart,
    required this.newStart,
    required this.reason,
    this.note = '',
    this.status = RescheduleStatus.requested,
    required this.createdAt,
    this.suggestedStart,
  });

  /// Returns true if pending.
  bool get isPending => status == RescheduleStatus.requested;
  /// Creates from customer.
  bool get fromCustomer => requestedBy == RescheduleBy.customer;
  /// Creates from artist.
  bool get fromArtist => requestedBy == RescheduleBy.artist;

  /// Returns a copy with some fields changed.
  BookingReschedule copyWith({RescheduleStatus? status, DateTime? suggestedStart, String? note}) => BookingReschedule(
        bookingId: bookingId,
        requestedBy: requestedBy,
        oldStart: oldStart,
        newStart: newStart,
        reason: reason,
        note: note ?? this.note,
        status: status ?? this.status,
        createdAt: createdAt,
        suggestedStart: suggestedStart ?? this.suggestedStart,
      );

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'requestedBy': requestedBy.name,
        'oldStart': oldStart.toIso8601String(),
        'newStart': newStart.toIso8601String(),
        'reason': reason,
        'note': note,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        if (suggestedStart != null) 'suggestedStart': suggestedStart!.toIso8601String(),
      };

  /// Builds from API JSON.
  static BookingReschedule? fromJson(Map<String, dynamic> j) {
    final oldS = DateTime.tryParse('${j['oldStart']}');
    final newS = DateTime.tryParse('${j['newStart']}');
    final id = j['bookingId'] is int ? j['bookingId'] as int : int.tryParse('${j['bookingId']}');
    if (oldS == null || newS == null || id == null) return null;
    return BookingReschedule(
      bookingId: id,
      requestedBy: RescheduleBy.values.firstWhere((e) => e.name == j['requestedBy'], orElse: () => RescheduleBy.artist),
      oldStart: oldS,
      newStart: newS,
      reason: (j['reason'] ?? '').toString(),
      note: (j['note'] ?? '').toString(),
      status: RescheduleStatus.values.firstWhere((e) => e.name == j['status'], orElse: () => RescheduleStatus.requested),
      createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
      suggestedStart: DateTime.tryParse('${j['suggestedStart']}'),
    );
  }
}

/// Model: Reschedule Fmt.
class RescheduleFmt {
  RescheduleFmt._();
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Date long.
  static String dateLong(DateTime d) => '${_days[d.weekday - 1]}, ${date(d)}';

  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  /// Date time.
  static String dateTime(DateTime d) => '${date(d)} • ${time(d)}';
}
