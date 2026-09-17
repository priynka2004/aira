import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/models.dart';
import '../models/booking/booking.dart';
import '../models/artist/package.dart';
import '../models/core/status_item.dart';
import '../models/core/location_type.dart';
import '../models/user/customer_address.dart';
import '../helper/booking_stats.dart';
import '../utils/service_locator.dart';
import '../widgets/journey_action_button.dart';
import 'chat_screen.dart';

/// Detail screen for a single booking. Fetches the full [Booking]
/// (GET /artists/bookings/get/) and the linked [Package]
/// (GET /artists/packages/get/) so the artist sees the real package
/// name/price/duration instead of just an ID.
///
/// [slot] is optional. When opened from [BookingScreen] it's passed in
/// (avoids a flash of "loading" for data the list screen already had).
/// When opened from a **booking notification** (tap on the bell, or a push
/// notification tray tap) there is no [BookingSlot] to hand over — only a
/// bookingId — so every value normally read from [slot] falls back to data
/// fetched here instead: client name via GET /users/profile/get/,
/// package/time/date/status straight from [Booking] itself. Either path
/// ends up showing the same screen.
///
/// Also listens live to `bookings/<bookingId>` in Firestore
/// ([FirestoreBookingService.bookingStream]) for as long as this screen is
/// open, so a status change made from elsewhere (the customer cancelling,
/// another device, a backend job) is reflected here immediately — e.g. the
/// Start/Mark complete/Cancel row disappearing the moment a booking is
/// cancelled — instead of only updating after this screen is closed and
/// [BookingScreen]'s own list listener catches up.
class BookingDetailScreen extends StatefulWidget {
  final int bookingId;
  final void Function(BookingSlot slot, SlotStatus next, {String? reason})? onUpdateStatus;
  final BookingSlot? slot;
  // statusId → SlotStatus lookup table, needed to interpret a live
  // Firestore update (which only carries a raw statusId). If empty (e.g.
  // this screen was opened straight from a notification, which has no
  // list screen to hand this down from), it's fetched here instead — see
  // [_load].
  final List<StatusItem> statuses;
  // Lets the journey flow tell whoever opened this screen to reload
  // bookings once a step actually changes the backend's statusId.
  final VoidCallback? onRefresh;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.slot,
    this.onUpdateStatus,
    this.statuses = const [],
    this.onRefresh,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _loading = true;
  String? _error;
  Booking? _booking;
  Package? _package;
  // Real display name for the customer, resolved via GET
  // /users/profile/get/ — only needed when [widget.slot] is null (a
  // notification deep-link); when a slot was handed in, it already has
  // the resolved name from wherever the list screen got it.
  String? _customerName;
  List<StatusItem> _statuses = const [];
  StreamSubscription<Booking?>? _liveSub;

  // Location + payment-status display — every lookup below is
  // best-effort: a failure here should never block the rest of the
  // booking detail from rendering, it just leaves that one row off.
  LocationType? _locationType;
  CustomerAddress? _address;
  List<StatusItem> _paymentStatuses = const [];

