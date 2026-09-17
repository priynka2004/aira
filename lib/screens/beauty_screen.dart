import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../models/artist/artist_profile.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';
import 'portfolio_detail_screen.dart';

/// Client-facing "recommend a look" screen. There's no AI-matching or
/// selfie-analysis endpoint in the Sunndari API, so that part of the
/// original concept stays illustrative — but the look tiles now show the
/// artist's *real* portfolio, and the rating card shows their *real*
/// avgRating/totalReviews instead of a fixed "4.9 · 128 bookings".
class BeautyScreen extends StatefulWidget {
  final VoidCallback onShare;
  const BeautyScreen({super.key, required this.onShare});

  @override
  State<BeautyScreen> createState() => _BeautyScreenState();
}

class _BeautyScreenState extends State<BeautyScreen> {
  bool _loading = true;
  String? _error;
  ArtistProfile? _profile;
  List<Portfolio> _looks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ServiceLocator.artistService.getProfile(),
        ServiceLocator.artistService.getAllPortfolios(limit: 3, sortBy: 'createdAt', sortOrder: 'desc'),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as ArtistProfile;
        _looks = (results[1] as dynamic).data as List<Portfolio>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AiraErrorState(message: _error!, onRetry: _load);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AiraCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AiraColors.blush, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, size: 26, color: AiraColors.roseDeep),
                ),
                const SizedBox(height: 12),
                Text("Share your work with a client", style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Pick a recent look from your portfolio to send them',
                    textAlign: TextAlign.center,
                    style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR RECENT WORK',
                  style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose)),
                )
              else if (_looks.isEmpty)
                Text('No portfolio items yet — add some from Settings → Portfolio.',
                    style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft))
              else
                Row(
                  children: _looks.map((l) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: l == _looks.last ? 0 : 10),
                        child: AiraCard(
                          padding: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          onTap: () async {
                            final changed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(builder: (_) => PortfolioDetailScreen(portfolio: l)),
                            );
                            if (changed == true) _load();
                          },
                          child: Column(
                            children: [
                              SizedBox(
                                height: 90,
                                width: double.infinity,
                                child: Image.network(
                                  resolveMediaUrl(l.fileUrl) ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(decoration: const BoxDecoration(gradient: AiraGradients.beautyLookTile)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.mediaType, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                                    Text(l.caption?.isNotEmpty == true ? l.caption! : 'Untitled',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AiraText.sans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AiraCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(gradient: AiraGradients.avatarOrb, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your profile', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 11, color: AiraColors.gold),
                              const SizedBox(width: 4),
                              Text(
                                _loading
                                    ? 'Loading…'
                                    : '${(_profile?.avgRating ?? 0).toStringAsFixed(1)} · ${_profile?.totalReviews ?? 0} reviews',
                                style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Share this look with client',
                  small: true,
                  onTap: _looks.isEmpty ? null : widget.onShare,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
