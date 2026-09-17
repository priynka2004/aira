import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'marketing_screen.dart';
import 'beauty_screen.dart';

class GrowScreen extends StatelessWidget {
  final String activeTab; // marketing | beauty
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AiraColors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiraScreenHeader(title: 'Grow'),
            AiraSegTabs(
              tabs: const [
                SegTabItem('marketing', 'Marketing Studio'),
                SegTabItem('beauty', 'Beauty Consultation'),
              ],
              active: activeTab,
              onSelect: onTabSelect,
            ),
            Expanded(
              child: activeTab == 'beauty' ? BeautyScreen(onShare: onShare) : MarketingScreen(onPost: onPost),
            ),
          ],
        ),
      ),
    );
  }
}
