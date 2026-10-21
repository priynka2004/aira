// FILE: api/reschedule_service.dart
// Reschedule requests — now backed by the server (nothing is stored on the device).
//
// Flow (Sunndari API): the ARTIST proposes a new time → the CUSTOMER accepts / rejects (or it expires after 24 h).
//   POST /artists/bookings/reschedule/request/   propose (confirmed bookings only, ≥ 2 h ahead, one open request)
//   POST /artists/bookings/reschedule/cancel/    withdraw a pending proposal
//   GET  /artists/bookings/reschedule/get_all/   list / status
// Customers answer from their own app, so the artist app can no longer accept / decline / counter a request.

import '../models/artist/artist_extras.dart';
import '../models/booking/booking_reschedule.dart';
import '../utils/service_locator.dart';

/// Reschedule Service — API/data layer.
class RescheduleService {
  /// Request dates are DD-MM-YY (2-digit year).
  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${(d.year % 100).toString().padLeft(2, '0')}';
  String _t(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  RescheduleStatus _status(String s) => switch (s) {
        'accepted' => RescheduleStatus.accepted,
        'rejected' => RescheduleStatus.declined,
        'cancelled' => RescheduleStatus.withdrawn,
        'expired' => RescheduleStatus.withdrawn,
        _ => RescheduleStatus.requested,
      };

  /// Server YYYY-MM-DD (or DD-MM-YY / DD-MM-YYYY) + HH:MM → DateTime.
  DateTime? _parse(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final p = date.split('-').map(int.tryParse).toList();
    if (p.length != 3 || p.contains(null)) return null;
    final ymd = p[0]! > 31
        ? [p[0]!, p[1]!, p[2]!]
        : [p[2]! < 100 ? 2000 + p[2]! : p[2]!, p[1]!, p[0]!];
    final tp = (time ?? '00:00').split(':').map((e) => int.tryParse(e) ?? 0).toList();
    return DateTime(ymd[0], ymd[1], ymd[2], tp.isNotEmpty ? tp[0] : 0, tp.length > 1 ? tp[1] : 0);
  }

  BookingReschedule? _map(RescheduleRequestItem r, {DateTime? oldStart}) {
    final ns = _parse(r.proposedDate, r.proposedStartTime);
    if (ns == null) return null;
    return BookingReschedule(
      bookingId: r.bookingId,
      requestedBy: RescheduleBy.artist,
      oldStart: _parse(r.previousDate, r.previousStartTime) ?? oldStart ?? ns,
      newStart: ns,
      reason: r.reason ?? '',
      status: _status(r.status),
      createdAt: DateTime.tryParse(r.createdAt ?? '') ?? DateTime.now(),
    );
  }

  /// Latest request for a booking (pending first).
  /// API: GET /artists/bookings/reschedule/get_all/
  Future<BookingReschedule?> get(int bookingId) async {
    try {
      final list = await ServiceLocator.artistBusiness.getReschedules(bookingId: bookingId, limit: 20);
      if (list.isEmpty) return null;
      final pending = list.where((e) => e.isPending);
      return _map(pending.isNotEmpty ? pending.first : list.first);
    } catch (_) {
      return null;
    }
  }

  /// All requests, keyed by booking id (pending ones win).
  /// API: GET /artists/bookings/reschedule/get_all/
  Future<Map<int, BookingReschedule>> all() async {
    final out = <int, BookingReschedule>{};
    try {
      final list = await ServiceLocator.artistBusiness.getReschedules(limit: 100);
      for (final r in list) {
        final m = _map(r);
        if (m == null) continue;
        final cur = out[m.bookingId];
        if (cur == null || (!cur.isPending && m.isPending)) out[m.bookingId] = m;
      }
    } catch (_) {}
    return out;
  }

  /// Artist proposes a new time.
  /// API: POST /artists/bookings/reschedule/request/ (errors are shown as-is: "This slot is already booked", …)
  Future<BookingReschedule> requestAsArtist({
    required int bookingId,
    required DateTime oldStart,
    required DateTime newStart,
    required String reason,
    String note = '',
  }) async {
    await ServiceLocator.artistBusiness.requestReschedule(
      bookingId: bookingId,
      proposedDate: _d(newStart),
      proposedStartTime: _t(newStart),
      reason: _fit300([reason, note].where((e) => e.trim().isNotEmpty).join(' — ')),
    );
    return (await get(bookingId)) ??
        BookingReschedule(
          bookingId: bookingId,
          requestedBy: RescheduleBy.artist,
          oldStart: oldStart,
          newStart: newStart,
          reason: reason,
          note: note,
          createdAt: DateTime.now(),
        );
  }

  /// The API accepts at most 300 characters in `reason` (a longer text is a 400 error).
  static String _fit300(String text) {
    final t = text.trim();
    return t.length <= 300 ? t : '${t.substring(0, 297)}...';
  }

  static const _customerOnly =
      'The Customer Answers Reschedule Proposals. You Can Propose A New Time Or Withdraw A Pending Request.';

  /// Not available for artists in the API.
  Future<BookingReschedule> accept(BookingReschedule r) async => throw Exception(_customerOnly);

  /// Not available for artists in the API.
  Future<BookingReschedule> decline(BookingReschedule r) async => throw Exception(_customerOnly);

  /// Not available for artists in the API (propose a new time instead).
  Future<BookingReschedule> suggestAnother(BookingReschedule r, DateTime suggested, {String note = ''}) async =>
      throw Exception(_customerOnly);

  /// Withdraws the pending request.
  /// API: GET …/reschedule/get_all/ then PUT /artists/bookings/reschedule/cancel/
  Future<BookingReschedule> withdraw(BookingReschedule r) async {
    // The API cancels by reschedule_id, so look up the pending request for this booking first.
    final list = await ServiceLocator.artistBusiness.getReschedules(bookingId: r.bookingId, limit: 20);
    final pending = list.where((e) => e.isPending).toList();
    if (pending.isEmpty) throw Exception('There Is No Pending Reschedule Request For This Booking.');
    await ServiceLocator.artistBusiness.cancelReschedule(rescheduleId: pending.first.requestId);
    return r.copyWith(status: RescheduleStatus.withdrawn);
  }

  /// Nothing is stored on the device any more; the screen just reloads from the server.
  Future<void> clear(int bookingId) async {}

  /// Kept for older callers.
  Future<BookingReschedule> applyCustomerResponse(BookingReschedule r, {required bool accepted}) async =>
      r.copyWith(status: accepted ? RescheduleStatus.accepted : RescheduleStatus.declined);
}
