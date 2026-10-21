// FILE: widgets/reschedule_widgets.dart
// WIDGETS: compare card, info row and pill used on reschedule screens.

import 'package:flutter/material.dart';
import '../models/booking/booking_reschedule.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Reschedule Compare Card widget.
class RescheduleCompareCard extends StatelessWidget {
  final DateTime oldStart;
  final DateTime newStart;
  final String oldLabel;
  final String newLabel;

  const RescheduleCompareCard({
    super.key,
    required this.oldStart,
    required this.newStart,
    this.oldLabel = 'Current',
    this.newLabel = 'New',
  });

  /// UI piece: col.
  Widget _col(String label, DateTime d, {required bool highlight}) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight ? AiraColors.blush : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: highlight ? AiraColors.pinkBorder : AiraColors.hair),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AiraText.sans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: highlight ? AiraColors.rose : AiraColors.charcoalSoft)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AiraColors.rose),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(RescheduleFmt.date(d),
                      style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AiraColors.rose),
                const SizedBox(width: 6),
                Text(RescheduleFmt.time(d),
                    style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
              ]),
              const SizedBox(height: 4),
              Text(RescheduleFmt.dateLong(d).split(',').first,
                  style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
            ],
          ),
        ),
      );

  /// Builds the UI.
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _col(oldLabel, oldStart, highlight: false),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded, size: 20, color: AiraColors.rose),
          ),
          _col(newLabel, newStart, highlight: true),
        ],
      );
}

/// Reschedule Info Row widget.
class RescheduleInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const RescheduleInfoRow({super.key, required this.icon, required this.label, required this.value, this.last = false});

  /// Builds the UI.
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AiraColors.hair))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SunndariIconBubble(icon: icon, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                  const SizedBox(height: 2),
                  Text(value, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Reschedule Pill widget.
class ReschedulePill extends StatelessWidget {
  final String text;
  const ReschedulePill(this.text, {super.key});

  /// Builds the UI.
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AiraColors.goldSoft, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: AiraText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF8A6A1F))),
      );
}
