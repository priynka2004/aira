import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../utils/notification_badge.dart';
import 'notifications_screen.dart';
import 'generate_reel_screen.dart';
import 'create_post_screen.dart';
import 'recommend_product_screen.dart';

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  const _StatItem(this.label, this.value, this.icon, this.trend);
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.label, this.onTap);
}

class HomeScreen extends StatelessWidget {
  /// target: 'business' | 'grow' | 'learn' | 'profile', tab: sub-tab key (optional)
  final void Function(String target, [String? tab]) onNavigate;
  final String artistName;
  final String dateLabel;
  final int bookingsToday;
  final double expectedEarningsToday;
  final int pendingConfirmations;
  final double avgRating;
  final String briefingText;
  final bool loading;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    this.artistName = '',
    this.dateLabel = '',
    this.bookingsToday = 0,
    this.expectedEarningsToday = 0,
    this.pendingConfirmations = 0,
    this.avgRating = 0,
    this.briefingText = '',
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('Bookings today', loading ? '—' : '$bookingsToday', Icons.calendar_today_outlined, null),
      _StatItem('Expected earnings', loading ? '—' : '₹${expectedEarningsToday.toStringAsFixed(0)}',
          Icons.currency_rupee, null),
      _StatItem('Pending confirmations', loading ? '—' : '$pendingConfirmations', Icons.access_time, null),
      _StatItem('Rating', loading ? '—' : avgRating.toStringAsFixed(1), Icons.star_outline, null),
    ];

    final actions = [
      _ActionItem(Icons.event_available_outlined, "Today's Bookings", () => onNavigate('business', 'booking')),
      // _ActionItem(Icons.videocam_outlined, 'Generate Reel',
      //     () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GenerateReelScreen()))),
      // _ActionItem(Icons.camera_alt_outlined, 'Create Post',
      //     () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()))),
      // _ActionItem(Icons.auto_awesome, 'Recommend Product',
      //     () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendProductScreen()))),
      _ActionItem(Icons.trending_up, 'Grow Business', () => onNavigate('business', 'insights')),
      _ActionItem(Icons.account_balance_wallet_outlined, 'Check Earnings', () => onNavigate('business', 'finance')),
      _ActionItem(Icons.calendar_today_outlined, 'Manage Bookings', () => onNavigate('business', 'booking')),
      _ActionItem(Icons.school_outlined, 'Learn Skills', () => onNavigate('learn')),
    ];

    return Container(
      color: AiraColors.bg,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLabel, style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft)),
                      const SizedBox(height: 2),
                      Text('Good morning${artistName.isNotEmpty ? ', $artistName' : ''} 🌸',
                          style: AiraText.serif(fontSize: 27, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AiraColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AiraColors.hair),
                        ),
                        child: const Icon(Icons.notifications_outlined, size: 20, color: AiraColors.charcoal),
                      ),
                      // Green dot — shown as soon as a push/unread
                      // notification exists, cleared as soon as the user
                      // opens the notifications list.
                      Positioned(
                        top: 1,
                        right: 1,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: NotificationBadge.instance.hasUnread,
                          builder: (context, hasUnread, _) {
                            if (!hasUnread) return const SizedBox.shrink();
                            return Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: AiraColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: AiraColors.bg, width: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Briefing hero
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AiraCard(
              gradient: AiraGradients.hero,
              borderWidth: 0,
              padding: const EdgeInsets.all(20),
              onTap: () => onNavigate('business', 'booking'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AiraColors.gold, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('MORNING BRIEFING',
                          style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.roseDeep, letterSpacing: 0.3)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loading
                        ? 'Loading your morning briefing…'
                        : (briefingText.isNotEmpty
                            ? briefingText
                            : "You're all clear — no bookings on the calendar today."),
                    style: AiraText.serif(fontSize: 17, fontWeight: FontWeight.w500, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View full briefing', style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14, color: AiraColors.roseDeep),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stat grid
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: stats.map((s) {
                return AiraCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(s.icon, size: 17, color: AiraColors.rose),
                      const SizedBox(height: 8),
                      Text(s.value, style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.label,
                                style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (s.trend != null)
                            Text(s.trend!, style: AiraText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.success)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Suggested action
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: AiraCard(
              padding: const EdgeInsets.all(16),
              borderColor: AiraColors.goldSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AiraColors.goldSoft, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.card_giftcard, size: 18, color: AiraColors.roseDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tomorrow is wide open', style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Send a festive offer to fill it before evening.',
                            style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft)),
                        const SizedBox(height: 12),
                        PrimaryButton(label: 'Create Offer', small: true, onTap: () => onNavigate('grow', 'marketing')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions grid
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WHAT WOULD YOU LIKE TO DO?',
                    style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: actions.map((a) {
                    return AiraCard(
                      padding: const EdgeInsets.all(10),
                      onTap: a.onTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: AiraColors.blush, borderRadius: BorderRadius.circular(16)),
                            child: Icon(a.icon, size: 16, color: AiraColors.roseDeep),
                          ),
                          const SizedBox(height: 10),
                          Text(a.label,
                              style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
