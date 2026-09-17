import '../models/booking/booking.dart';
import '../models/core/status_item.dart';
import '../models/models.dart';

/// Turns a raw list of [Booking]s (from GET /artists/bookings/get_all/)
/// into the aggregate numbers the Dashboard and Earnings screens need.
/// Centralizing this means both screens always agree on what counts as
/// "this week", "completed", "today", etc.
///
/// Known backend gap: Booking has no payment-status field, so "pending"
/// here is a proxy (value of bookings not yet completed/cancelled), not a
/// real payment state.
class BookingStats {
  final List<Booking> bookings;
  final List<StatusItem> statuses;

  BookingStats(this.bookings, this.statuses);

  String statusLabel(int statusId) {
    final match = statuses.where((s) => s.statusId == statusId);
    return match.isNotEmpty ? match.first.name.toLowerCase() : '';
  }

  /// Maps a raw backend `statusId` to the UI's [SlotStatus], via [statuses]
  /// (GET /core/booking-statuses/ or similar — id → name lookup table).
  /// Shared by [AiraAppShellState] (list view) and [BookingDetailScreen]
  /// (detail view, including its live Firestore listener) so both always
  /// agree on what a given statusId means — one lookup, not two copies
  /// that could drift apart.
  ///
  /// [cancelledBy] should be passed whenever it's available on the
  /// booking. Backend data has been observed with `cancelledBy`/
  /// `cancellationReason` set while `statusId` still resolves to
  /// "confirmed" or "in_progress" instead of "cancelled" (a backend data
  /// bug — see testing notes) — trusting `statusId` alone in that case
  /// makes the app offer Accept/On My Way/etc. on a booking that's
  /// actually dead. A non-null `cancelledBy` always wins over whatever
  /// `statusId` says.
  static SlotStatus mapStatus(int statusId, List<StatusItem> statuses, {String? cancelledBy}) {
    if (cancelledBy != null && cancelledBy.isNotEmpty) {
      return SlotStatus.cancelled;
    }
    final match = statuses.where((s) => s.statusId == statusId);
    final label = match.isNotEmpty ? match.first.name.toLowerCase() : '';
    switch (label) {
      case 'pending':
        return SlotStatus.pending;
      case 'confirmed':
        return SlotStatus.confirmed;
      case 'in_progress':
        return SlotStatus.inProgress;
      case 'completed':
        return SlotStatus.completed;
      case 'cancelled':
        return SlotStatus.cancelled;
      case 'no_show':
        return SlotStatus.noShow;
      default:
        return SlotStatus.open;
    }
  }

  bool _isCancelled(Booking b) {
    final l = statusLabel(b.statusId);
    return l == 'cancelled' || l == 'no_show';
  }

  bool _isCompleted(Booking b) => statusLabel(b.statusId) == 'completed';

  bool _countsTowardEarnings(Booking b) => !_isCancelled(b);

  DateTime? _dateOf(Booking b) {
    try {
      return DateTime.parse(b.bookingDate);
    } catch (_) {
      return null;
    }
  }

  DateTime get _startOfWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1)); // Monday
  }

  DateTime get _startOfPrevWeek => _startOfWeek.subtract(const Duration(days: 7));

  /// Total value of all non-cancelled bookings.
  double get totalEarnings =>
      bookings.where(_countsTowardEarnings).fold(0.0, (sum, b) => sum + b.totalAmount);

  /// Value of non-cancelled bookings falling in the current Mon–Sun week.
  double get weekEarnings {
    final start = _startOfWeek;
    final end = start.add(const Duration(days: 7));
    return bookings.where((b) {
      if (!_countsTowardEarnings(b)) return false;
      final d = _dateOf(b);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  double get _prevWeekEarnings {
    final start = _startOfPrevWeek;
    final end = _startOfWeek;
    return bookings.where((b) {
      if (!_countsTowardEarnings(b)) return false;
      final d = _dateOf(b);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  /// % change of this week's earnings vs last week's. 0 when there's no
  /// prior-week data to compare against (avoids a misleading spike).
  double get weekChangePercent {
    final prev = _prevWeekEarnings;
    if (prev <= 0) return 0;
    return ((weekEarnings - prev) / prev) * 100;
  }

  int get completedCount => bookings.where(_isCompleted).length;

  /// Rough "pending" value: bookings not yet completed or cancelled.
  double get pendingValue => bookings
      .where((b) => !_isCompleted(b) && !_isCancelled(b))
      .fold(0.0, (sum, b) => sum + b.totalAmount);

  /// Earnings per day for the current Mon–Sun week, in order (index 0 = Mon).
  List<double> get weekDailyTotals {
    final start = _startOfWeek;
    final totals = List<double>.filled(7, 0);
    for (final b in bookings) {
      if (!_countsTowardEarnings(b)) continue;
      final d = _dateOf(b);
      if (d == null) continue;
      final diff = d.difference(start).inDays;
      if (diff >= 0 && diff < 7) totals[diff] += b.totalAmount;
    }
    return totals;
  }

  List<Booking> get todaysAppointments {
    final now = DateTime.now();
    final list = bookings.where((b) {
      if (_isCancelled(b)) return false;
      final d = _dateOf(b);
      // Compare parsed date components rather than the raw string —
      // a raw `b.bookingDate == todayStr` match silently breaks (and
      // dashboard stats read as 0) if the backend ever sends the date
      // with a time component, different padding, or stray whitespace,
      // even though the date is genuinely today.
      return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  /// Totals for the last [weeks] Mon–Sun weeks, oldest first, ending with
  /// the current week. Used for the "Month" view of the performance chart.
  List<double> lastNWeeksTotals(int weeks) {
    final currentWeekStart = _startOfWeek;
    final totals = List<double>.filled(weeks, 0);
    for (final b in bookings) {
      if (!_countsTowardEarnings(b)) continue;
      final d = _dateOf(b);
      if (d == null) continue;
      final weeksAgo = currentWeekStart.difference(
          d.subtract(Duration(days: d.weekday - 1)))
          .inDays ~/
          7;
      final index = weeks - 1 - weeksAgo;
      if (index >= 0 && index < weeks) totals[index] += b.totalAmount;
    }
    return totals;
  }

  List<Booking> get recentTransactions {
    final list = bookings.where(_countsTowardEarnings).toList();
    list.sort((a, b) {
      final da = _dateOf(a);
      final db = _dateOf(b);
      if (da == null || db == null) return 0;
      return db.compareTo(da); // most recent first
    });
    return list;
  }
}
