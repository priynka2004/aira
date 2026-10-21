// FILE: screens/business_screen.dart
// SCREEN: Business tab wrapper — sub-tabs Insights | Bookings | Finance.

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/booking/booking.dart';
import '../models/core/status_item.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'insights_screen.dart';
import 'booking_screen.dart';
import 'finance_screen.dart';

/// SCREEN: Business tab wrapper — sub-tabs Insights | Bookings | Finance.
class BusinessScreen extends StatelessWidget {
  final String activeTab;
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

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final (title, sub) = switch (activeTab) {
      'booking' => ('My Bookings', 'Every Appointment, Organised.'),
      'finance' => ('My Earnings', 'A Clear View Of Your Business Income.'),
      _ => ('Insights', 'See How Your Business Is Growing.'),
    };
    return SunndariBackground(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SunndariTabHeader(title: title, subtitle: sub),
            Expanded(
              child: switch (activeTab) {
                'booking' => BookingScreen(
                  slots: slots,
                  loading: loading,
                  onUpdateStatus: onUpdateStatus,
                  statuses: bookingStatuses,
                  onRefresh: onRefresh,
                  onNavigate: onNavigate,
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
    );
  }
}
