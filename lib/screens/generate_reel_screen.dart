// FILE: screens/generate_reel_screen.dart
// SCREEN: Generate Reel — slideshow preview of portfolio photos + caption, share (local, no API).

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/share_profile.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';
import '../utils/app_feedback.dart';
import '../utils/api_logger.dart';

/// SCREEN: Generate Reel — slideshow preview of portfolio photos + caption, share (local, no API).
class GenerateReelScreen extends StatefulWidget {
  const GenerateReelScreen({super.key});

  @override
  State<GenerateReelScreen> createState() => _GenerateReelScreenState();
}

/// Vibe.
class _Vibe {
  final String label;
  final String emoji;
  const _Vibe(this.label, this.emoji);
}

/// State of [GenerateReelScreen] — holds the screen data and logic.
class _GenerateReelScreenState extends State<GenerateReelScreen> {
  bool _loading = true;
  String? _loadError;
  List<Portfolio> _portfolio = [];
  final Set<int> _selectedIds = {};

  static const _vibes = [
    _Vibe('Glow Transformation', '✨'),
    _Vibe('Behind The Scenes', '🎬'),
    _Vibe('Before & After', '🔁'),
    _Vibe('Client Reactions', '💬'),
  ];
  int _vibeIndex = 0;
  final _captionController = TextEditingController(text: '');

  bool _previewing = false;
  int _previewIndex = 0;
  Timer? _previewTimer;
  bool _sharing = false;

  /// Runs once when the screen opens; starts: _load().
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _previewTimer?.cancel();
    _captionController.dispose();
    super.dispose();
  }

  /// Loads this screen's data.
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

  /// Updates caption.
  void _updateCaption() {
    final vibe = _vibes[_vibeIndex];
    _captionController.text =
    '${vibe.emoji} ${vibe.label} ✨\n\nSwipe Through The Transformation! Book Your Look With Me 💕\n\n#SunndariArtist #ReelIt #MakeupReel';
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
        AppFeedback.showWarning(context, 'Pick Up To 8 Photos For A Reel');
      }
    });
  }

  /// Starts preview.
  void _startPreview() {
    if (_selected.isEmpty) {
      AppFeedback.showWarning(context, 'Select At Least One Photo First');
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

  /// Stops preview.
  void _stopPreview() {
    _previewTimer?.cancel();
    setState(() => _previewing = false);
  }

  /// Shares via the share sheet.
  Future<void> _share() async {
    if (_selected.isEmpty) return;
    setState(() => _sharing = true);
    try {
      final text = await captionWithProfileLink(_captionController.text);
      final url = resolveMediaUrl(_selected.first.fileUrl);
      if (url != null) {
        final response = await ApiLog.get(Uri.parse(url), tag: 'HTTP/download');
        if (response.statusCode != 200) throw Exception("Couldn't Load The Cover Photo To Share.");
        final dir = await getTemporaryDirectory();
        final ext = url.contains('.png') ? '.png' : '.jpg';
        final file = File('${dir.path}/reel_cover$ext');
        await file.writeAsBytes(response.bodyBytes);
        if (!mounted) return;
        await Share.shareXFiles([XFile(file.path)], text: text);
      } else {
        await Share.share(text);
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SunndariAppBar(onBack: () => Navigator.of(context).pop()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  const Expanded(child: SunndariPageHeading(title: 'Generate Reel', subtitle: 'Turn Your Best Looks Into A Slideshow.')),
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
                    GhostButton(label: 'Edit Selection', small: false, onTap: _stopPreview),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text('SELECT PHOTOS (Up To 8)',
                        style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                    const SizedBox(height: 10),
                    if (_portfolio.isEmpty)
                      Text('No Portfolio Items Yet — Add Some From Settings → Portfolio.',
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

  /// UI piece: reel preview.
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
