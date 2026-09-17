import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking/booking.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import 'booking_service.dart';

/// Thrown by every [BookingJourneyService] mutation with the backend's
/// raw reason code (e.g. `otp_invalid`, `arrived_not_allowed`,
/// `account_locked`, `on_my_way_too_early`) so the screen can show the
/// right message per the field guide's per-endpoint reason tables,
/// instead of a generic error string.
class JourneyReasonError implements Exception {
  final String reason;
  JourneyReasonError(this.reason);
  @override
  String toString() => reason;
}

/// Artist-side actions for the booking lifecycle's real backend
/// endpoints (see the Booking Lifecycle Field Guide, endpoints 03–06):
///
///   PUT /artists/bookings/on_my_way/
///   PUT /artists/bookings/arrived/                (artist enters the
///       Booking OTP that was sent to them at booking creation)
///   PUT /artists/bookings/start_pin/verify/        (artist enters the
///       4-digit code the customer reads out)
///   PUT /artists/bookings/completion_pin/verify/   (same, once done)
///
/// Every method re-fetches and returns the fresh [Booking] on success so
/// the caller can derive the next [JourneyStage] straight from it — there
/// is no local journey state to fall out of sync with the backend.
class BookingJourneyService {
  final ApiService _apiService;
  late final BookingService _bookingService;

  BookingJourneyService(this._apiService) {
    _bookingService = BookingService(_apiService);
  }

  static const _lockPrefsPrefix = 'booking_lockout_';

  /// Extracts the backend's reason code out of a thrown exception's
  /// message. Business-rule failures come back as `"Value Error
  /// <reason>"` (see the field guide's wire-conventions table); this
  /// pulls out just `<reason>`, falling back to the raw message for
  /// anything shaped differently (e.g. a field-validation 400, or a
  /// network error).
  String _reasonFrom(Object error) {
    var msg = error.toString();
    if (msg.startsWith('Exception: ')) msg = msg.substring('Exception: '.length);
    const marker = 'Value Error ';
    final idx = msg.indexOf(marker);
    if (idx != -1) return msg.substring(idx + marker.length).trim();
    return msg.trim();
  }

  Future<Booking> getBooking(int bookingId) => _bookingService.getBooking(bookingId);

  /// PUT /artists/bookings/on_my_way/
  /// Backend enforces the 2h-before-start window itself (don't rely on
  /// hiding the button client-side) — a too-early tap surfaces as
  /// [JourneyReasonError] with reason `on_my_way_too_early`.
  Future<Booking> markOnMyWay(int bookingId) async {
    try {
      await _apiService.put(ApiEndpoints.artistBookingsOnMyWay, data: {'booking_id': bookingId});
    } catch (e) {
      throw JourneyReasonError(_reasonFrom(e));
    }
    return getBooking(bookingId);
  }

  /// PUT /artists/bookings/arrived/ — the artist types in the 6-digit
  /// Booking OTP that was pushed to their own notifications/SMS at
  /// booking-creation time. Reasons: `booking_not_found`,
  /// `arrived_not_allowed`, `account_locked`, `otp_invalid`.
  Future<Booking> confirmArrival(int bookingId, String bookingOtp) async {
    try {
      await _apiService.put(ApiEndpoints.artistBookingsArrived, data: {
        'booking_id': bookingId,
        'booking_otp': int.tryParse(bookingOtp) ?? bookingOtp,
      });
    } catch (e) {
      final reason = _reasonFrom(e);
      if (reason == 'account_locked') await _recordLockout(bookingId, 'arrive');
      throw JourneyReasonError(reason);
    }
    await _clearLockout(bookingId, 'arrive');
    return getBooking(bookingId);
  }

  /// PUT /artists/bookings/start_pin/verify/ — the artist types in the
  /// 4-digit code the customer reads out loud. On success, `statusId`
  /// moves to `in_progress` and the Completion PIN is minted. Reasons:
  /// `booking_not_found`, `start_pin_verify_not_allowed`,
  /// `account_locked`, `start_pin_invalid`.
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

  /// PUT /artists/bookings/completion_pin/verify/ — same shape, once the
  /// service is actually finished. On success `statusId` moves to
  /// `completed` — the end state. Reasons: `booking_not_found`,
  /// `completion_pin_verify_not_allowed`, `account_locked`,
  /// `completion_pin_invalid`.
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

  // ── Lockout countdown (local-only UI aid) ───────────────────────────
  // The 5-wrong-attempts / 30-minute lockout is enforced server-side on
  // every retry regardless of what's stored here. The backend doesn't
  // return a "time remaining" value with `account_locked`, so this just
  // remembers *when* that reason was first seen for a given
  // booking+credential and shows an approximate countdown from there, per
  // the field guide's "show the lock clearly" edge-case note.
  String _lockKey(int bookingId, String stage) => '$_lockPrefsPrefix${bookingId}_$stage';

  Future<void> _recordLockout(int bookingId, String stage) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _lockKey(bookingId, stage);
    if (prefs.getString(key) == null) {
      await prefs.setString(key, DateTime.now().add(const Duration(minutes: 30)).toIso8601String());
    }
  }

  Future<void> _clearLockout(int bookingId, String stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockKey(bookingId, stage));
  }

  /// Null if not (locally believed to be) locked, otherwise how much
  /// time is left in the approximate 30-minute window.
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
