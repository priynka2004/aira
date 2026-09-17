/// `open` / `clash` are UI-only states kept for the "empty slot" and
/// "AiRA detected a conflict" cards; the rest map 1:1 onto the backend's
/// `/artists/bookings/update_status/` status strings.
///
/// `pending` is the backend's `statusId: 1` — a booking request the
/// customer has placed that the artist has not yet accepted or rejected.
/// It is distinct from `open` (a synthetic "empty slot" row that has no
/// backing booking at all).
enum SlotStatus { pending, confirmed, inProgress, completed, cancelled, noShow, open, clash }

class BookingSlot {
  /// Null for synthetic "open slot" rows that don't exist in the backend.
  final int? bookingId;
  /// Raw ISO date (yyyy-MM-dd) this slot falls on, straight from the API's
  /// `bookingDate` — used to group/filter slots by day.
  final String date;
  final String time;
  final String client;
  final String service;
  final SlotStatus status;
  final double? amount;

  /// Raw 24h `HH:mm[:ss]` start time straight from the backend's
  /// `startTime`. [time] above is the pretty "4:00 PM" display string —
  /// this raw form is what the journey-flow window math below needs.
  final String? rawStartTime;

  const BookingSlot({
    this.bookingId,
    required this.date,
    required this.time,
    required this.client,
    required this.service,
    required this.status,
    this.amount,
    this.rawStartTime,
  });

  /// [date] + [rawStartTime] combined into a real [DateTime], or null if
  /// either is missing/unparseable.
  DateTime? get startDateTime {
    final d = DateTime.tryParse(date);
    if (d == null || rawStartTime == null) return null;
    final parts = rawStartTime!.split(':');
    if (parts.isEmpty) return null;
    final h = int.tryParse(parts[0]);
    final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (h == null) return null;
    return DateTime(d.year, d.month, d.day, h, m ?? 0);
  }

  /// True from 2 hours before [startDateTime] to 2 hours after it —
  /// matches the backend's own enforcement on `PUT
  /// /artists/bookings/on_my_way/` ("On My Way can only be marked within
  /// 2 hours of the booking start time" — confirmed symmetric: both a
  /// booking more than 2h in the future *and* one whose start time is
  /// more than 2h in the past get rejected).
  bool get isWithinUpcomingWindow {
    final start = startDateTime;
    if (start == null) return false;
    final now = DateTime.now();
    final diff = now.difference(start).abs();
    return diff <= const Duration(hours: 2);
  }

  /// True once the booking's start time has actually arrived (or passed).
  bool get hasStartTimePassed {
    final start = startDateTime;
    if (start == null) return isBookingDay; // fall back to date-only check
    return !DateTime.now().isBefore(start);
  }

  /// True when [date] (yyyy-MM-dd) falls strictly after today's local
  /// date — i.e. this booking hasn't happened yet. Drives the
  /// "Upcoming" (non-clickable) vs "Mark complete" (clickable) button
  /// shown for `confirmed`/`inProgress` slots.
  bool get isFutureDate {
    final d = DateTime.tryParse(date);
    if (d == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return DateTime(d.year, d.month, d.day).isAfter(todayOnly);
  }

  /// True when [date] is today's local date — the actual booking day,
  /// the only day "Mark complete" should be actionable.
  bool get isBookingDay {
    final d = DateTime.tryParse(date);
    if (d == null) return false;
    final today = DateTime.now();
    return d.year == today.year && d.month == today.month && d.day == today.day;
  }

  /// True when [date] falls strictly before today's local date — used by
  /// [isMissed] as a date-only fallback so a past-dated pending/confirmed/
  /// in-progress booking always collapses to "Missed" even in the rare
  /// case [rawStartTime] is missing/unparseable and the time-based check
  /// below can't run. A prior calendar day's window has unambiguously
  /// passed regardless of what time it started.
  bool get isPastDate {
    final d = DateTime.tryParse(date);
    if (d == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return DateTime(d.year, d.month, d.day).isBefore(todayOnly);
  }

  /// True once this booking's window has fully lapsed — more than 2 hours
  /// past its scheduled start — without it ever reaching `completed`/
  /// `cancelled`/`noShow`. Drives the "Missed" status: a booking whose time
  /// has passed with the artist never having accepted/started/finished it
  /// (see the Booking Status rules — Missed = booking date/time has fully
  /// passed and the service was never carried out). Terminal statuses
  /// (completed/cancelled/noShow) are never "missed" — callers should check
  /// [status] first. Uses the same 2h grace window as
  /// [isWithinUpcomingWindow] so a booking doesn't flip to Missed the
  /// instant its start time ticks over while the artist may still be
  /// legitimately en route/mid-service.
  ///
  /// [isPastDate] is checked first and independently of time-of-day: any
  /// booking dated before today is unambiguously over, so — e.g. when
  /// viewed through the date-range picker — it can never read back as
  /// "pending"/"confirmed"/"Upcoming" with live Accept/Confirm buttons,
  /// even in the edge case where [rawStartTime] itself is missing.
  bool get isMissed {
    if (isPastDate) return true;
    final start = startDateTime;
    if (start == null) return false;
    return DateTime.now().isAfter(start.add(const Duration(hours: 2)));
  }

  BookingSlot copyWith({String? date, String? time, String? client, String? service, SlotStatus? status}) {
    return BookingSlot(
      bookingId: bookingId,
      date: date ?? this.date,
      time: time ?? this.time,
      client: client ?? this.client,
      service: service ?? this.service,
      status: status ?? this.status,
      amount: amount,
      rawStartTime: rawStartTime,
    );
  }
}
