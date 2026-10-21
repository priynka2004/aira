// FILE: screens/changes_required_screen.dart
// SCREEN: Changes Required — admin asked for edits to the artist page; resubmit when all done.

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Review Change.
class ReviewChange {
  final String title;
  final String body;
  final IconData icon;
  final String actionLabel;
  final VoidCallback? onAction;
  const ReviewChange({
    required this.title,
    required this.body,
    required this.icon,
    required this.actionLabel,
    this.onAction,
  });
}

/// SCREEN: Changes Required — admin asked for edits to the artist page; resubmit when all done.
class ChangesRequiredScreen extends StatefulWidget {
  final List<ReviewChange> changes;
  final VoidCallback? onResubmit;
  final VoidCallback? onContactSupport;

  const ChangesRequiredScreen({
    super.key,
    required this.changes,
    this.onResubmit,
    this.onContactSupport,
  });

  @override
  State<ChangesRequiredScreen> createState() => _ChangesRequiredScreenState();
}

/// State of [ChangesRequiredScreen] — holds the screen data and logic.
class _ChangesRequiredScreenState extends State<ChangesRequiredScreen> {
  final Set<int> _done = {};

  Future<void> _run(int i) async {
    widget.changes[i].onAction?.call();
    if (mounted) setState(() => _done.add(i));
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final total = widget.changes.length;
    final done = _done.length;
    final ready = total > 0 && done == total;

    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SunndariBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SunndariAppBar(onBack: () => Navigator.of(context).pop()),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: SunndariPageHeading(
                            title: 'Changes Required',
                            subtitle: 'Please Update The Highlighted Details And Resubmit.',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AiraColors.blush,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AiraColors.pinkBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 14, color: AiraColors.rose),
                              const SizedBox(width: 4),
                              Text('Action Needed',
                                  style: AiraText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.rose)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AiraColors.blush,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AiraColors.pinkBorder),
                        ),
                        child: Text('Artist Page Review',
                            style: AiraText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AiraCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('$done Of $total Updates Completed',
                                    style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                              ),
                              Text('${total == 0 ? 0 : (done * 100 / total).round()}%',
                                  style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : done / total,
                              minHeight: 8,
                              backgroundColor: AiraColors.blush,
                              valueColor: const AlwaysStoppedAnimation(AiraColors.rose),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: AiraColors.charcoalSoft),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your Current Approved Page Remains Live While Changes Are Reviewed.',
                                  style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Review Feedback', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    for (var i = 0; i < widget.changes.length; i++) _changeCard(i),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Resubmit For Review',
                      icon: Icons.send_rounded,
                      expand: true,
                      onTap: ready ? widget.onResubmit : null,
                    ),
                    if (!ready) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text('Complete The Requested Updates First.',
                            style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(color: AiraColors.hair),
                    Center(
                      child: TextButton.icon(
                        onPressed: widget.onContactSupport,
                        icon: const Icon(Icons.headset_mic_outlined, size: 18, color: AiraColors.rose),
                        label: Text('Contact Support  ›',
                            style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AiraColors.rose)),
                      ),
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

  /// UI: changes card.
  Widget _changeCard(int i) {
    final c = widget.changes[i];
    final done = _done.contains(i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AiraCard(
        padding: const EdgeInsets.all(14),
        borderColor: done ? AiraColors.success : AiraColors.hair,
        child: Row(
          children: [
            SunndariIconBubble(icon: done ? Icons.check_rounded : c.icon, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title, style: AiraText.sans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                  const SizedBox(height: 2),
                  Text(c.body, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            PrimaryButton(label: done ? 'Done' : c.actionLabel, small: true, onTap: () => _run(i)),
          ],
        ),
      ),
    );
  }
}
