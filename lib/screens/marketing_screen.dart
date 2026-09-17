import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../utils/app_feedback.dart';

class _Tile {
  final IconData icon;
  final String label;
  const _Tile(this.icon, this.label);
}

class MarketingScreen extends StatelessWidget {
  final VoidCallback onPost;
  const MarketingScreen({super.key, required this.onPost});

  @override
  Widget build(BuildContext context) {
    const tiles = [
      // _Tile(Icons.camera_alt_outlined, 'Instagram Post'),
      // _Tile(Icons.videocam_outlined, 'Reel'),
      _Tile(Icons.description_outlined, 'Caption'),
      _Tile(Icons.percent, 'Offer Poster'),
      _Tile(Icons.card_giftcard, 'Festive Campaign'),
      _Tile(Icons.people_outline, 'Brand Pitch'),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: tiles.map((t) {
              return AiraCard(
                padding: const EdgeInsets.all(10),
                onTap: () => AppFeedback.showInfo(context, "${t.label} generation isn't available yet"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: AiraColors.blush, borderRadius: BorderRadius.circular(16)),
                      child: Icon(t.icon, size: 17, color: AiraColors.roseDeep),
                    ),
                    const SizedBox(height: 12),
                    Text(t.label, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Generate in one tap', style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PREVIEW — DIWALI OFFER POST',
                  style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
              const SizedBox(height: 10),
              AiraCard(
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      alignment: Alignment.bottomLeft,
                      decoration: const BoxDecoration(gradient: AiraGradients.marketingPreview),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Diwali Glow Offer', style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                          Text('Flat 20% off bridal & party looks',
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
                            '✨ This Diwali, glow like never before. Book your festive look before 12 Nov and save 20%. Limited slots!',
                            style: AiraText.sans(fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: ['#DiwaliGlow', '#BridalMakeup', '#SunndariArtist']
                                .map((h) => Text(h, style: AiraText.sans(fontSize: 11.5, color: AiraColors.roseDeep)))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: PrimaryButton(label: 'Post Now', small: true, expand: true, onTap: onPost)),
                              const SizedBox(width: 8),
                              GhostButton(
                                label: 'Edit',
                                small: true,
                                onTap: () => AppFeedback.showInfo(context, "Editing tools aren't available yet"),
                              ),
                            ],
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
