// FILE: screens/reschedule_confirmed_screen.dart
// SCREEN: Reschedule Confirmed — step 3: request-sent confirmation.

import 'package:flutter/material.dart';
import '../models/booking/booking_reschedule.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/reschedule_widgets.dart';

/// SCREEN: Reschedule Confirmed — step 3: request-sent confirmation.
class RescheduleConfirmedScreen extends StatelessWidget {
  final String serviceName;
  final String clientName;
  final DateTime oldStart;
  final DateTime newStart;

  const RescheduleConfirmedScreen({
    super.key,
    required this.serviceName,
    required this.clientName,
    required this.oldStart,
    required this.newStart,
  });

  /// UI piece: step.
  Widget _step(int n, String text, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AiraColors.blush, shape: BoxShape.circle),
              child: Text('$n', style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: AiraText.sans(fontSize: 13, color: AiraColors.charcoal, height: 1.35)),
            ),
          ],
        ),
      );

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AiraColors.bg,
        body: SunndariBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(gradient: AiraGradients.button, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 46, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text('Reschedule Request Sent', style: AiraText.serif(fontSize: 24), textAlign: TextAlign.center)),
                const SizedBox(height: 6),
                Center(
                  child: Text('$clientName Has Been Asked To Confirm The New Time.',
                      textAlign: TextAlign.center,
                      style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft, height: 1.35)),
                ),
                const SizedBox(height: 12),
                const Center(child: ReschedulePill('Reschedule Requested')),
                const SizedBox(height: 18),
                AiraCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serviceName, style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                      const SizedBox(height: 10),
                      RescheduleCompareCard(oldStart: oldStart, newStart: newStart, oldLabel: 'Current', newLabel: 'Requested'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AiraCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What Happens Next', style: AiraText.serif(fontSize: 17)),
                      const SizedBox(height: 10),
                      _step(1, 'Your Client Reviews The New Date And Time.'),
                      _step(2, 'If They Accept, Your Booking And Calendar Update Automatically.'),
                      _step(3, 'Until Then Your Booking Stays At The Current Time.', last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Back To Booking',
                  icon: Icons.arrow_back_rounded,
                  expand: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
