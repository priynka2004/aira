import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';
import '../utils/app_feedback.dart';

/// Landing-page "Generate Reel" flow: pick a handful of portfolio photos,
/// preview them as an auto-advancing slideshow with a caption, then share
/// the cover photo + caption out.
///
/// There's no video-rendering endpoint in the Sunndari API (and stitching
/// a real .mp4 client-side is out of scope for this app), so "reel" here
/// means a real, working in-app slideshow preview — not a fake spinner
/// that produces nothing. Sharing exports the cover image + caption,
/// which is enough to hand off to Instagram's own Reel composer.
class GenerateReelScreen extends StatefulWidget {
  const GenerateReelScreen({super.key});

  @override
  State<GenerateReelScreen> createState() => _GenerateReelScreenState();
}

class _Vibe {
  final String label;
  final String emoji;
  const _Vibe(this.label, this.emoji);
}

class _GenerateReelScreenState extends State<GenerateReelScreen> {
  bool _loading = true;
  String? _loadError;
  List<Portfolio> _portfolio = [];
  final Set<int> _selectedIds = {};

  static const _vibes = [
    _Vibe('Glow transformation', '✨'),
    _Vibe('Behind the scenes', '🎬'),
    _Vibe('Before & after', '🔁'),
    _Vibe('Client reactions', '💬'),
  ];
  int _vibeIndex = 0;
  final _captionController = TextEditingController(text: '');

  bool _previewing = false;
  int _previewIndex = 0;
  Timer? _previewTimer;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final page = await ServiceLocator.artistService
          .getAllPortfolios(limit: 20, sortBy: 'createdAt', sortOrder: 'desc');
      final list = (page as dynamic).data as List<Portfolio>;
      if (!mounted) return;
      setState(() {
        _portfolio = list;
        _selectedIds.addAll(list.take(4).map((p) => p.portfolioId));
        _loading = false;
      });
      _updateCaption();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _updateCaption() {
    final vibe = _vibes[_vibeIndex];
    _captionController.text =
    '${vibe.emoji} ${vibe.label} ✨\n\nSwipe through the transformation! Book your look with me 💕\n\n#SunndariArtist #ReelIt #MakeupReel';
  }

  List<Portfolio> get _selected =>
      _portfolio.where((p) => _selectedIds.contains(p.portfolioId)).toList();

  void _toggle(int portfolioId) {
    setState(() {
      if (_selectedIds.contains(portfolioId)) {
        _selectedIds.remove(portfolioId);
      } else if (_selectedIds.length < 8) {
        _selectedIds.add(portfolioId);
      } else {
        AppFeedback.showWarning(context, 'Pick up to 8 photos for a reel');
      }
    });
  }

  void _startPreview() {
    if (_selected.isEmpty) {
      AppFeedback.showWarning(context, 'Select at least one photo first');
      return;
    }
    setState(() {
      _previewing = true;
      _previewIndex = 0;
    });
    _previewTimer?.cancel();
    _previewTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() => _previewIndex = (_previewIndex + 1) % _selected.length);
    });
  }

  void _stopPreview() {
    _previewTimer?.cancel();
    setState(() => _previewing = false);
  }

  Future<void> _share() async {
    if (_selected.isEmpty) return;
    setState(() => _sharing = true);
    try {
      final url = resolveMediaUrl(_selected.first.fileUrl);
      if (url != null) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) throw Exception("Couldn't load the cover photo to share.");
        final dir = await getTemporaryDirectory();
        final ext = url.contains('.png') ? '.png' : '.jpg';
        final file = File('${dir.path}/reel_cover$ext');
        await file.writeAsBytes(response.bodyBytes);
        if (!mounted) return;
        await Share.shareXFiles([XFile(file.path)], text: _captionController.text);
      } else {
        await Share.share(_captionController.text);
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Generate Reel', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : _loadError != null
                  ? AiraErrorState(message: _loadError!, onRetry: () {
                setState(() => _loading = true);
                _load();
              })
                  : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  if (_previewing) ...[
                    _reelPreview(),
                    const SizedBox(height: 12),
                    GhostButton(label: 'Edit selection', small: false, onTap: _stopPreview),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text('SELECT PHOTOS (up to 8)',
                        style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                    const SizedBox(height: 10),
                    if (_portfolio.isEmpty)
                      Text('No portfolio items yet — add some from Settings → Portfolio.',
                          style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft))
                    else
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: _portfolio.map((p) {
                          final selected = _selectedIds.contains(p.portfolioId);
                          final url = resolveMediaUrl(p.fileUrl);
                          return GestureDetector(
                            onTap: () => _toggle(p.portfolioId),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: url != null
                                        ? Image.network(url, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: AiraColors.blush))
                                        : Container(color: AiraColors.blush),
                                  ),
                                ),
                                if (selected)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AiraColors.rose, width: 3),
                                        color: AiraColors.rose.withValues(alpha: 0.12),
                                      ),
                                      alignment: Alignment.topRight,
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.check_circle, size: 18, color: AiraColors.rose),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                    Text('VIBE',
                        style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_vibes.length, (i) {
                        final selected = i == _vibeIndex;
                        return ChoiceChip(
                          label: Text('${_vibes[i].emoji} ${_vibes[i].label}'),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _vibeIndex = i;
                            _updateCaption();
                          }),
                          selectedColor: AiraColors.blush,
                          labelStyle: AiraText.sans(
                              fontSize: 12.5, color: selected ? AiraColors.roseDeep : AiraColors.charcoal),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Preview Reel', expand: true, onTap: _startPreview),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reelPreview() {
    final selected = _selected;
    final current = selected.isNotEmpty ? selected[_previewIndex % selected.length] : null;
    final url = current != null ? resolveMediaUrl(current.fileUrl) : null;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 9 / 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                url != null
                    ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AiraColors.blush))
                    : Container(color: AiraColors.blush),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: List.generate(selected.length, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _previewIndex ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Text(
                    _captionController.text.split('\n').first,
                    style: AiraText.sans(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AiraCard(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _captionController,
            maxLines: 4,
            style: AiraText.sans(fontSize: 13, height: 1.5),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _sharing ? 'Preparing…' : 'Share Reel Cover',
          expand: true,
          onTap: _sharing ? null : _share,
        ),
      ],
    );
  }
}
