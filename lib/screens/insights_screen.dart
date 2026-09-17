import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/booking/booking.dart';
import '../models/artist/artist_profile.dart';
import '../models/artist/package.dart';
import '../models/core/status_item.dart';
import '../utils/service_locator.dart';

class _InsightItem {
  final String tone; // success | warn | gold
  final String title;
  final String body;
  final IconData icon;
  final String? cta;
  final VoidCallback? onTap;
  const _InsightItem(this.tone, this.title, this.body, this.icon, {this.cta, this.onTap});
}

/// Every number here is computed from real API data — bookings, packages,
/// and the artist's own profile. There's no analytics/insights endpoint in
/// the Sunndari API, so the "business score" is a transparent, on-device
/// composite (repeat-client rate + completion rate + rating) rather than
/// something the backend calculated — see `_computeScore()` below.
class InsightsScreen extends StatefulWidget {
  final void Function(String target, [String? tab]) onNavigate;
  const InsightsScreen({super.key, required this.onNavigate});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _loading = true;
  String? _error;
  List<Booking> _bookings = [];
  List<StatusItem> _statuses = [];
  List<Package> _packages = [];
  ArtistProfile? _profile;

  /// When set, the score and every insight below is computed only from
  /// bookings inside this range — otherwise it's all-time, as before.
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Bookings is the one piece of data every insight on this screen
      // depends on, so it alone is allowed to fail the whole screen.
      // Statuses/packages/profile are each best-effort — previously all
      // four were in a single Future.wait, so one bad StatusItem (or any
      // other single-endpoint hiccup) took down the entire Insights
      // screen with a generic error instead of showing what it could.
      final bookings = await ServiceLocator.bookingService.getAllBookings(limit: 300);

      List<StatusItem> statuses = [];
      try {
        statuses = await ServiceLocator.coreService.getBookingStatuses();
      } catch (_) {
        // Falls back to an empty list — completion-rate style numbers
        // will read as 0 rather than the screen erroring out entirely.
      }

      List<Package> packages = [];
      try {
        packages = (await ServiceLocator.artistService.getAllPackages(limit: 50)).data;
      } catch (_) {
        // Best-effort — "No packages listed yet" card covers this case.
      }

      ArtistProfile? profile;
      try {
        profile = await ServiceLocator.artistService.getProfile();
      } catch (_) {
        // Best-effort — score just won't have a rating component yet.
      }

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _statuses = statuses;
        _packages = packages;
        _profile = profile;
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

  String _statusLabel(int statusId) {
    final m = _statuses.where((s) => s.statusId == statusId);
    return m.isNotEmpty ? m.first.name.toLowerCase() : '';
  }

  Future<void> _pickRange() async {
    final picked = await pickAiraDateRange(context, initialRange: _range);
    if (picked == null) return;
    setState(() => _range = picked);
  }

  List<Booking> get _filteredBookings {
    final range = _range;
    if (range == null) return _bookings;
    return _bookings.where((b) {
      final d = DateTime.tryParse(b.bookingDate);
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(range.start) && !day.isAfter(range.end);
    }).toList();
  }

  double get _repeatRate {
    final completed = _filteredBookings.where((b) => _statusLabel(b.statusId) == 'completed').toList();
    if (completed.isEmpty) return 0;
    final byCustomer = <int, int>{};
    for (final b in completed) {
      byCustomer[b.customerId] = (byCustomer[b.customerId] ?? 0) + 1;
    }
    final repeatCustomers = byCustomer.values.where((c) => c > 1).length;
    return (repeatCustomers / byCustomer.length) * 100;
  }

  double get _completionRate {
    if (_filteredBookings.isEmpty) return 0;
    final completed = _filteredBookings.where((b) => _statusLabel(b.statusId) == 'completed').length;
    final decided = _filteredBookings
        .where((b) => ['completed', 'cancelled', 'no_show'].contains(_statusLabel(b.statusId)))
        .length;
    if (decided == 0) return 0;
    return (completed / decided) * 100;
  }

  double get _avgBookingValue {
    final completed = _filteredBookings.where((b) => _statusLabel(b.statusId) == 'completed').toList();
    if (completed.isEmpty) return 0;
    return completed.fold<double>(0, (s, b) => s + b.totalAmount) / completed.length;
  }

  int get _pendingCount =>
      _filteredBookings.where((b) => _statusLabel(b.statusId) == 'pending').length;

  int get _upcomingCount => _filteredBookings.where((b) {
        final label = _statusLabel(b.statusId);
        if (label != 'pending' && label != 'confirmed') return false;
        final d = DateTime.tryParse(b.bookingDate);
        if (d == null) return false;
        final today = DateTime.now();
        final day = DateTime(d.year, d.month, d.day);
        return !day.isBefore(DateTime(today.year, today.month, today.day));
      }).length;

