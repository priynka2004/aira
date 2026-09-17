import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/core/status_item.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/journey_action_button.dart';
import 'booking_detail_screen.dart';

class BookingScreen extends StatefulWidget {
  final List<BookingSlot> slots;
  final bool loading;
  final void Function(BookingSlot slot, SlotStatus next, {String? reason})? onUpdateStatus;
  // Passed straight through to [BookingDetailScreen] so it can map a live
  // Firestore statusId update onto the same [SlotStatus] this list uses —
  // without it, the detail screen has no way to interpret a raw statusId
  // it hasn't fetched itself.
  final List<StatusItem> statuses;
  // Lets the journey flow (on-my-way/arrived/PIN verification) tell the
  // parent to reload bookings once a step actually changes the backend's
  // statusId — otherwise the list here would keep showing a stale status
  // until the next unrelated refresh.
  final VoidCallback? onRefresh;

  const BookingScreen({
    super.key,
    required this.slots,
    this.loading = false,
    this.onUpdateStatus,
    this.statuses = const [],
    this.onRefresh,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _selectedDate;

  /// When set, the screen switches from the single-day week-pill view to a
  /// grouped list of every booking between these two dates (inclusive) —
  /// this is how older bookings, outside the current week, get seen.
  DateTimeRange? _customRange;

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  /// Today through the next 29 days (30 days total) — the schedule window
  /// the business/artist screen should default to, per the Booking Status
  /// rules: today's date is selected on open (see [initState]) and the
  /// strip itself never reaches into the past. Older bookings are still
  /// reachable, but only via the explicit date-range picker
  /// ([AiraDateRangeButton]/[_pickRange]) — they never show here by
  /// default.
  List<DateTime> get _next30Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(30, (i) => today.add(Duration(days: i)));
  }

  List<BookingSlot> get _slotsForSelectedDay {
    final iso = _isoDate(_selectedDate);
    final list = widget.slots.where((s) => s.date == iso).toList();
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  /// Every booking that falls inside [_customRange], grouped by ISO date
  /// (ascending), each day's slots sorted by time.
  List<MapEntry<String, List<BookingSlot>>> get _slotsGroupedForRange {
    final range = _customRange;
    if (range == null) return const [];
    final startIso = _isoDate(range.start);
    final endIso = _isoDate(range.end);
    final inRange = widget.slots.where((s) => s.date.compareTo(startIso) >= 0 && s.date.compareTo(endIso) <= 0).toList();
    final byDate = <String, List<BookingSlot>>{};
    for (final s in inRange) {
      byDate.putIfAbsent(s.date, () => []).add(s);
    }
    for (final list in byDate.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    final entries = byDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  /// Real, data-derived clashes for the selected day — pairs of active
  /// bookings that share the exact same start time.
  List<String> get _clashDescriptions {
    final active = _slotsForSelectedDay
        .where((s) => s.status != SlotStatus.cancelled && s.status != SlotStatus.noShow && s.status != SlotStatus.completed)
        .toList();
    final byTime = <String, List<BookingSlot>>{};
    for (final s in active) {
      byTime.putIfAbsent(s.time, () => []).add(s);
    }
    final out = <String>[];
    for (final entry in byTime.entries) {
      if (entry.value.length > 1) {
        final who = entry.value.map((s) => s.client).join(' & ');
        out.add('$who overlap at ${entry.key}');
      }
    }
    return out;
  }

  Future<void> _pickRange() async {
    final picked = await pickAiraDateRange(context, initialRange: _customRange);
    if (picked == null) return;
    setState(() => _customRange = picked);
  }

  String _dateHeaderLabel(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  Color _statusBg(SlotStatus s) => switch (s) {
    SlotStatus.pending => AiraColors.goldSoft,
    SlotStatus.confirmed => const Color(0xFFEAF3EC),
    SlotStatus.completed => const Color(0xFFEAF3EC),
    SlotStatus.inProgress => AiraColors.goldSoft,
    SlotStatus.open => AiraColors.bg,
    SlotStatus.clash => AiraColors.errorBg,
    SlotStatus.cancelled => AiraColors.errorBg,
    SlotStatus.noShow => AiraColors.errorBg,
  };
  Color _statusText(SlotStatus s) => switch (s) {
    SlotStatus.pending => AiraColors.warn,
    SlotStatus.confirmed => AiraColors.success,
    SlotStatus.completed => AiraColors.success,
    SlotStatus.inProgress => AiraColors.warn,
    SlotStatus.open => AiraColors.charcoalSoft,
    SlotStatus.clash => AiraColors.errorText,
    SlotStatus.cancelled => AiraColors.errorText,
    SlotStatus.noShow => AiraColors.errorText,
  };
  String _statusLabel(SlotStatus s) => switch (s) {
    SlotStatus.pending => 'New request',
    SlotStatus.confirmed => 'Confirmed',
    SlotStatus.completed => 'Completed',
    SlotStatus.inProgress => 'In progress',
    SlotStatus.open => 'Open',
    SlotStatus.clash => 'Clash',
    SlotStatus.cancelled => 'Cancelled',
    SlotStatus.noShow => 'No-show',
  };

  /// A slot whose window has fully lapsed (see [BookingSlot.isMissed])
  /// without ever reaching a terminal status reads as "Missed" — this
  /// overrides every other label/color below it for pending/confirmed/
  /// in-progress slots, since the booking date+time (not the stale
  /// backend statusId) is the source of truth for whether it's still
  /// live. A `confirmed` slot that hasn't lapsed yet and is on a future
  /// date reads as "Upcoming" — matches the action button below it, which
  /// is "Upcoming" (disabled) until the booking day arrives.
  bool _isMissed(BookingSlot s) =>
      s.isMissed &&
      (s.status == SlotStatus.pending ||
          s.status == SlotStatus.confirmed ||
          s.status == SlotStatus.inProgress);

  String _displayStatusLabel(BookingSlot s) {
    if (_isMissed(s)) return 'Missed';
    if (s.status == SlotStatus.confirmed && s.isFutureDate) return 'Upcoming';
    return _statusLabel(s.status);
  }

  Color _displayStatusBg(BookingSlot s) =>
      _isMissed(s) ? AiraColors.errorBg : _statusBg(s.status);
  Color _displayStatusText(BookingSlot s) =>
      _isMissed(s) ? AiraColors.errorText : _statusText(s.status);

  Widget _slotTile(BookingSlot s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text(s.time, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
            ),
          ),
          Expanded(
            child: AiraCard(
              padding: const EdgeInsets.all(13),
              borderColor: s.status == SlotStatus.clash ? const Color(0xFFF0C3B7) : AiraColors.hair,
              onTap: s.bookingId == null
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BookingDetailScreen(
                  bookingId: s.bookingId!,
                  slot: s,
                  onUpdateStatus: widget.onUpdateStatus,
                  statuses: widget.statuses,
                  onRefresh: widget.onRefresh,
                ),
              )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.client == '—' ? s.service : s.client,
                                style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            if (s.client != '—')
                              Text(s.service, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                            if (s.amount != null)
                              Text('₹${s.amount!.toStringAsFixed(0)}',
                                  style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _displayStatusBg(s), borderRadius: BorderRadius.circular(999)),
                        child: Text(_displayStatusLabel(s),
                            style: AiraText.sans(fontSize: 10.5, fontWeight: FontWeight.w600, color: _displayStatusText(s))),
                      ),
                    ],
                  ),
                  // A missed slot never offers Accept/Reject/On My Way/etc
                  // — its window is gone. The only remaining action is
                  // Cancel, so it needs to stay reachable here rather than
                  // disappearing along with the rest of the row.
                  if (widget.onUpdateStatus != null &&
                      s.bookingId != null &&
                      (s.status == SlotStatus.pending ||
                          s.status == SlotStatus.confirmed ||
                          s.status == SlotStatus.inProgress)) ...[
                    const SizedBox(height: 10),
                    if (_isMissed(s))
                      Row(
                        children: [
                          GhostButton(
                            label: 'Cancel',
                            small: true,
                            color: AiraColors.errorText,
                            onTap: () async {
                              final reason = await showAiraCancelReasonDialog(context, clientName: s.client);
                              if (reason == null) return; // artist backed out
                              widget.onUpdateStatus!(s, SlotStatus.cancelled, reason: reason);
                            },
                          ),
                        ],
                      )
                    else if (s.status == SlotStatus.pending)
                      Row(
                        children: [
                          PrimaryButton(
                            label: 'Accept',
                            small: true,
                            onTap: () => widget.onUpdateStatus!(s, SlotStatus.confirmed),
                          ),
                          const SizedBox(width: 8),
                          GhostButton(
                            label: 'Reject',
                            small: true,
                            color: AiraColors.errorText,
                            onTap: () async {
                              final reason = await showAiraCancelReasonDialog(context, clientName: s.client, isReject: true);
                              if (reason == null) return; // artist backed out
                              widget.onUpdateStatus!(s, SlotStatus.cancelled, reason: reason);
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          // Dynamic button driven by the booking's own
                          // live state: Upcoming → On My Way → Confirm
                          // Arrival → Start Service (enter customer's
                          // PIN) → Enter Completion Code → Completed. See
                          // widgets/journey_action_button.dart — "Mark
                          // complete" is no longer directly reachable from
                          // here, it only happens at the end of that flow.
                          JourneyActionButton(
                            slot: s,
                            statuses: widget.statuses,
                            onUpdateStatus: widget.onUpdateStatus!,
                            onRefresh: widget.onRefresh,
                          ),
                          const SizedBox(width: 8),
                          GhostButton(
                            label: 'Cancel',
                            small: true,
                            color: AiraColors.errorText,
                            onTap: () async {
                              final reason = await showAiraCancelReasonDialog(context, clientName: s.client);
                              if (reason == null) return; // artist backed out
                              widget.onUpdateStatus!(s, SlotStatus.cancelled, reason: reason);
                            },
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeMode = _customRange != null;
    final daySlots = _slotsForSelectedDay;
    final groupedRange = _slotsGroupedForRange;
    final clashes = rangeMode ? const <String>[] : _clashDescriptions;
    final today = DateTime.now();
    final isToday = _isoDate(_selectedDate) == _isoDate(DateTime(today.year, today.month, today.day));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: rangeMode
                    ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${groupedRange.fold<int>(0, (n, e) => n + e.value.length)} booking'
                        '${groupedRange.fold<int>(0, (n, e) => n + e.value.length) == 1 ? '' : 's'} in range',
                    style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft),
                  ),
                )
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _next30Days.map((d) {
                      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final label = '${labels[d.weekday - 1]} ${d.day}';
                      final active = _isoDate(d) == _isoDate(_selectedDate);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AiraPill(
                          label: label,
                          active: active,
                          onTap: () => setState(() => _selectedDate = d),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AiraDateRangeButton(
                range: _customRange,
                onTap: _pickRange,
                onClear: () => setState(() => _customRange = null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!widget.loading && !rangeMode && clashes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AiraCard(
              padding: const EdgeInsets.all(14),
              borderColor: AiraColors.gold,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.warning_amber_rounded, size: 16, color: AiraColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      clashes.length == 1
                          ? '${clashes.first}. Reach out to one client to reschedule.'
                          : '${clashes.length} time slots have overlapping bookings on this day — review and reschedule as needed.',
                      style: AiraText.sans(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!widget.loading && !rangeMode && clashes.isNotEmpty) const SizedBox(height: 14),
        if (!widget.loading && !rangeMode && daySlots.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              isToday
                  ? 'No bookings today — new bookings from clients will show up here.'
                  : 'No bookings on this day.',
              style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft),
            ),
          ),
        if (!widget.loading && rangeMode && groupedRange.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'No bookings between ${formatAiraDateRange(_customRange!)}.',
              style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft),
            ),
          ),
        if (!rangeMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: daySlots.map(_slotTile).toList()),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedRange.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(
                          _dateHeaderLabel(entry.key),
                          style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft),
                        ),
                      ),
                      ...entry.value.map(_slotTile),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
