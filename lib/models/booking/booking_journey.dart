// FILE: models/booking/booking_journey.dart  |  MODEL
// Journey stage of a booking (on my way, arrived, in progress...).

import '../models.dart';
import 'booking.dart';

/// Enum: Journey Stage values.
enum JourneyStage {
  upcoming,
  onTheWay,
  arrived,
  inProgress,
  completed,
  missed;
  static JourneyStage fromBooking(Booking booking, SlotStatus status) {
    if (status == SlotStatus.completed) return JourneyStage.completed;
    if (status == SlotStatus.inProgress) return JourneyStage.inProgress;
    if (booking.arrivedAt != null && booking.arrivedAt!.isNotEmpty) {
      return JourneyStage.arrived;
    }
    if (booking.onMyWayAt != null && booking.onMyWayAt!.isNotEmpty) {
      return JourneyStage.onTheWay;
    }
    if (booking.hasStartTimePassed) return JourneyStage.missed;
    return JourneyStage.upcoming;
  }
}

/// Model: Booking Journey.
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