  int get _activePackagesCount => _packages.where((p) => p.isActive).length;

  /// Simple, transparent 0-100 composite: half from rating (out of 5),
  /// a quarter from repeat-client rate, a quarter from completion rate.
  int get _score {
    final ratingPart = ((_profile?.avgRating ?? 0) / 5) * 50;
    final repeatPart = (_repeatRate / 100) * 25;
    final completionPart = (_completionRate / 100) * 25;
    return (ratingPart + repeatPart + completionPart).round().clamp(0, 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _filteredBookings.where((b) => _statusLabel(b.statusId) == 'completed').length;

    final items = <_InsightItem>[
      if (completedCount == 0) ...[
        // Even with zero completed bookings, there's real fetched data
        // worth surfacing here (upcoming/pending bookings, active
        // packages) instead of leaving the screen looking empty until
        // the first booking is completed.
        if (_upcomingCount > 0)
          _InsightItem(
            'success',
            '$_upcomingCount upcoming booking${_upcomingCount == 1 ? '' : 's'}',
            _pendingCount > 0
                ? '$_pendingCount of these ${_pendingCount == 1 ? 'is' : 'are'} still awaiting your confirmation.'
                : 'All confirmed and on your schedule.',
            Icons.event_available_outlined,
            cta: _pendingCount > 0 ? 'Review bookings' : null,
            onTap: _pendingCount > 0 ? () => widget.onNavigate('business', 'booking') : null,
          ),
        _InsightItem('gold', 'No completed bookings yet',
            'Once you complete a few bookings, AiRA will show your repeat-client rate and average booking value here.',
            Icons.info_outline),
        if (_activePackagesCount > 0)
          _InsightItem(
            'success',
            '$_activePackagesCount active package${_activePackagesCount == 1 ? '' : 's'}',
            "You're set up to accept bookings for these — no action needed.",
            Icons.card_giftcard_outlined,
          ),
      ] else ...[
        _InsightItem(
          _repeatRate >= 40 ? 'success' : 'warn',
          _repeatRate >= 40 ? 'Strong repeat rate' : 'Room to grow repeat clients',
          '${_repeatRate.toStringAsFixed(0)}% of your clients have booked with you more than once.',
          Icons.emoji_events_outlined,
        ),
        _InsightItem(
          'gold',
          'Average booking value',
          '₹${_avgBookingValue.toStringAsFixed(0)} per completed booking, across $completedCount booking${completedCount == 1 ? '' : 's'}.',
          Icons.currency_rupee,
        ),
      ],
      if (_packages.isEmpty)
        _InsightItem('warn', 'No packages listed yet',
            "Clients can't book a fixed package from you until you add one.",
            Icons.card_giftcard_outlined,
            cta: 'Create a package', onTap: () => widget.onNavigate('grow', 'marketing')),
    ];

    Color toneColor(String tone) => switch (tone) {
          'success' => AiraColors.success,
          'warn' => AiraColors.warn,
          _ => AiraColors.gold,
        };
    Color toneBg(String tone) => switch (tone) {
          'success' => const Color(0xFFEAF3EC),
          'warn' => const Color(0xFFFBF1DD),
          _ => AiraColors.goldSoft,
        };

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose));
    }
    if (_error != null) {
      return AiraErrorState(message: _error!, onRetry: _load);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: AiraDateRangeButton(
              range: _range,
              onTap: _pickRange,
              onClear: () => setState(() => _range = null),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AiraCard(
            gradient: AiraGradients.hero,
            borderWidth: 0,
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BUSINESS SCORE', style: AiraText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                    const SizedBox(height: 4),
                    Text('$_score', style: AiraText.serif(fontSize: 36, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      _range == null
                          ? 'From your rating, repeat clients & completion rate'
                          : 'For ${formatAiraDateRange(_range!)} — rating, repeat clients & completion rate',
                      style: AiraText.sans(fontSize: 10, color: AiraColors.charcoalSoft),
                    ),
                  ],
                ),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CustomPaint(painter: _ScoreRingPainter(_score / 100)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: items
                .map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AiraCard(
                        padding: const EdgeInsets.all(16),
                        onTap: it.onTap,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(color: toneBg(it.tone), borderRadius: BorderRadius.circular(16)),
                              child: Icon(it.icon, size: 17, color: toneColor(it.tone)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.title, style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(it.body, style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft, height: 1.4)),
                                  if (it.cta != null) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(it.cta!, style: AiraText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward, size: 12, color: AiraColors.roseDeep),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  _ScoreRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final track = Paint()
      ..color = AiraColors.blush
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, track);

    final fg = Paint()
      ..color = AiraColors.rose
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90deg
      2 * 3.14159265 * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) => oldDelegate.progress != progress;
}
