import '../models.dart';
import 'booking.dart';

/// Client-side view of where a booking sits in the real backend lifecycle
/// (see the Booking Lifecycle Field Guide). Every value here is *derived*
/// from the live [Booking] record (`statusId` + the two sub-stage
/// timestamps that matter on the artist's side) — nothing is generated
/// or stored locally; the backend is the only source of truth for PINs.
///
///   upcoming → onTheWay → arrived → inProgress → completed
///
/// (`cancelled` / `noShow` are handled separately via [SlotStatus], since
/// they can happen from almost any stage — see the field guide's "escape
/// hatches".)
enum JourneyStage {
  /// `confirmed`; hasn't marked "on the way" yet.
  upcoming,

  /// `confirmed`, `onMyWayAt` set. Next action: enter the Booking OTP on
  /// arrival.
  onTheWay,

  /// `confirmed`, `arrivedAt` set. The Start Service PIN has already been
  /// minted for the customer — next action: ask them for it and enter it.
  arrived,

  /// `statusId` resolves to `in_progress`. The Completion PIN has already
  /// been minted for the customer — next action: ask them for it and
  /// enter it once the service is actually done.
  inProgress,

  /// `statusId` resolves to `completed`. End state.
  completed,

  /// Still `confirmed`/`pending` — never marked "on the way" — and the
  /// appointment's scheduled start time has already passed. Terminal for
  /// this screen's purposes: the only remaining action is Cancel (see
  /// [BookingScreen] and [BookingDetailScreen] — never Accept/On My Way/
  /// etc, since that window is gone). Distinct from the backend's
  /// `no_show`/`cancelled` statuses, which are handled via [SlotStatus] —
  /// this is a client-derived "the deadline passed and nothing happened"
  /// state layered on top of whatever `statusId` still says, since the
  /// backend doesn't yet auto-expire bookings on its own (see the Booking
  /// Screen backend requirements doc).
  missed;

  /// Derives the stage purely from the booking's own fields. [status] is
  /// the already-resolved [SlotStatus] (via [BookingStats.mapStatus]) —
  /// the screen already has [statuses] on hand for this from the booking
  /// list, so there's no extra lookup needed here.
  static JourneyStage fromBooking(Booking booking, SlotStatus status) {
    if (status == SlotStatus.completed) return JourneyStage.completed;
    if (status == SlotStatus.inProgress) return JourneyStage.inProgress;
    // Still "confirmed" (or an unrecognised status, which we treat as
    // confirmed rather than guessing) — check the sub-stage timestamps,
    // arrivedAt first, per the field guide.
    if (booking.arrivedAt != null && booking.arrivedAt!.isNotEmpty) {
      return JourneyStage.arrived;
    }
    if (booking.onMyWayAt != null && booking.onMyWayAt!.isNotEmpty) {
      return JourneyStage.onTheWay;
    }
    // Never marked on the way, and the appointment's start time (plus the
    // same 2h grace window the Customer app uses — see
    // `Booking.hasStartTimePassed`) has already come and gone — the
    // on-my-way deadline was missed.
    if (booking.hasStartTimePassed) return JourneyStage.missed;
    return JourneyStage.upcoming;
  }
}

/// Everything the journey screen needs for the current booking: the
/// derived [stage] plus the underlying [booking] record it was derived
/// from (so the screen can read `bookingDate`/`startTime` for the on-my-
/// way window, `totalAmount`, etc. without a second fetch).
class BookingJourney {
  final int bookingId;
  final JourneyStage stage;
  final Booking booking;

  const BookingJourney({
    required this.bookingId,
    required this.stage,
    required this.booking,
  });
}
