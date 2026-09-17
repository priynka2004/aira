import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/booking/booking.dart';
import '../models/core/status_item.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'insights_screen.dart';
import 'booking_screen.dart';
import 'finance_screen.dart';

class BusinessScreen extends StatelessWidget {
  final String activeTab; // insights | booking | finance
  final ValueChanged<String> onTabSelect;
  final void Function(String target, [String? tab]) onNavigate;
  final List<BookingSlot> slots;
  final VoidCallback onWithdraw;
  final bool loading;
  final void Function(BookingSlot slot, SlotStatus next, {String? reason})? onUpdateStatus;
  final List<Booking> bookings;
  final List<StatusItem> bookingStatuses;
  final Map<int, String> customerNames;
  final VoidCallback? onRefresh;

  const BusinessScreen({
    super.key,
    required this.activeTab,
    required this.onTabSelect,
    required this.onNavigate,
    required this.slots,
    required this.onWithdraw,
    this.loading = false,
    this.onUpdateStatus,
    this.bookings = const [],
    this.bookingStatuses = const [],
    this.customerNames = const {},
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AiraColors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiraScreenHeader(title: 'Business'),
            AiraSegTabs(
              tabs: const [
                SegTabItem('insights', 'Insights'),
                SegTabItem('booking', 'Bookings'),
                SegTabItem('finance', 'Finance'),
              ],
              active: activeTab,
              onSelect: onTabSelect,
            ),
            Expanded(
              child: switch (activeTab) {
                'booking' => BookingScreen(
                  slots: slots,
                  loading: loading,
                  onUpdateStatus: onUpdateStatus,
                  statuses: bookingStatuses,
                  onRefresh: onRefresh,
                ),
                'finance' => FinanceScreen(
                  onWithdraw: onWithdraw,
                  loading: loading,
                  bookings: bookings,
                  statuses: bookingStatuses,
                  customerNames: customerNames,
                ),
                _ => InsightsScreen(onNavigate: onNavigate),
              },
            ),
          ],
        ),
      ),
    );
  }
}
