import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/booking/booking.dart';
import '../models/core/status_item.dart';
import '../helper/booking_stats.dart';

class InvoiceRow {
  final String label;
  final String amount;
  final String status;
  const InvoiceRow(this.label, this.amount, this.status);
}

class FinanceScreen extends StatefulWidget {
  final VoidCallback onWithdraw;
  final bool loading;
  final List<Booking> bookings;
  final List<StatusItem> statuses;
  final Map<int, String> customerNames;

  const FinanceScreen({
    super.key,
    required this.onWithdraw,
    this.loading = false,
    this.bookings = const [],
    this.statuses = const [],
    this.customerNames = const {},
  });

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  /// When set, every number on this screen (earnings + recent bookings) is
  /// scoped to this date range instead of all-time — this is how older
  /// earnings, outside the current week, get seen.
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final picked = await pickAiraDateRange(context, initialRange: _range);
    if (picked == null) return;
    setState(() => _range = picked);
  }

  List<Booking> get _filteredBookings {
    final range = _range;
    if (range == null) return widget.bookings;
    return widget.bookings.where((b) {
      final d = DateTime.tryParse(b.bookingDate);
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(range.start) && !day.isAfter(range.end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rangeActive = _range != null;
    final stats = BookingStats(_filteredBookings, widget.statuses);
    final totalEarnings = stats.totalEarnings;
    final weekEarnings = stats.weekEarnings;
    final weekChangePercent = stats.weekChangePercent;
    final rows = stats.recentTransactions.take(6).map((b) {
      final label = stats.statusLabel(b.statusId);
      final customer = widget.customerNames[b.customerId] ?? 'Customer #${b.customerId}';
      return InvoiceRow(
        '$customer — Package #${b.packageId}',
        '₹${b.totalAmount.toStringAsFixed(0)}',
        label == 'completed' ? 'Paid' : (label == 'cancelled' || label == 'no_show' ? 'Cancelled' : 'Pending'),
      );
    }).toList();

    final money = totalEarnings == 0 && widget.loading
        ? '…'
        : '₹${totalEarnings.toStringAsFixed(0)}';

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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AiraCard(
            gradient: AiraGradients.financeCard,
            borderWidth: 0,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rangeActive ? 'EARNINGS IN RANGE' : 'TOTAL EARNINGS',
                    style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.goldSoft, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text(money, style: AiraText.serif(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  rangeActive
                      ? formatAiraDateRange(_range!)
                      : 'This week ₹${weekEarnings.toStringAsFixed(0)}'
                          '${weekChangePercent != 0 ? ' · ${weekChangePercent > 0 ? '+' : ''}${weekChangePercent.toStringAsFixed(0)}% vs last week' : ''}',
                  style: AiraText.sans(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    PrimaryButton(label: 'Withdraw', small: true, background: AiraColors.gold, onTap: widget.onWithdraw),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rangeActive ? 'BOOKINGS IN RANGE' : 'RECENT BOOKINGS',
                  style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
              const SizedBox(height: 10),
              if (widget.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose)),
                )
              else if (rows.isEmpty)
                Text(
                  rangeActive ? 'No bookings in this date range.' : 'No completed bookings yet.',
                  style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft),
                )
              else
              AiraCard(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: rows.asMap().entries.map((e) {
                    final r = e.value;
                    final isLast = e.key == rows.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: isLast ? null : const Border(bottom: BorderSide(color: AiraColors.hair)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(r.label, style: AiraText.sans(fontSize: 13.5))),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(r.amount, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              Text(r.status,
                                  style: AiraText.sans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: r.status == 'Paid' ? AiraColors.success : AiraColors.warn,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
