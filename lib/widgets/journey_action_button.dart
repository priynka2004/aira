import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/models.dart';
import '../models/booking/booking.dart';
import '../models/booking/booking_journey.dart';
import '../models/core/status_item.dart';
import '../helper/booking_stats.dart';
import '../utils/service_locator.dart';
import '../screens/journey_screen.dart';
import 'common.dart';

/// The dynamic "what does the artist do next" button for the real
/// booking lifecycle (see the Booking Lifecycle Field Guide):
///
///   Upcoming (2h before) → On My Way → Confirm Arrival →
///   Start Service (enter customer's PIN) → Enter Completion Code →
///   Completed + Review
///
/// Fetches the live [Booking] and derives [JourneyStage] straight from
/// it (see `booking_journey.dart`) — there's no local/cached stage
/// anymore, so this always reflects the backend's real state. Routes
/// into [JourneyScreen] for every stage past "Upcoming"; that screen owns
/// the actual OTP/PIN entry, location-sharing, and completion logic.
class JourneyActionButton extends StatefulWidget {
  final BookingSlot slot;
  final List<StatusItem> statuses;
  final void Function(BookingSlot slot, SlotStatus next, {String? reason}) onUpdateStatus;
  final VoidCallback? onRefresh;
  final bool small;

  const JourneyActionButton({
    super.key,
    required this.slot,
    required this.statuses,
    required this.onUpdateStatus,
    this.onRefresh,
    this.small = true,
  });

  @override
  State<JourneyActionButton> createState() => _JourneyActionButtonState();
}

class _JourneyActionButtonState extends State<JourneyActionButton> {
  late Future<Booking> _future;

  @override
  void initState() {
    super.initState();
    _future = ServiceLocator.bookingJourneyService.getBooking(widget.slot.bookingId!);
  }

  @override
  void didUpdateWidget(covariant JourneyActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.bookingId != widget.slot.bookingId) {
      _future = ServiceLocator.bookingJourneyService.getBooking(widget.slot.bookingId!);
    }
  }

  void _refetch() {
    if (mounted) {
      setState(() {
        _future = ServiceLocator.bookingJourneyService.getBooking(widget.slot.bookingId!);
      });
    }
  }

  void _open(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => JourneyScreen(
            slot: widget.slot,
            statuses: widget.statuses,
            onUpdateStatus: widget.onUpdateStatus,
            onRefresh: widget.onRefresh,
          ),
        ))
        .then((_) {
      // Refresh after returning, in case the stage moved on inside the
      // journey screen.
      _refetch();
    });
  }

  ({String label, bool enabled}) _labelFor(JourneyStage stage) {
    final slot = widget.slot;
    switch (stage) {
      case JourneyStage.upcoming:
        if (slot.isWithinUpcomingWindow) {
          return (label: 'On My Way', enabled: true);
        }
        return (label: 'Upcoming', enabled: false);
      case JourneyStage.missed:
        // Never marked on the way before the appointment's start time —
        // the deadline is gone. Not tappable; Cancel (rendered alongside
        // this button by the caller) is the only remaining action.
        return (label: 'Missed', enabled: false);
      case JourneyStage.onTheWay:
        return (label: 'Confirm Arrival', enabled: true);
      case JourneyStage.arrived:
        return (label: 'Start Service', enabled: true);
      case JourneyStage.inProgress:
        return (label: 'Enter Completion Code', enabled: true);
      case JourneyStage.completed:
        return (label: 'Completed', enabled: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slot.bookingId == null) {
      return GhostButton(label: 'Upcoming', small: widget.small, color: AiraColors.charcoalSoft, onTap: null);
    }
    return FutureBuilder<Booking>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return GhostButton(label: 'Upcoming', small: widget.small, color: AiraColors.charcoalSoft, onTap: null);
        }
        final stage = JourneyStage.fromBooking(
          snapshot.data!,
          BookingStats.mapStatus(snapshot.data!.statusId, widget.statuses, cancelledBy: snapshot.data!.cancelledBy),
        );
        // A booking the backend has actually cancelled (cancelledBy set)
        // should never offer an action button, even if statusId itself
        // hasn't caught up to "cancelled" yet (see mapStatus doc).
        if (snapshot.data!.cancelledBy != null && snapshot.data!.cancelledBy!.isNotEmpty) {
          return GhostButton(label: 'Cancelled', small: widget.small, color: AiraColors.charcoalSoft, onTap: null);
        }
        final info = _labelFor(stage);
        if (!info.enabled) {
          return GhostButton(label: info.label, small: widget.small, color: AiraColors.charcoalSoft, onTap: null);
        }
        return PrimaryButton(label: info.label, small: widget.small, onTap: () => _open(context));
      },
    );
  }
}
