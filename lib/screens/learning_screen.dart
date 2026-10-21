// FILE: screens/learning_screen.dart
// SCREEN: Learning — course list (static content).

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../utils/app_feedback.dart';

/// Course.
class _Course {
  final String title;
  final String level;
  final String time;
  final IconData icon;
  const _Course(this.title, this.level, this.time, this.icon);
}

/// SCREEN: Learning — course list (static content).
class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    const courses = [
      _Course('Airbrush Bridal Techniques', 'Advanced', '45 min', Icons.menu_book_outlined),
      _Course('2026 Festive Makeup Trends', 'Trending', '20 min', Icons.star),
      _Course('Pricing Your Services Right', 'Business', '15 min', Icons.emoji_events_outlined),
    ];

    return Container(
      color: AiraColors.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AiraScreenHeader(title: 'Learning Coach'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AiraCard(
                gradient: AiraGradients.hero,
                borderWidth: 0,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RECOMMENDED FOR YOU', style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                    const SizedBox(height: 6),
                    Text('Courses And Tips For Artists Are Coming Soon.',
                        style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: courses
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AiraCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () => AppFeedback.showInfo(context, 'Courses Are Coming Soon'),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(color: AiraColors.blush, borderRadius: BorderRadius.circular(16)),
                                  child: Icon(c.icon, size: 18, color: AiraColors.roseDeep),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.title, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(c.level, style: AiraText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                                          const SizedBox(width: 8),
                                          Text('•', style: TextStyle(color: AiraColors.hair)),
                                          const SizedBox(width: 8),
                                          Text(c.time, style: AiraText.sans(fontSize: 11, color: AiraColors.charcoalSoft)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.play_arrow, size: 20, color: AiraColors.charcoalSoft),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
