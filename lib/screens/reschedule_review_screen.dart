// FILE: screens/reschedule_review_screen.dart
// SCREEN: Reschedule Review — step 2: review old vs new time and send the request.

import 'package:flutter/material.dart';
import '../models/booking/booking_reschedule.dart';
import '../theme/tokens.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../widgets/common.dart';
import '../widgets/reschedule_widgets.dart';

/// SCREEN: Reschedule Review — step 2: review old vs new time and send the request.
class RescheduleReviewScreen extends StatefulWidget {
  final int bookingId;
  final String serviceName;
  final String venueLabel;
  final String clientName;
  final DateTime oldStart;
  final DateTime newStart;
  final String reason;
  final String note;

  const RescheduleReviewScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
    required this.venueLabel,
    required this.clientName,
    required this.oldStart,
    required this.newStart,
    required this.reason,
    this.note = '',
  });

  @override
  State<RescheduleReviewScreen> createState() => _RescheduleReviewScreenState();
}

/// State of [RescheduleReviewScreen] — holds the screen data and logic.
class _RescheduleReviewScreenState extends State<RescheduleReviewScreen> {
  bool _sending = false;

  /// Sends the message.
  /// API: rescheduleService.requestAsArtist
  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ServiceLocator.rescheduleService.requestAsArtist(
        bookingId: widget.bookingId,
        oldStart: widget.oldStart,
        newStart: widget.newStart,
        reason: widget.reason,
        note: widget.note,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SunndariBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SunndariAppBar(onBack: _sending ? null : () => Navigator.of(context).pop(false)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: SunndariPageHeading(
                        title: 'Review Request',
                        subtitle: 'Check The New Time Before Sending It To Your Client.',
                      ),
                    ),
                    AiraCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Booking', style: AiraText.serif(fontSize: 17)),
                          const SizedBox(height: 4),
                          RescheduleInfoRow(icon: Icons.person_outline_rounded, label: 'Client', value: widget.clientName),
                          RescheduleInfoRow(icon: Icons.brush_outlined, label: 'Service', value: widget.serviceName),
                          RescheduleInfoRow(icon: Icons.location_on_outlined, label: 'Venue', value: widget.venueLabel, last: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AiraCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date & Time', style: AiraText.serif(fontSize: 17)),
                          const SizedBox(height: 10),
                          RescheduleCompareCard(
                            oldStart: widget.oldStart,
                            newStart: widget.newStart,
                            oldLabel: 'Current',
                            newLabel: 'Requested',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AiraCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reason', style: AiraText.serif(fontSize: 17)),
                          const SizedBox(height: 4),
                          RescheduleInfoRow(
                            icon: Icons.edit_note_rounded,
                            label: 'Reason For Reschedule',
                            value: widget.reason,
                            last: widget.note.isEmpty,
                          ),
                          if (widget.note.isNotEmpty)
                            RescheduleInfoRow(icon: Icons.notes_rounded, label: 'Note For Client', value: widget.note, last: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AiraCard(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: const Color(0xFFFFF6DD),
                      borderColor: AiraColors.warn,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: AiraColors.warn),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your Booking Stays At The Current Time Until The Client Accepts. '
                              'Applicable Charges, If Any, Are Shown Before Confirmation.',
                              style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoal, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: _sending ? 'Sending…' : 'Send Reschedule Request',
                      icon: Icons.send_rounded,
                      expand: true,
                      onTap: _sending ? null : _send,
                    ),
                    const SizedBox(height: 10),
                    GhostButton(
                      label: 'Edit Details',
                      icon: Icons.edit_outlined,
                      expand: true,
                      onTap: _sending ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
