// FILE: api/booking_journey_service.dart
// Booking lifecycle APIs: On My Way -> Arrived -> Start PIN -> Complete Service (request) -> Completion PIN.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking/booking.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import 'booking_service.dart';

/// Exception type: Journey Reason Error.
class JourneyReasonError implements Exception {
  final String reason;
  JourneyReasonError(this.reason);
  /// Readable text for logs.
  @override
  String toString() => reason;
}

/// Booking Journey Service — API/data layer.
class BookingJourneyService {
  final ApiService _apiService;
  late final BookingService _bookingService;

  BookingJourneyService(this._apiService) {
    _bookingService = BookingService(_apiService);
  }

  static const _lockPrefsPrefix = 'booking_lockout_';
  /// Reason from.
  String _reasonFrom(Object error) {
    var msg = error.toString();
    if (msg.startsWith('Exception: ')) msg = msg.substring('Exception: '.length);
    const marker = 'Value Error ';
    final idx = msg.indexOf(marker);
    if (idx != -1) return msg.substring(idx + marker.length).trim();
    return msg.trim();
  }

  /// Gets booking.
  Future<Booking> getBooking(int bookingId) => _bookingService.getBooking(bookingId);

  /// Marks on my way.
  /// API: PUT /artists/bookings/on_my_way/
  Future<Booking> markOnMyWay(int bookingId) async {
    try {
      await _apiService.put(ApiEndpoints.artistBookingsOnMyWay, data: {'booking_id': bookingId});
    } catch (e) {
      throw JourneyReasonError(_reasonFrom(e));
    }
    return getBooking(bookingId);
  }

  /// Marks arrival. No OTP any more — the backend immediately creates the Start Service PIN
  /// and notifies the customer.
  /// API: PUT /artists/bookings/arrived/   body: {"booking_id": int}
  Future<Booking> markArrived(int bookingId) async {
    try {
      await _apiService.put(ApiEndpoints.artistBookingsArrived, data: {'booking_id': bookingId});
    } catch (e) {
      throw JourneyReasonError(_reasonFrom(e));
    }
    return getBooking(bookingId);
  }

  static const _completionReqPrefix = 'completion_pin_requested_';

  /// True if the artist already tapped "Complete Service" for this booking.
  Future<bool> isCompletionRequested(int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_completionReqPrefix$bookingId') ?? false;
  }

  /// Forgets the local "requested" flag (e.g. server says the PIN was never requested).
  Future<void> clearCompletionRequested(int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_completionReqPrefix$bookingId');
  }

  /// Artist taps "Complete Service": the backend creates the Completion PIN and notifies the customer.
  /// Calling again re-sends the notification (same PIN), at most once a minute.
  /// API: PUT /artists/bookings/completion_pin/request/   body: {"booking_id": int}
  Future<void> requestCompletionPin(int bookingId) async {
    try {
      await _apiService.put(ApiEndpoints.artistBookingsCompletionPinRequest, data: {'booking_id': bookingId});
    } catch (e) {
      throw JourneyReasonError(_reasonFrom(e));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_completionReqPrefix$bookingId', true);
  }

  /// Verifies start PIN.
  /// API: PUT /artists/bookings/start_pin/verify/
  Future<Booking> verifyStartPin(int bookingId, String pin) async {
    try {
      await _apiService.put(ApiEndpoints.artistBookingsStartPinVerify, data: {
        'booking_id': bookingId,
        'start_service_pin': int.tryParse(pin) ?? pin,
      });
    } catch (e) {
      final reason = _reasonFrom(e);
      if (reason == 'account_locked') await _recordLockout(bookingId, 'start');
      throw JourneyReasonError(reason);
    }
    await _clearLockout(bookingId, 'start');
    return getBooking(bookingId);
  }

  /// Verifies completion PIN.
  /// API: PUT /artists/bookings/completion_pin/verify/
  Future<Booking> verifyCompletionPin(int bookingId, String pin) async {
    try {
      await _apiService.put(ApiEndpoints.artistBookingsCompletionPinVerify, data: {
        'booking_id': bookingId,
        'completion_pin': int.tryParse(pin) ?? pin,
      });
    } catch (e) {
      final reason = _reasonFrom(e);
      if (reason == 'account_locked') await _recordLockout(bookingId, 'complete');
      throw JourneyReasonError(reason);
    }
    await _clearLockout(bookingId, 'complete');
    return getBooking(bookingId);
  }

  /// Lock key.
  String _lockKey(int bookingId, String stage) => '$_lockPrefsPrefix${bookingId}_$stage';

  /// Records lockout.
  Future<void> _recordLockout(int bookingId, String stage) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _lockKey(bookingId, stage);
    if (prefs.getString(key) == null) {
      await prefs.setString(key, DateTime.now().add(const Duration(minutes: 30)).toIso8601String());
    }
  }

  /// Clears lockout.
  Future<void> _clearLockout(int bookingId, String stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockKey(bookingId, stage));
  }

  /// Lockout remaining.
  Future<Duration?> lockoutRemaining(int bookingId, String stage) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lockKey(bookingId, stage));
    if (raw == null) return null;
    final until = DateTime.tryParse(raw);
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) {
      await _clearLockout(bookingId, stage);
      return null;
    }
    return remaining;
  }
}
