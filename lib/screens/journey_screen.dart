import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/models.dart';
import '../models/booking/booking.dart';
import '../models/booking/booking_journey.dart';
import '../models/core/status_item.dart';
import '../helper/booking_stats.dart';
import '../utils/service_locator.dart';
import '../utils/app_feedback.dart';
import '../utils/geo_utils.dart';
import '../utils/address_geocoder.dart' as geocoder;
import '../api/booking_tracking_socket.dart';
import '../api/booking_journey_service.dart' show JourneyReasonError;
import '../services/firestore_location_service.dart';
import '../utils/app_session.dart';
import 'review_customer_screen.dart';

/// Full-screen version of the real booking lifecycle, wired straight to
/// the live backend (see the Booking Lifecycle Field Guide):
///
///   On My Way → Enter Booking OTP (arrival) → Enter Start Service PIN →
///   (in progress) → Enter Completion PIN → Review
///
/// Every step here is a direct call to the artist-side endpoint that
/// owns it; the screen never generates or stores a credential itself —
/// it only ever *enters* what the customer reads out loud (Start Service
/// PIN, Completion PIN) or what the artist's own notification gave them
/// at booking time (Booking OTP). This is the only place `completed` gets
/// set — the booking list and detail screen route here instead of
/// exposing a direct "Mark complete".
class JourneyScreen extends StatefulWidget {
  final BookingSlot slot;
  final List<StatusItem> statuses;
  final void Function(BookingSlot slot, SlotStatus next, {String? reason}) onUpdateStatus;
  final VoidCallback? onRefresh;

  const JourneyScreen({
    super.key,
    required this.slot,
    required this.statuses,
    required this.onUpdateStatus,
    this.onRefresh,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  Booking? _booking;
  bool _loading = true;
  bool _busy = false;

  final _otpController = TextEditingController(); // 6-digit Booking OTP
  final _pinController = TextEditingController(); // 4-digit start/completion PIN

  final _tracking = BookingTrackingSocket();
  final _firestoreLocation = FirestoreLocationService();
  StreamSubscription<Position>? _positionSub;

  // The artist's own live position, kept locally too (not just sent to
  // the socket) so we can compute a live distance-to-customer figure.
  double? _myLat;
  double? _myLng;

  // The customer's booking address, geocoded ONCE (an address is a fixed
  // point — it doesn't move) and cached per booking. Never refetched on
  // every frame; only the artist's side of the distance is live.
  geocoder.LatLng? _customerLatLng;
  int? _geocodedForAddressId;

  Timer? _lockTicker;
  Duration? _lockRemaining;
  String? _lockedStageKey;

  int get _bookingId => widget.slot.bookingId!;

  JourneyStage get _stage {
    final b = _booking;
    if (b == null) return JourneyStage.upcoming;
    return JourneyStage.fromBooking(b, BookingStats.mapStatus(b.statusId, widget.statuses, cancelledBy: b.cancelledBy));
  }

  /// The key [BookingJourneyService]'s lockout tracking uses for the
  /// credential relevant to the current stage.
  String? get _stageCredentialKey => switch (_stage) {
        JourneyStage.onTheWay => 'arrive',
        JourneyStage.arrived => 'start',
        JourneyStage.inProgress => 'complete',
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    _positionSub?.cancel();
    _tracking.close();
    _otpController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final booking = await ServiceLocator.bookingJourneyService.getBooking(_bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
      _afterBookingChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppFeedback.showError(context, e, onRetry: _load);
    }
  }

  /// Re-checks location sharing + lockout state for whatever stage the
  /// booking is now in — called after every load/refresh.
  void _afterBookingChanged() {
    if (_stage == JourneyStage.onTheWay || _stage == JourneyStage.arrived) {
      _startLocationSharing();
      _loadCustomerLocation();
    } else {
      _stopLocationSharing();
    }
    _checkLockout();
  }

  /// Geocodes the customer's booking address once (cached by addressId)
  /// so the distance card has a fixed point to measure the artist's live
  /// position against. Silent on failure — the UI just falls back to
  /// not showing a distance if the address can't be resolved.
  Future<void> _loadCustomerLocation() async {
    final booking = _booking;
    final addressId = booking?.addressId;
    if (booking == null || addressId == null) return;
    if (_geocodedForAddressId == addressId && _customerLatLng != null) return;
    try {
      final address = await ServiceLocator.userService.getAddress(addressId);
      final query = [address.addressLine1, address.city, address.pinCode]
          .where((s) => s.isNotEmpty)
          .join(', ');
      final latLng = await geocoder.AddressGeocoder.geocode(query);
      if (!mounted) return;
      setState(() {
        _customerLatLng = latLng;
        _geocodedForAddressId = addressId;
      });
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }

  void _startLocationSharing() {
    final token = AppSession.instance.accessToken;
    if (token != null) _tracking.connect(_bookingId, token);
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
    ).listen(
      (pos) {
        _tracking.sendLocation(pos.latitude, pos.longitude);
        // Also push to Firestore — this is what actually reaches the
        // customer app today, since the custom backend's socket isn't
        // live yet. Both writes are cheap best-effort calls, so keeping
        // both means nothing has to change here once the backend socket
        // does go live.
        _firestoreLocation.pushLocation(_bookingId, pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _myLat = pos.latitude;
            _myLng = pos.longitude;
          });
        }
      },
      onError: (_) {
        // Best-effort — missing location permission shouldn't block the
        // rest of the journey flow, just the live-tracking dot on the
        // customer's map.
      },
    );
  }