  @override
  void initState() {
    super.initState();
    _statuses = widget.statuses;
    _load();
    _listenLive();
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  void _listenLive() {
    _liveSub = ServiceLocator.firestoreBookingService
        .bookingStream(widget.bookingId)
        .listen(
          (booking) {
        if (!mounted || booking == null) return;
        setState(() => _booking = booking);
      },
      onError: (_) {
        // Best-effort — the screen still works from the REST load above,
        // it just won't get live updates for the rest of this session.
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await ServiceLocator.bookingService.getBooking(widget.bookingId);

      if (_statuses.isEmpty) {
        try {
          _statuses = await ServiceLocator.coreService.getBookingStatuses();
        } catch (_) {
          // Best-effort — status badge/buttons fall back to "open".
        }
      }

      Package? pkg;
      try {
        pkg = await ServiceLocator.artistService.getPackage(booking.packageId);
      } catch (_) {
        // Package lookup is best-effort — booking detail is still useful
        // without it (e.g. package was since deleted).
      }

      if (widget.slot == null) {
        // No list screen handed us the customer's real name — resolve it
        // ourselves, same best-effort lookup app_shell.dart does for the
        // list. Failure just leaves the "Customer #<id>" fallback below.
        unawaited(_loadCustomerName(booking.customerId));
      }

      LocationType? locationType;
      try {
        locationType = await ServiceLocator.coreService.getLocationType(booking.locationTypeId);
      } catch (_) {
        // Best-effort — falls back to showing nothing for location type.
      }

      // Best-effort, and expected to fail for many bookings today: this
      // endpoint (GET /users/address/get/) is written for a user reading
      // their *own* saved address, so it may 401/403 an artist reading a
      // customer's address depending on how the backend scopes it. See
      // the Booking Screen backend requirements doc — an
      // artist-permission-safe way to read the booking's address is one
      // of the asks there.
      CustomerAddress? address;
      final addressId = booking.addressId;
      if (addressId != null) {
        try {
          address = await ServiceLocator.userService.getAddress(addressId);
        } catch (_) {
          // Falls back to showing just the location type, no street
          // address.
        }
      }

      List<StatusItem> paymentStatuses = const [];
      if (booking.paymentStatusId != null) {
        try {
          paymentStatuses = await ServiceLocator.coreService.getPaymentStatuses();
        } catch (_) {
          // Falls back to not showing a payment-status row at all rather
          // than a wrong/blank one.
        }
      }

      if (!mounted) return;
      setState(() {
        _booking = booking;
        _package = pkg;
        _locationType = locationType;
        _address = address;
        _paymentStatuses = paymentStatuses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadCustomerName(int customerId) async {
    try {
      final profile = await ServiceLocator.userService.getProfile(customerId);
      if (!mounted || profile.name.trim().isEmpty) return;
      setState(() => _customerName = profile.name.trim());
    } catch (_) {
      // Best-effort — keeps the "Customer #<id>" fallback.
    }
  }

  SlotStatus get _effectiveStatus {
    final booking = _booking;
    if (booking != null) {
      return BookingStats.mapStatus(booking.statusId, _statuses, cancelledBy: booking.cancelledBy);
    }
    return widget.slot?.status ?? SlotStatus.open;
  }

  /// True once this booking's window has fully lapsed (see
  /// [BookingSlot.isMissed]) without ever reaching a terminal status —
  /// mirrors [BookingScreen]'s own check so both screens agree on when
  /// Accept/Reject/On My Way/etc. stop being offered.
  bool get _isMissed =>
      _slotForCallback.isMissed &&
      (_effectiveStatus == SlotStatus.pending ||
          _effectiveStatus == SlotStatus.confirmed ||
          _effectiveStatus == SlotStatus.inProgress);

  String get _clientName =>
      widget.slot?.client ?? _customerName ?? 'Customer #${_booking?.customerId ?? ''}';

  String get _packageLabel =>
      _package?.name ?? widget.slot?.service ?? 'Package #${_booking?.packageId ?? ''}';

  /// Same "Missed" / "Upcoming" overrides [BookingScreen] applies to the
  /// list badge — kept in sync so the detail screen never disagrees with
  /// the list about what a booking's status reads as.
  String get _statusRowLabel {
    if (_isMissed) return 'Missed';
    if (_effectiveStatus == SlotStatus.confirmed && _slotForCallback.isFutureDate) {
      return 'Upcoming';
    }
    return switch (_effectiveStatus) {
      SlotStatus.pending => 'New request',
      SlotStatus.confirmed => 'Confirmed',
      SlotStatus.inProgress => 'In progress',
      SlotStatus.completed => 'Completed',
      SlotStatus.cancelled => 'Cancelled',
      SlotStatus.noShow => 'No-show',
      _ => 'Open',
    };
  }

  /// Location-type name plus, when the address lookup succeeded, the
  /// actual street address — e.g. "At customer's home — 12 MG Road,
  /// Lucknow". Null when there's genuinely nothing to show yet (location
  /// type lookup itself failed).
  String? get _locationLabel {
    final typeName = _locationType?.name;
    if (typeName == null) return null;
    final addr = _address;
    if (addr == null) return typeName;
    final line2 = (addr.addressLine2?.trim().isNotEmpty ?? false) ? ', ${addr.addressLine2}' : '';
    return '$typeName — ${addr.addressLine1}$line2, ${addr.city} ${addr.pinCode}';
  }

  /// Null until the backend actually returns `paymentStatusId` on the
  /// booking (see the model doc comment) — deliberately never guessed
  /// from `statusId`, since payment and booking status are meant to be
  /// independent (a "completed" service doesn't imply "paid").
  String? get _paymentStatusLabel {
    final id = _booking?.paymentStatusId;
    if (id == null) return null;
    final match = _paymentStatuses.where((s) => s.statusId == id);
    if (match.isEmpty) return null;
    final name = match.first.name;
    return name.isEmpty ? null : name[0].toUpperCase() + name.substring(1);
  }

  String get _timeLabel {
    if (widget.slot != null) return widget.slot!.time;
    final booking = _booking;
    return booking != null ? _formatTime(booking.startTime) : '—';
  }

  /// Whatever the buttons below need to hand back to [widget.onUpdateStatus]
  /// — the real [widget.slot] when we have one, otherwise a stand-in built
  /// from [_booking] so the same Start/Mark complete/Cancel flow works
  /// identically from a notification deep-link.
  BookingSlot get _slotForCallback =>
      widget.slot ??
          BookingSlot(
            bookingId: widget.bookingId,
            date: _booking?.bookingDate ?? '',
            time: _timeLabel,
            rawStartTime: _booking?.startTime,
            client: _clientName,
            service: _packageLabel,
            status: _effectiveStatus,
            amount: _booking?.totalAmount,
          );

  String _formatTime(String startTime) {
    try {
      final parts = startTime.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? parts[1] : '00';
      final suffix = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$m $suffix';
    } catch (_) {
      return startTime;
    }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
        ),
        Expanded(
          child: Text(value, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

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
                  Expanded(child: Text('Booking details', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : _error != null
                  ? AiraErrorState(message: _error!, onRetry: _load)
                  : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  AiraCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Client', _clientName),
                        _row('Status', _statusRowLabel),
                        _row('Package', _packageLabel),
                        if (_package != null) _row('Duration', '${_package!.durationMinutes} min'),
                        _row('Date', _booking != null ? _formatDate(_booking!.bookingDate) : (widget.slot?.date ?? '—')),
                        _row('Time', _timeLabel),
                        if (_locationLabel != null) _row('Location', _locationLabel!),
                        _row('Amount', '₹${(_booking?.totalAmount ?? widget.slot?.amount ?? 0).toStringAsFixed(0)}'),
                        if (_paymentStatusLabel != null) _row('Payment', _paymentStatusLabel!),
                        if (_booking?.notes != null && _booking!.notes!.isNotEmpty)
                          _row('Notes', _booking!.notes!),
                        if (_booking?.cancellationReason != null)
                          _row('Cancellation reason', _booking!.cancellationReason!),
                      ],
                    ),
                  ),
                  // Backend only allows chat for confirmed/in-progress
                  // bookings (GET /chat/conversation/get/ 400s with "Chat is
                  // only available for confirmed or in-progress bookings"
                  // for anything else) — so a still-`pending` request can't
                  // show this button, only Accept/Reject below.
                  if (_effectiveStatus == SlotStatus.confirmed || _effectiveStatus == SlotStatus.inProgress) ...[
                    const SizedBox(height: 12),
                    GhostButton(
                      label: 'Message $_clientName',
                      icon: Icons.chat_bubble_outline,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            bookingId: widget.bookingId,
                            title: _clientName,
                          ),
                        ));
                      },
                    ),
                  ],
                  if (widget.onUpdateStatus != null &&
                      !_isMissed &&
                      (_effectiveStatus == SlotStatus.pending ||
                          _effectiveStatus == SlotStatus.confirmed ||
                          _effectiveStatus == SlotStatus.inProgress)) ...[
                    const SizedBox(height: 16),
                    if (_effectiveStatus == SlotStatus.pending)
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Accept',
                              onTap: () {
                                widget.onUpdateStatus!(_slotForCallback, SlotStatus.confirmed);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GhostButton(
                              label: 'Reject',
                              color: AiraColors.errorText,
                              onTap: () async {
                                final reason = await showAiraCancelReasonDialog(
                                  context,
                                  clientName: _clientName,
                                  isReject: true,
                                );
                                if (reason == null) return; // artist backed out
                                widget.onUpdateStatus!(_slotForCallback, SlotStatus.cancelled, reason: reason);
                                if (context.mounted) Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          // Dynamic button driven by the booking's own
                          // live state — see widgets/journey_action_button.dart.
                          // Routes into the real On My Way → Confirm
                          // Arrival → Start Service → Enter Completion
                          // Code flow instead of completing the booking
                          // directly from here.
                          Expanded(
                            child: JourneyActionButton(
                              slot: _slotForCallback,
                              statuses: _statuses,
                              onUpdateStatus: widget.onUpdateStatus!,
                              onRefresh: widget.onRefresh,
                              small: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GhostButton(
                              label: 'Cancel booking',
                              color: AiraColors.errorText,
                              onTap: () async {
                                final reason = await showAiraCancelReasonDialog(
                                  context,
                                  clientName: _clientName,
                                );
                                if (reason == null) return; // artist backed out
                                widget.onUpdateStatus!(_slotForCallback, SlotStatus.cancelled, reason: reason);
                                if (context.mounted) Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
