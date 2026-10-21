// FILE: screens/grow_screen.dart
// SCREEN: Grow My Business — one card per growth tool (Share My Artist Page, Portfolio Showcase, Create Post, Reel, Recommend Product...).

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'beauty_screen.dart';
import 'insights_screen.dart';
import 'marketing_screen.dart';
import 'business_details_screen.dart';

/// SCREEN: Grow My Business — one card per growth tool (Share My Artist Page, Portfolio Showcase, Create Post, Reel, Recommend Product...).
class GrowScreen extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabSelect;
  final VoidCallback onPost;
  final VoidCallback onShare;

  const GrowScreen({
    super.key,
    required this.activeTab,
    required this.onTabSelect,
    required this.onPost,
    required this.onShare,
  });

  /// Opens the next screen.
  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  /// UI piece: page.
  Widget _page(BuildContext context, Widget child) => Scaffold(
        backgroundColor: AiraColors.bg,
        body: SunndariBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SunndariAppBar(onBack: () => Navigator.of(context).pop()),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      );

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return SunndariBackground(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SunndariTabHeader(title: 'Grow My Business'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AiraColors.blush,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AiraColors.pinkBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bar_chart_rounded, size: 15, color: AiraColors.roseDeep),
                    const SizedBox(width: 6),
                    Text('Growth Tools', style: AiraText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Makeup Artist To Beauty Entrepreneur.',
                style: AiraText.sans(fontSize: 14, color: AiraColors.charcoalSoft)),
          ),
          const SizedBox(height: 16),
          _card(
            icon: Icons.image_outlined,
            title: 'Create A Portfolio Showcase',
            body: 'Present Your Best Looks In One Place.',
            button: 'Choose Photos',
            buttonIcon: Icons.image_outlined,
            art: _PhotosArt(),
            onTap: () => _open(context, _page(context, const MarketingScreen())),
          ),
          _card(
            icon: Icons.bar_chart_rounded,
            title: 'Business Insights',
            body: 'Understand Bookings And Repeat Business.',
            button: 'View Insights',
            buttonIcon: Icons.bar_chart_rounded,
            art: _ChartArt(),
            onTap: () => _open(
              context,
              _page(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: SunndariPageHeading(title: 'Business Insights', subtitle: 'Understand Your Business At A Glance.'),
                    ),
                    Expanded(child: InsightsScreen(onNavigate: (target, [tab]) => Navigator.of(context).pop())),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: AiraCard(
              onTap: () => _open(context, const BusinessDetailsScreen(initialTab: 'portfolio')),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const SunndariIconBubble(icon: Icons.lightbulb_outline_rounded, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Next Step', style: AiraText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                        const SizedBox(height: 2),
                        Text('Keep Your Portfolio And Availability Updated.',
                            style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.35)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AiraColors.rose),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// UI piece: card.
  Widget _card({
    required IconData icon,
    required String title,
    required String body,
    required String button,
    required IconData buttonIcon,
    required Widget art,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: AiraCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
          child: Stack(
            children: [
              Positioned(right: 0, top: 0, bottom: 0, child: art),
              Padding(
                padding: const EdgeInsets.only(right: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SunndariIconBubble(icon: icon, size: 50),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 118),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: AiraText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AiraColors.roseDeep, height: 1.2)),
                                const SizedBox(height: 2),
                                Text(body, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft, height: 1.3)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.only(right: 118),
                      child: PrimaryButton(label: button, icon: buttonIcon, expand: true, onTap: onTap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Private Photos Art widget.
class _PhotosArt extends StatelessWidget {
  /// Builds the UI.
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 62,
                height: 74,
                decoration: BoxDecoration(color: AiraColors.rose.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 3)),
                child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 26),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 14,
              child: Transform.rotate(
                angle: 0.14,
                child: Container(
                  width: 50,
                  height: 56,
                  decoration: BoxDecoration(color: AiraColors.roseDeep.withOpacity(0.7), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 3)),
                  child: const Icon(Icons.brush_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Private Chart Art widget.
class _ChartArt extends StatelessWidget {
  /// Builds the UI.
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 112,
        child: Center(
          child: Container(
            width: 96,
            height: 88,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AiraColors.blush,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AiraColors.pinkBorder, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in const [22.0, 34.0, 28.0, 50.0])
                  Expanded(
                    child: Container(
                      height: h,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: AiraColors.rose, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.pie_chart_rounded, size: 26, color: AiraColors.pinkBorder),
              ],
            ),
          ),
        ),
      );
}