  void _stopLocationSharing() {
    _positionSub?.cancel();
    _positionSub = null;
    _tracking.close();
    _firestoreLocation.stopSharing(_bookingId);
  }

  /// Live distance between the artist's current GPS position and the
  /// customer's (fixed) booking address — null until both sides are
  /// known, and recalculated on every artist position update.
  double? get _liveDistanceKm {
    final customer = _customerLatLng;
    if (_myLat == null || _myLng == null || customer == null) return null;
    return distanceKm(lat1: _myLat!, lng1: _myLng!, lat2: customer.lat, lng2: customer.lng);
  }

  // ── Lockout countdown ────────────────────────────────────────────────

  Future<void> _checkLockout() async {
    final key = _stageCredentialKey;
    _lockTicker?.cancel();
    if (key == null) {
      if (mounted) setState(() { _lockRemaining = null; _lockedStageKey = null; });
      return;
    }
    final remaining = await ServiceLocator.bookingJourneyService.lockoutRemaining(_bookingId, key);
    if (!mounted) return;
    setState(() { _lockRemaining = remaining; _lockedStageKey = key; });
    if (remaining != null) {
      _lockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
        final left = _lockRemaining;
        if (left == null || left.inSeconds <= 1) {
          t.cancel();
          if (mounted) setState(() => _lockRemaining = null);
          return;
        }
        if (mounted) setState(() => _lockRemaining = left - const Duration(seconds: 1));
      });
    }
  }

  bool get _isLocked => _lockRemaining != null && _lockedStageKey == _stageCredentialKey;

  String _formatLock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Reason → friendly message (per the field guide's per-endpoint tables) ──

  String _friendlyReason(String reason) {
    switch (reason) {
      case 'on_my_way_too_early':
        return 'Not yet — come back closer to the appointment.';
      case 'on_my_way_not_allowed':
      case 'arrived_not_allowed':
      case 'start_pin_verify_not_allowed':
      case 'completion_pin_verify_not_allowed':
        return "This booking's status changed — refreshing.";
      case 'booking_not_found':
        return "Couldn't find this booking — refreshing.";
      case 'otp_invalid':
        return "That code doesn't match — check the notification you were sent.";
      case 'start_pin_invalid':
      case 'completion_pin_invalid':
        return "That code doesn't match — ask the customer to double check it.";
      case 'account_locked':
        return 'Too many wrong attempts. Locked for a while — try again later.';
      default:
        // Not one of the documented snake_case reason codes — the
        // backend sometimes returns a plain, already-readable sentence
        // instead (as seen with the on-my-way window rule). Only swap
        // *that* out for a generic message if it actually looks like a
        // raw technical/server-crash string; otherwise it's meant to be
        // read, so show it as-is.
        return AppFeedback.friendlyMessage(reason);
    }
  }

  bool _reasonMeansStateChanged(String reason) =>
      reason.endsWith('_not_allowed') || reason.endsWith('_not_found');

  Future<void> _handleJourneyError(Object e) async {
    if (e is JourneyReasonError) {
      AppFeedback.showWarning(context, _friendlyReason(e.reason));
      if (e.reason == 'account_locked') {
        await _checkLockout();
      } else if (_reasonMeansStateChanged(e.reason)) {
        await _load();
      }
      return;
    }
    AppFeedback.showError(context, e);
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _submitOnMyWay() async {
    setState(() => _busy = true);
    try {
      final booking = await ServiceLocator.bookingJourneyService.markOnMyWay(_bookingId);
      if (!mounted) return;
      setState(() => _booking = booking);
      _afterBookingChanged();
      widget.onRefresh?.call();
    } catch (e) {
      await _handleJourneyError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitArrival() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      AppFeedback.showWarning(context, 'Enter the 6-digit code from your notification');
      return;
    }
    setState(() => _busy = true);
    try {
      final booking = await ServiceLocator.bookingJourneyService.confirmArrival(_bookingId, otp);
      if (!mounted) return;
      _otpController.clear();
      setState(() => _booking = booking);
      _afterBookingChanged();
      widget.onRefresh?.call();
    } catch (e) {
      await _handleJourneyError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitStartPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      AppFeedback.showWarning(context, 'Enter the 4-digit code the customer gave you');
      return;
    }
    setState(() => _busy = true);
    try {
      final booking = await ServiceLocator.bookingJourneyService.verifyStartPin(_bookingId, pin);
      if (!mounted) return;
      _pinController.clear();
      setState(() => _booking = booking);
      _afterBookingChanged();
      widget.onRefresh?.call();
      AppFeedback.showSuccess(context, 'Service started!');
    } catch (e) {
      await _handleJourneyError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitCompletionPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      AppFeedback.showWarning(context, 'Enter the 4-digit code the customer gave you');
      return;
    }
    setState(() => _busy = true);
    try {
      final booking = await ServiceLocator.bookingJourneyService.verifyCompletionPin(_bookingId, pin);
      if (!mounted) return;
      _pinController.clear();
      setState(() => _booking = booking);
      _afterBookingChanged();
      widget.onRefresh?.call();
      AppFeedback.showSuccess(context, 'Booking completed!');
    } catch (e) {
      await _handleJourneyError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitCancel() async {
    final reason = await showAiraCancelReasonDialog(context, clientName: widget.slot.client);
    if (reason == null) return; // artist backed out
    widget.onUpdateStatus(widget.slot, SlotStatus.cancelled, reason: reason);
    widget.onRefresh?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Service journey', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading || _booking == null
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        children: [
                          AiraCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.slot.client, style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('${widget.slot.service} · ${widget.slot.time}',
                                    style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _stepper(_stage),
                          const SizedBox(height: 24),
                          ..._stageContent(_stage),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(JourneyStage stage) {
    const labels = ['On the way', 'Arrived', 'Service started', 'Complete'];
    final activeIndex = switch (stage) {
      JourneyStage.upcoming => -1,
      JourneyStage.missed => -1,
      JourneyStage.onTheWay => 0,
      JourneyStage.arrived => 1,
      JourneyStage.inProgress => 2,
      JourneyStage.completed => 3,
    };
    return Row(
      children: List.generate(labels.length, (i) {
        final done = i <= activeIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(height: 2, color: i - 1 < activeIndex ? AiraColors.rose : AiraColors.hair),
                    ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AiraColors.rose : AiraColors.hair,
                    ),
                  ),
                  if (i < labels.length - 1)
                    Expanded(
                      child: Container(height: 2, color: i < activeIndex ? AiraColors.rose : AiraColors.hair),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(labels[i],
                  textAlign: TextAlign.center,
                  style: AiraText.sans(fontSize: 10.5, color: done ? AiraColors.charcoal : AiraColors.charcoalSoft)),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _stageContent(JourneyStage stage) {
    switch (stage) {
      case JourneyStage.upcoming:
        final within = widget.slot.isWithinUpcomingWindow;
        return [
          _infoCard(
            icon: Icons.directions_walk,
            title: 'Ready when you are',
            body: within
                ? 'Once you\'re about to head out, tap below to start sharing your live location with the customer.'
                : 'You can mark yourself on the way starting 2 hours before the appointment.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'On My Way',
            expand: true,
            onTap: _busy ? null : _submitOnMyWay,
          ),
        ];

      case JourneyStage.missed:
        return [
          _infoCard(
            icon: Icons.event_busy_outlined,
            title: 'Booking missed',
            body: 'The scheduled time has passed and this was never marked "On My Way". '
                'It can no longer be started — cancel it to close it out.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Cancel Booking',
            expand: true,
            background: AiraColors.errorText,
            onTap: _busy ? null : _submitCancel,
          ),
        ];

      case JourneyStage.onTheWay:
        return [
          _infoCard(
            icon: Icons.navigation_outlined,
            title: 'On the way',
            body: _liveDistanceKm != null
                ? 'Your live location is being shared with the customer — ${formatDistanceKm(_liveDistanceKm!)} to their address.'
                : 'Your live location is being shared with the customer.',
          ),
          const SizedBox(height: 20),
          _codeEntryCard(
            title: 'Enter your arrival code',
            subtitle: 'Use the 6-digit code that was sent to you (notification/SMS) when this booking was confirmed.',
            controller: _otpController,
            length: 6,
            buttonLabel: 'Confirm Arrival',
            onSubmit: _submitArrival,
          ),
        ];

      case JourneyStage.arrived:
        return [
          _infoCard(
            icon: Icons.hourglass_bottom,
            title: 'Arrived',
            body: 'The customer has a 4-digit code on their screen — ask them to read it out to start the service.',
          ),
          const SizedBox(height: 20),
          _codeEntryCard(
            title: 'Enter the customer\'s code',
            subtitle: 'They\'ll read this out loud from their app.',
            controller: _pinController,
            length: 4,
            buttonLabel: 'Start Service',
            onSubmit: _submitStartPin,
          ),
        ];

      case JourneyStage.inProgress:
        return [
          _infoCard(
            icon: Icons.content_cut,
            title: 'Service in progress',
            body: 'Once you\'ve finished, ask the customer for their completion code and enter it below.',
          ),
          const SizedBox(height: 20),
          _codeEntryCard(
            title: 'Enter the completion code',
            subtitle: 'The customer\'s app is already showing them this 4-digit code.',
            controller: _pinController,
            length: 4,
            buttonLabel: 'Mark Complete',
            onSubmit: _submitCompletionPin,
          ),
        ];

      case JourneyStage.completed:
        return [
          _infoCard(
            icon: Icons.check_circle_outline,
            title: 'Booking completed',
            body: 'Nicely done. Leave a quick review for the customer while it\'s fresh.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Review Customer',
            expand: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReviewCustomerScreen(bookingId: _bookingId, customerName: widget.slot.client),
            )),
          ),
        ];
    }
  }

  Widget _codeEntryCard({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required int length,
    required String buttonLabel,
    required VoidCallback onSubmit,
  }) {
    final locked = _isLocked;
    return AiraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(title, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitle, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (locked) ...[
            Icon(Icons.lock_clock_outlined, color: AiraColors.charcoalSoft, size: 28),
            const SizedBox(height: 8),
            Text(
              'Locked — try again in ${_formatLock(_lockRemaining!)}',
              style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Too many wrong attempts on this code.',
              style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(length)],
              maxLength: length,
              textAlign: TextAlign.center,
              style: AiraText.serif(fontSize: 24, fontWeight: FontWeight.w600).copyWith(letterSpacing: 6),
              decoration: InputDecoration(
                counterText: '',
                hintText: '•' * length,
                filled: true,
                fillColor: AiraColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AiraColors.hair)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AiraColors.hair)),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: buttonLabel, expand: true, onTap: _busy ? null : onSubmit),
          ],
        ],
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body}) {
    return AiraCard(
      padding: const EdgeInsets.all(16),
      borderColor: AiraColors.goldSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AiraColors.goldSoft, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 18, color: AiraColors.roseDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
