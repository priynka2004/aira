// FILE: screens/marketing_screen.dart
// SCREEN: Marketing Studio — tools to promote the artist (caption/post, festive campaign, reel, brand pitch).
// Every tile opens a real, working screen (no "coming soon" dead-ends).

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../utils/share_profile.dart';
import 'create_post_screen.dart';
import 'generate_reel_screen.dart';

/// One studio tool tile.
class _Tool {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback Function(BuildContext) action;
  const _Tool(this.icon, this.title, this.subtitle, this.action);
}

/// SCREEN: Marketing Studio.
class MarketingScreen extends StatelessWidget {
  /// Kept only so older callers still compile; Post/Edit now open Create Post directly.
  final VoidCallback? onPost;
  const MarketingScreen({super.key, this.onPost});

  void _post(BuildContext context, int occasion) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => CreatePostScreen(initialOccasion: occasion)));

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final tools = <_Tool>[
      _Tool(Icons.edit_note_rounded, 'Caption', 'Photo + Ready Caption', (c) => () => _post(c, 0)),
      _Tool(Icons.celebration_outlined, 'Festive Campaign', 'Diwali, Eid, Wedding Season', (c) => () => _post(c, 2)),
      _Tool(Icons.movie_creation_outlined, 'Reel', 'Slideshow Of Your Looks', (c) => () => Navigator.of(c)
          .push(MaterialPageRoute(builder: (_) => const GenerateReelScreen()))),
      _Tool(Icons.ios_share_rounded, 'Brand Pitch', 'Share Your Artist Page', (c) => () => shareArtistProfile(c)),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: SunndariPageHeading(title: 'Marketing Studio', subtitle: 'Create Posts That Bring In Bookings.'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final t in tools)
                AiraCard(
                  padding: const EdgeInsets.all(12),
                  onTap: t.action(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SunndariIconBubble(icon: t.icon, size: 40),
                      const SizedBox(height: 10),
                      Text(t.title,
                          style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                      const SizedBox(height: 2),
                      Text(t.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft, height: 1.3)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAMPLE PREVIEW (EXAMPLE ONLY)',
                  style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
              const SizedBox(height: 10),
              AiraCard(
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 170,
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      alignment: Alignment.bottomLeft,
                      decoration: const BoxDecoration(gradient: AiraGradients.marketingPreview),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Diwali Glow Offer',
                              style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                          Text('Flat 20% Off Bridal & Party Looks',
                              style: AiraText.sans(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✨ This Diwali, Glow Like Never Before. Book Your Festive Look Early And Save 20%. Limited Slots!',
                            style: AiraText.sans(fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: ['#DiwaliGlow', '#BridalMakeup', '#SunndariArtist']
                                .map((h) => Text(h, style: AiraText.sans(fontSize: 11.5, color: AiraColors.roseDeep)))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Create Your Own Post',
                            icon: Icons.add_photo_alternate_outlined,
                            small: true,
                            expand: true,
                            onTap: () => _post(context, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
