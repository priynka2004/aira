// FILE: helper/booking_stats.dart
// Numbers computed from the artist's bookings: earnings, weekly totals, completed / pending counts, status mapping.

import '../models/booking/booking.dart';
import '../models/core/status_item.dart';
import '../models/models.dart';

/// Booking Stats.
class BookingStats {
  final List<Booking> bookings;
  final List<StatusItem> statuses;

  BookingStats(this.bookings, this.statuses);

  /// Status label.
  String statusLabel(int statusId) {
    final match = statuses.where((s) => s.statusId == statusId);
    return match.isNotEmpty ? match.first.name.toLowerCase() : '';
  }

  /// Maps status.
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

  /// Returns true if cancelled.
  bool _isCancelled(Booking b) {
    final l = statusLabel(b.statusId);
    return l == 'cancelled' || l == 'no_show';
  }

  /// Returns true if completed.
  bool _isCompleted(Booking b) => statusLabel(b.statusId) == 'completed';

  /// Counts toward earnings.
  bool _countsTowardEarnings(Booking b) => !_isCancelled(b);

  /// Date of.
  DateTime? _dateOf(Booking b) {
    try {
      return DateTime.parse(b.bookingDate);
    } catch (_) {
      return null;
    }
  }

  /// Starts of week.
  DateTime get _startOfWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  /// Starts of prev week.
  DateTime get _startOfPrevWeek => _startOfWeek.subtract(const Duration(days: 7));

  /// Total earnings.
  double get totalEarnings =>
      bookings.where(_countsTowardEarnings).fold(0.0, (sum, b) => sum + b.totalAmount);

  /// Week earnings.
  double get weekEarnings {
    final start = _startOfWeek;
    final end = start.add(const Duration(days: 7));
    return bookings.where((b) {
      if (!_countsTowardEarnings(b)) return false;
      final d = _dateOf(b);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  /// Prev week earnings.
  double get _prevWeekEarnings {
    final start = _startOfPrevWeek;
    final end = _startOfWeek;
    return bookings.where((b) {
      if (!_countsTowardEarnings(b)) return false;
      final d = _dateOf(b);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  /// Week change percent.
  double get weekChangePercent {
    final prev = _prevWeekEarnings;
    if (prev <= 0) return 0;
    return ((weekEarnings - prev) / prev) * 100;
  }

  /// Completed count.
  int get completedCount => bookings.where(_isCompleted).length;

  /// Pending value.
  double get pendingValue => bookings
      .where((b) => !_isCompleted(b) && !_isCancelled(b))
      .fold(0.0, (sum, b) => sum + b.totalAmount);

  /// Week daily totals.
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

  /// Todays appointments.
  List<Booking> get todaysAppointments {
    final now = DateTime.now();
    final list = bookings.where((b) {
      if (_isCancelled(b)) return false;
      final d = _dateOf(b);
      return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  /// This month appointments.
  List<Booking> get thisMonthAppointments {
    final now = DateTime.now();
    return bookings.where((b) {
      if (_isCancelled(b)) return false;
      final d = _dateOf(b);
      return d != null && d.year == now.year && d.month == now.month;
    }).toList();
  }

  /// Last n weeks totals.
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

  /// Recent transactions.
  List<Booking> get recentTransactions {
    final list = bookings.where(_countsTowardEarnings).toList();
    list.sort((a, b) {
      final da = _dateOf(a);
      final db = _dateOf(b);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return list;
  }
}
