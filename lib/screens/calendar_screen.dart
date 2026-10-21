// FILE: screens/calendar_screen.dart
// SCREEN: Calendar tab — week strip, bookings per day, set working hours, block days off.
//
// APIs used:
//   GET /artists/availability/schedule/get_all/
//   GET /artists/availability/block/get_all/
//   POST /artists/availability/schedule/set/
//   POST /artists/availability/block/add/

import 'package:flutter/material.dart';
import '../models/auth/add_block.dart';
import '../models/models.dart';
import '../models/core/status_item.dart';
import '../models/booking/booking_reschedule.dart';
import 'booking_detail_screen.dart';
import '../models/auth/set_schedule.dart';
import '../theme/tokens.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../widgets/common.dart';
import '../widgets/sunndari_time_picker.dart';

/// SCREEN: Calendar tab — week strip, bookings per day, set working hours, block days off.
class CalendarScreen extends StatefulWidget {
  final bool showBack;

  final List<BookingSlot> slots;
  final List<StatusItem> statuses;
  final void Function(BookingSlot slot, SlotStatus next, {String? reason})? onUpdateStatus;
  final VoidCallback? onRefresh;

  const CalendarScreen({
    super.key,
    this.showBack = false,
    this.slots = const [],
    this.statuses = const [],
    this.onUpdateStatus,
    this.onRefresh,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// State of [CalendarScreen] — holds the screen data and logic.
class _CalendarScreenState extends State<CalendarScreen> {
  static const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late DateTime _weekStart;
  late DateTime _selected;
  late DateTime _visibleMonth;
  String _view = 'week'; // 'week' | 'month' | 'hours'
  bool _loading = true;
  bool _saving = false;

  final Map<int, bool> _available = {};
  final Map<int, TimeOfDay> _start = {};
  final Map<int, TimeOfDay> _end = {};
  Set<String> _blocked = {}; // dates blocked for the WHOLE day
  final Map<String, List<List<int>>> _partial = {}; // date -> blocked ranges [startMin, endMin]
  final Set<String> _onServer = {}; // dates that already have time-range blocks on the server
  final Set<String> _dirty = {}; // dates with unsaved slot changes
  final Set<int> _wasScheduled = {}; // days that exist on the server (to remove when switched off)

  /// Runs once when the screen opens; starts: _load(), _loadReschedules().
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month, 1);
    _weekStart = _selected.subtract(Duration(days: _selected.weekday - 1));
    _load();
    _loadReschedules();
  }

  Map<int, BookingReschedule> _reschedules = {};

  /// Loads reschedules.
  /// API: rescheduleService.all
  Future<void> _loadReschedules() async {
    // API call: rescheduleService.all
    final m = await ServiceLocator.rescheduleService.all();
    if (mounted) setState(() => _reschedules = m);
  }

  /// Returns true if live.
  bool _isLive(BookingSlot s) => s.status == SlotStatus.confirmed || s.status == SlotStatus.inProgress;

  /// Bookings on.
  List<BookingSlot> _bookingsOn(DateTime d) =>
      widget.slots.where((s) => s.bookingId != null && _isLive(s) && s.date == _iso(d)).toList();

  /// Slot badge.
  String _slotBadge(BookingSlot s) {
    final r = _reschedules[s.bookingId];
    if (r != null && r.isPending) return r.fromCustomer ? 'Reschedule Request' : 'Reschedule Requested';
    return s.status == SlotStatus.inProgress ? 'In Progress' : 'Confirmed';
  }

  /// Opens booking.
  void _openBooking(BookingSlot s) {
    // Navigates to BookingDetailScreen
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => BookingDetailScreen(
        bookingId: s.bookingId!,
        slot: s,
        onUpdateStatus: widget.onUpdateStatus,
        statuses: widget.statuses,
        onRefresh: widget.onRefresh,
      ),
    ))
        .then((_) => _loadReschedules());
  }

  /// Shows booking sheet.
  void _showBookingSheet(BookingSlot s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SunndariIconBubble(icon: Icons.event_available_outlined, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.client == '—' ? s.service : s.client,
                            style: AiraText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                        Text(s.service, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
                        Text('${s.time} • ${_slotBadge(s)}',
                            style: AiraText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AiraColors.rose)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'View Booking',
                icon: Icons.visibility_outlined,
                expand: true,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openBooking(s);
                },
              ),
              const SizedBox(height: 8),
              Text('Need A Different Time? Open The Booking And Tap Reschedule.',
                  style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
            ],
          ),
        ),
      ),
    );
  }

  /// Bookings section.
  List<Widget> _bookingsSection() {
    final list = _bookingsOn(_selected);
    return [
      Text('Bookings', style: AiraText.serif(fontSize: 18)),
      const SizedBox(height: 8),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('No Confirmed Bookings On This Day.',
              style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
        )
      else
        for (final s in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AiraCard(
              padding: const EdgeInsets.all(13),
              onTap: () => _showBookingSheet(s),
              child: Row(
                children: [
                  const SunndariIconBubble(icon: Icons.event_note_outlined, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.time, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                        Text(s.client == '—' ? s.service : s.client,
                            style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                        Text(s.service, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_reschedules[s.bookingId]?.isPending ?? false) ? AiraColors.goldSoft : const Color(0xFFEAF3EC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(_slotBadge(s),
                            style: AiraText.sans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: (_reschedules[s.bookingId]?.isPending ?? false)
                                    ? const Color(0xFF8A6A1F)
                                    : AiraColors.success)),
                      ),
                      const SizedBox(height: 6),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AiraColors.rose),
                    ],
                  ),
                ],
              ),
            ),
          ),
      const SizedBox(height: 8),
    ];
  }

  /// As list.
  List<dynamic> _asList(dynamic j) {
    if (j is List) return j;
    if (j is Map && j['data'] is List) return j['data'] as List;
    return const [];
  }

  TimeOfDay _parse(dynamic v, TimeOfDay fallback) {
    final parts = v?.toString().split(':');
    if (parts == null || parts.length < 2) return fallback;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? fallback.hour,
      minute: int.tryParse(parts[1]) ?? fallback.minute,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _label(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Same day.
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _select(DateTime d) {
    _selected = d;
    _weekStart = d.subtract(Duration(days: d.weekday - 1));
    _visibleMonth = DateTime(d.year, d.month, 1);
  }

  /// Minutes since midnight from "HH:MM[:SS]" (null when missing).
  int? _minOrNull(dynamic v) {
    final parts = v?.toString().split(':');
    if (parts == null || parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return (h == null || m == null) ? null : h * 60 + m;
  }

  String _dateOnly(String e) => e.length >= 10 ? e.substring(0, 10) : e;

  /// Block records as (date, startMin?, endMin?) — start/end are null for a full-day block.
  List<(String, int?, int?)> _blockRecords(dynamic blocks) => [
    for (final b in _asList(blocks))
      if (b is Map && (b['blockDate'] ?? b['block_date']) != null)
        (
        _dateOnly((b['blockDate'] ?? b['block_date']).toString()),
        _minOrNull(b['startTime'] ?? b['start_time']),
        _minOrNull(b['endTime'] ?? b['end_time']),
        ),
  ];

  /// Splits the server's blocks into full-day blocks and time-range blocks.
  void _parseBlocks(dynamic blocks) {
    final full = <String>{};
    _partial.clear();
    _onServer.clear();
    for (final (d, st, en) in _blockRecords(blocks)) {
      if (st == null || en == null) {
        full.add(d);
      } else {
        (_partial[d] ??= []).add([st, en]);
        _onServer.add(d);
      }
    }
    _blocked = full;
  }

  TimeOfDay _tod(int minutes) => TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  /// Hourly slots [startMin, endMin] inside the selected day's working hours.
  List<List<int>> _slots() {
    final st = _s.hour * 60 + _s.minute;
    final en = _e.hour * 60 + _e.minute;
    final out = <List<int>>[];
    for (var m = st; m < en; m += 60) {
      out.add([m, m + 60 > en ? en : m + 60]);
    }
    return out;
  }

  bool _slotBlocked(String iso, List<int> slot) =>
      _blocked.contains(iso) ||
          (_partial[iso] ?? const []).any((r) => slot[0] < r[1] && slot[1] > r[0]);

  /// Tap a slot: block it / open it again (merged into ranges for the API).
  void _toggleSlot(List<int> slot) {
    final iso = _iso(_selected);
    if (_blocked.contains(iso)) {
      AppFeedback.showInfo(context, 'This Whole Day Is Blocked. Unblock The Day First.');
      return;
    }
    final slots = _slots();
    final blockedNow = <int>{
      for (final sl in slots)
        if (_slotBlocked(iso, sl)) sl[0],
    };
    blockedNow.contains(slot[0]) ? blockedNow.remove(slot[0]) : blockedNow.add(slot[0]);
    final ranges = <List<int>>[];
    for (final sl in slots) {
      if (!blockedNow.contains(sl[0])) continue;
      if (ranges.isNotEmpty && ranges.last[1] == sl[0]) {
        ranges.last[1] = sl[1];
      } else {
        ranges.add([sl[0], sl[1]]);
      }
    }
    setState(() {
      ranges.isEmpty ? _partial.remove(iso) : _partial[iso] = ranges;
      _dirty.add(iso);
    });
  }

  /// Saves the blocked hours of the selected day.
  /// API: removeBlock (clears the day) → addBlock for every blocked range (with start_time / end_time).
  Future<void> _saveSlots() async {
    final iso = _iso(_selected);
    final ranges = [for (final r in (_partial[iso] ?? const <List<int>>[])) [r[0], r[1]]];
    setState(() => _saving = true);
    try {
      final art = ServiceLocator.artistService;
      if (_onServer.contains(iso)) {
        await art.removeBlock(iso);
        _onServer.remove(iso);
      }
      for (final r in ranges) {
        await art.addBlock(AddBlock(blockDate: iso, startTime: _fmt(_tod(r[0])), endTime: _fmt(_tod(r[1]))));
      }
      if (ranges.isNotEmpty) {
        final check = await art.getAllBlocks();
        final ignored = _blockRecords(check).any((r) => r.$1 == iso && (r.$2 == null || r.$3 == null));
        if (ignored) {
          await art.removeBlock(iso);
          if (mounted) {
            setState(() {
              _partial.remove(iso);
              _dirty.remove(iso);
            });
            AppFeedback.showWarning(context, 'Selected Hours Are Not Supported By The Server Yet. Nothing Was Blocked.');
          }
          return;
        }
        _onServer.add(iso);
      }
      if (mounted) {
        setState(() => _dirty.remove(iso));
        AppFeedback.showSuccess(context, 'Blocked Hours Saved ✓');
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Loads this screen's data.
  /// Uses 2 APIs (see inline notes).
  Future<void> _load() async {
    try {
      final art = ServiceLocator.artistService;
      // API call: artistService.getAllSchedules → GET /artists/availability/schedule/get_all/
      final sched = await art.getAllSchedules();
      // API call: artistService.getAllBlocks → GET /artists/availability/block/get_all/
      final blocks = await art.getAllBlocks();
      for (final r in _asList(sched)) {
        final m = Map<String, dynamic>.from(r as Map);
        final d = m['dayOfWeek'];
        if (d is! int) continue;
        _available[d] = true;
        _wasScheduled.add(d);
        _start[d] = _parse(m['startTime'], const TimeOfDay(hour: 9, minute: 0));
        _end[d] = _parse(m['endTime'], const TimeOfDay(hour: 18, minute: 0));
      }
      _parseBlocks(blocks);
    } catch (_) {
    }
    if (mounted) setState(() => _loading = false);
  }

  int get _dow => _selected.weekday - 1;
  /// Returns true if available.
  bool get _isAvailable => (_available[_dow] ?? false) && !_blocked.contains(_iso(_selected));
  /// "Open 24 Hours" = 12:00 AM to 11:59 PM (a day's hours cannot cross midnight).
  static const _open = TimeOfDay(hour: 0, minute: 0);
  static const _close = TimeOfDay(hour: 23, minute: 59);
  bool _is24h(TimeOfDay a, TimeOfDay b) => a.hour == 0 && a.minute == 0 && b.hour == 23 && b.minute == 59;

  TimeOfDay get _s => _start[_dow] ?? const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay get _e => _end[_dow] ?? const TimeOfDay(hour: 18, minute: 0);

  /// Lets the user pick time.
  Future<void> _pickTime(bool start) async {
    final t = await pickSunndariTime(context, initial: start ? _s : _e, helpText: start ? 'Start Time' : 'End Time');
    if (t == null) return;
    setState(() => start ? _start[_dow] = t : _end[_dow] = t);
  }

  /// Saves the entered data.
  /// API: artistService.setSchedule → POST /artists/availability/schedule/set/
  Future<void> _save() async {
    for (var d = 0; d < 7; d++) {
      if (_available[d] != true) continue;
      final st = _start[d] ?? const TimeOfDay(hour: 9, minute: 0);
      final en = _end[d] ?? const TimeOfDay(hour: 18, minute: 0);
      if (en.hour * 60 + en.minute <= st.hour * 60 + st.minute) {
        AppFeedback.showWarning(context, 'End Time Must Be After Start Time (${_weekNames[d]}).');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final art = ServiceLocator.artistService;
      for (var d = 0; d < 7; d++) {
        if (_available[d] == true) {
          // API call: artistService.setSchedule → POST /artists/availability/schedule/set/
          await art.setSchedule(SetSchedule(
            dayOfWeek: d,
            startTime: _fmt(_start[d] ?? const TimeOfDay(hour: 9, minute: 0)),
            endTime: _fmt(_end[d] ?? const TimeOfDay(hour: 18, minute: 0)),
          ));
        }
        else if (_wasScheduled.contains(d)) {
          // API call: artistService.removeSchedule → DELETE /artists/availability/schedule/remove/
          await art.removeSchedule(d);
        }
      }
      _wasScheduled
        ..clear()
        ..addAll([for (var d = 0; d < 7; d++) if (_available[d] == true) d]);
      if (mounted) AppFeedback.showSuccess(context, 'Working Hours Saved ✓');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Asks for confirmation, then blocks / unblocks the selected day (single place for Block Time).
  Future<void> _toggleBlock() async {
    final iso = _iso(_selected);
    final blocked = _blocked.contains(iso);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AiraColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(blocked ? 'Unblock This Day?' : 'Block This Day?', style: AiraText.serif(fontSize: 19)),
        content: Text(
          blocked
              ? 'Clients Will Be Able To Book You On $iso Again.'
              : 'Clients Will Not Be Able To Book You On $iso.',
          style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(blocked ? 'Unblock' : 'Block',
                style: AiraText.sans(fontWeight: FontWeight.w700, color: AiraColors.rose)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (blocked) {
      await _unblockDay();
    } else {
      await _blockDay();
    }
  }

  /// Block day.
  /// API: artistService.addBlock → POST /artists/availability/block/add/
  Future<void> _blockDay() async {
    try {
      // API call: artistService.addBlock → POST /artists/availability/block/add/
      await ServiceLocator.artistService.addBlock(AddBlock(blockDate: _iso(_selected)));
      if (!mounted) return;
      setState(() => _blocked.add(_iso(_selected)));
      AppFeedback.showSuccess(context, 'This Day Is Blocked');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    }
  }

  /// Unblocks the selected day so it persists after reload.
  /// API: artistService.removeBlock → DELETE /artists/availability/block/remove/
  Future<void> _unblockDay() async {
    final iso = _iso(_selected);
    try {
      await ServiceLocator.artistService.removeBlock(iso);
      if (mounted) setState(() => _blocked.remove(iso));
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    }
  }

  static const _weekNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Weekly working hours: pick the days and one start / end time, then it saves straight away.
  Future<void> _openWeeklyHours() async {
    final days = <int>{for (var d = 0; d < 7; d++) if (_available[d] == true) d};
    if (days.isEmpty) days.addAll([0, 1, 2, 3, 4, 5]);
    var start = _s, end = _e;
    String? problem;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AiraColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> pick(bool isStart) async {
            final t = await pickSunndariTime(ctx, initial: isStart ? start : end, helpText: isStart ? 'Start Time' : 'End Time');
            if (t != null) setSheet(() { isStart ? start = t : end = t; problem = null; });
          }
          Widget timeTile(String label, TimeOfDay t, bool isStart) => Expanded(
            child: GestureDetector(
              onTap: () => pick(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AiraColors.pinkFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AiraColors.pinkBorder, width: 1.1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                  const SizedBox(height: 2),
                  Text(t.format(ctx), style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Working Hours', style: AiraText.serif(fontSize: 20)),
                const SizedBox(height: 4),
                Text('Choose The Days You Work And Your Daily Hours.',
                    style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var d = 0; d < 7; d++)
                    GestureDetector(
                      onTap: () => setSheet(() { days.contains(d) ? days.remove(d) : days.add(d); problem = null; }),
                      child: Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: days.contains(d) ? AiraGradients.aira : null,
                          color: days.contains(d) ? null : AiraColors.pinkFill,
                          borderRadius: BorderRadius.circular(12),
                          border: days.contains(d) ? null : Border.all(color: AiraColors.pinkBorder),
                        ),
                        child: Text(_weekNames[d],
                            style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w700,
                                color: days.contains(d) ? Colors.white : AiraColors.charcoal)),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),
                Row(children: [timeTile('Start Time', start, true), const SizedBox(width: 12), timeTile('End Time', end, false)]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('Open 24 Hours (12:00 AM – 11:59 PM)',
                          style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                    ),
                    Switch(
                      value: _is24h(start, end),
                      onChanged: (v) => setSheet(() {
                        start = v ? _open : const TimeOfDay(hour: 9, minute: 0);
                        end = v ? _close : const TimeOfDay(hour: 18, minute: 0);
                        problem = null;
                      }),
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      trackColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected) ? AiraColors.success : null,
                      ),
                    ),
                  ],
                ),
                if (problem != null) ...[
                  const SizedBox(height: 10),
                  Text(problem!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Save Working Hours',
                  expand: true,
                  onTap: () {
                    if (days.isEmpty) {
                      setSheet(() => problem = 'Please Select At Least One Working Day.');
                    } else if (end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
                      setSheet(() => problem = 'End Time Must Be After The Start Time.');
                    } else {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
    if (apply != true || !mounted) return;
    setState(() {
      for (var d = 0; d < 7; d++) {
        _available[d] = days.contains(d);
        if (days.contains(d)) {
          _start[d] = start;
          _end[d] = end;
        }
      }
    });
    await _save();
  }

  /// Block tab: tap hours to block / open them for the selected day (separate from Working Hours).
  List<Widget> _blockSection() {
    final iso = _iso(_selected);
    final fullDay = _blocked.contains(iso);
    final slots = _slots();
    final working = (_available[_dow] ?? false) && slots.isNotEmpty;

    Widget legend(Color c, String t, {bool fill = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: fill ? c.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c, width: 1.4),
        ),
      ),
      const SizedBox(width: 6),
      Text(t, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
    ]);

    return [
      if (!working)
        AiraCard(
          child: Text('You Are Not Working On This Day. Turn It On From The Hours Tab To Block Specific Hours.',
              style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.4)),
        )
      else ...[
        Text('Tap An Hour To Block Or Open It.',
            style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
        const SizedBox(height: 10),
        Row(children: [
          legend(AiraColors.success, 'Open'),
          const SizedBox(width: 16),
          legend(AiraColors.errorText, 'Blocked', fill: true),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final sl in slots)
              Builder(builder: (_) {
                final blocked = _slotBlocked(iso, sl);
                final c = blocked ? AiraColors.errorText : AiraColors.success;
                return GestureDetector(
                  onTap: () => _toggleSlot(sl),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: blocked ? c.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c, width: 1.4),
                    ),
                    child: Text(_label(_tod(sl[0])),
                        style: AiraText.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: blocked ? c : AiraColors.charcoal,
                        )),
                  ),
                );
              }),
          ],
        ),
        const SizedBox(height: 14),
        if (_dirty.contains(iso))
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save Blocked Hours',
            expand: true,
            onTap: _saving ? null : _saveSlots,
          ),
        if (_dirty.contains(iso)) const SizedBox(height: 8),
      ],
      GhostButton(
        label: fullDay ? 'Unblock This Day' : 'Block Full Day',
        icon: fullDay ? Icons.event_available_outlined : Icons.event_busy_outlined,
        expand: true,
        onTap: _toggleBlock,
      ),
      const SizedBox(height: 6),
      Text('Blocked Hours Are Hidden From Clients.',
          style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
      const SizedBox(height: 8),
    ];
  }

  /// UI piece: time box.
  Widget _timeBox(String label, TimeOfDay t, bool start) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _pickTime(start),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AiraColors.pinkFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AiraColors.pinkBorder),
            ),
            child: Row(
              children: [
                Expanded(child: Text(_label(t), style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600))),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AiraColors.roseDeep),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  /// UI piece: week strip.
  Widget _weekStrip() {
    final end = _weekStart.add(const Duration(days: 6));
    final range = '${_weekStart.day} ${_months[_weekStart.month - 1].substring(0, 3)} – '
        '${end.day} ${_months[end.month - 1].substring(0, 3)} ${end.year}';
    return AiraCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_left_rounded, color: AiraColors.rose),
              ),
              Expanded(
                child: Center(
                  child: Text(range,
                      style: AiraText.sans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_right_rounded, color: AiraColors.rose),
              ),
            ],
          ),
          Row(
            children: List.generate(7, (i) {
              final d = _weekStart.add(Duration(days: i));
              final sel = _sameDay(d, _selected);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _select(d)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: sel ? AiraGradients.button : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(_dayShort[i],
                            style: AiraText.sans(fontSize: 11, color: sel ? Colors.white : AiraColors.charcoalSoft)),
                        const SizedBox(height: 4),
                        Text('${d.day}',
                            style: AiraText.sans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : AiraColors.roseDeep)),
                        const SizedBox(height: 3),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _bookingsOn(d).isEmpty
                                ? Colors.transparent
                                : (sel ? Colors.white : AiraColors.rose),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// UI piece: segment (Week | Month | Hours | Block).
  Widget _segment() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AiraColors.pinkFill,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AiraColors.hair),
    ),
    child: Row(
      children: [
        for (final e in {'Week': 'week', 'Month': 'month', 'Hours': 'hours', 'Block': 'block'}.entries)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _view = e.value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _view == e.value ? AiraGradients.button : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(e.key,
                    style: AiraText.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _view == e.value ? Colors.white : AiraColors.roseDeep,
                    )),
              ),
            ),
          ),
      ],
    ),
  );

  /// UI piece: month grid.
  Widget _monthGrid() {
    final first = _visibleMonth;
    final days = DateTime(first.year, first.month + 1, 0).day;
    final offset = first.weekday - 1;
    return AiraCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _visibleMonth = DateTime(first.year, first.month - 1, 1)),
                icon: const Icon(Icons.chevron_left_rounded, color: AiraColors.rose),
              ),
              Expanded(
                child: Center(
                  child: Text('${_months[first.month - 1]} ${first.year}',
                      style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _visibleMonth = DateTime(first.year, first.month + 1, 1)),
                icon: const Icon(Icons.chevron_right_rounded, color: AiraColors.rose),
              ),
            ],
          ),
          Row(
            children: [
              for (final d in _dayShort)
                Expanded(
                    child: Center(child: Text(d, style: AiraText.sans(fontSize: 11, color: AiraColors.charcoalSoft)))),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < offset; i++) const SizedBox.shrink(),
              for (var day = 1; day <= days; day++)
                Builder(builder: (_) {
                  final d = DateTime(first.year, first.month, day);
                  final sel = _sameDay(d, _selected);
                  return GestureDetector(
                    onTap: () => setState(() => _select(d)),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: sel ? AiraGradients.button : null,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$day',
                          style: AiraText.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AiraColors.roseDeep)),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SunndariBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
            : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (widget.showBack) ...[
              SunndariAppBar(onBack: () => Navigator.of(context).pop()),
              const SunndariPageHeading(title: 'My Calendar', subtitle: 'Make Time For Your Next Opportunity.'),
            ] else
              const SunndariTabHeader(title: 'My Calendar', subtitle: 'Make Time For Your Next Opportunity.', flush: true),
            const SizedBox(height: 14),
            _segment(),
            const SizedBox(height: 14),
            _view == 'month' ? _monthGrid() : _weekStrip(),
            const SizedBox(height: 16),
            Text('${_dayLong[_dow]}, ${_selected.day} ${_months[_selected.month - 1]}',
                style: AiraText.serif(fontSize: 20)),
            const SizedBox(height: 10),
            if (_view == 'week' || _view == 'month') ..._bookingsSection(),
            if (_view == 'block') ..._blockSection(),
            if (_view == 'hours') ...[
              AiraCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const SunndariIconBubble(icon: Icons.calendar_today_outlined, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available For Bookings',
                              style: AiraText.sans(
                                  fontSize: 14.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                          Text('Clients Can Book You On This Day.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      trackColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected) ? AiraColors.success : null,
                      ),
                      onChanged: (v) {
                        setState(() => _available[_dow] = v);
                        if (v && _blocked.contains(_iso(_selected))) _unblockDay();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AiraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Working Hours',
                        style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _timeBox('Start Time', _s, true),
                      const SizedBox(width: 12),
                      _timeBox('End Time', _e, false),
                    ]),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Open 24 Hours (12:00 AM – 11:59 PM)',
                              style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                        ),
                        Switch(
                          value: _is24h(_s, _e),
                          onChanged: (v) => setState(() {
                            _start[_dow] = v ? _open : const TimeOfDay(hour: 9, minute: 0);
                            _end[_dow] = v ? _close : const TimeOfDay(hour: 18, minute: 0);
                          }),
                          thumbColor: const WidgetStatePropertyAll(Colors.white),
                          trackColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected) ? AiraColors.success : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AiraCard(
                onTap: _openWeeklyHours,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const SunndariIconBubble(icon: Icons.access_time_rounded, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set Weekly Working Hours',
                              style: AiraText.sans(
                                  fontSize: 14.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                          Text('Choose Your Working Days And Daily Hours.',
                              style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AiraColors.rose),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AiraColors.blush, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AiraColors.rose),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time Protected Automatically',
                              style: AiraText.sans(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                          Text('Service Duration And Travel Buffers Prevent Overlapping Bookings.',
                              style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _saving ? 'Saving…' : 'Save Availability',
                expand: true,
                onTap: _saving ? null : _save,
              ),
            ],
          ],
        ),
      ),
    );
  }
}