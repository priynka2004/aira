// FILE: screens/create_post_screen.dart
// SCREEN: Create Post — pick photo + occasion, generate caption, preview, share (local, no API).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';
import '../utils/app_feedback.dart';
import '../utils/api_logger.dart';
import '../utils/share_profile.dart';

/// SCREEN: Create Post — pick photo + occasion, generate caption, preview, share (local, no API).
class CreatePostScreen extends StatefulWidget {
  /// Which occasion chip starts selected (0 Everyday, 1 Bridal, 2 Festive, 3 Party, 4 New look).
  final int initialOccasion;
  const CreatePostScreen({super.key, this.initialOccasion = 0});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

/// Occasion.
class _Occasion {
  final String label;
  final String emoji;
  const _Occasion(this.label, this.emoji);
}

/// State of [CreatePostScreen] — holds the screen data and logic.
class _CreatePostScreenState extends State<CreatePostScreen> {
  bool _loadingPortfolio = true;
  String? _loadError;
  List<Portfolio> _portfolio = [];
  Portfolio? _selected;

  static const _occasions = [
    _Occasion('Everyday Glow', '✨'),
    _Occasion('Bridal', '💍'),
    _Occasion('Festive', '🎉'),
    _Occasion('Party', '🥂'),
    _Occasion('New Look', '💫'),
  ];
  static const _tones = ['Warm & Friendly', 'Bold & Confident', 'Elegant & Minimal'];

  int _occasionIndex = 0;
  int _toneIndex = 0;
  final _captionController = TextEditingController();
  bool _sharing = false;

  /// Runs once when the screen opens; starts: _loadPortfolio(), _regenerateCaption().
  @override
  void initState() {
    super.initState();
    _occasionIndex = widget.initialOccasion.clamp(0, _occasions.length - 1);
    _loadPortfolio();
    _regenerateCaption();
  }

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// Loads portfolio.
  Future<void> _loadPortfolio() async {
    try {
      final page = await ServiceLocator.artistService
          .getAllPortfolios(limit: 12, sortBy: 'createdAt', sortOrder: 'desc');
      final list = (page as dynamic).data as List<Portfolio>;
      if (!mounted) return;
      setState(() {
        _portfolio = list;
        _selected = list.isNotEmpty ? list.first : null;
        _loadingPortfolio = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loadingPortfolio = false;
      });
    }
  }

  static const _openers = {
    'Warm & Friendly': ['So Happy With How This Turned Out! 🥰', 'Had The Sweetest Time Creating This Look 💕'],
    'Bold & Confident': ['Unapologetically Glam. 🔥', 'This Is What Confidence Looks Like. 💄'],
    'Elegant & Minimal': ['Simple. Elegant. Timeless.', 'Less Is More, Always. ✨'],
  };
  static const _ctas = [
    'DM To Book Your Slot!',
    'Slots Filling Fast This Week — Message Me To Grab Yours.',
    'Tap The Link In Bio To Book.',
  ];
  static const _baseTags = ['#SunndariArtist', '#MakeupArtist', '#BeautyLook'];
  static const _occasionTags = {
    'Everyday Glow': ['#EverydayMakeup', '#NaturalGlow'],
    'Bridal': ['#BridalMakeup', '#WeddingSeason', '#BrideToBe'],
    'Festive': ['#FestiveLook', '#GlowUp'],
    'Party': ['#PartyMakeup', '#GlamLook'],
    'New Look': ['#Transformation', '#NewLook'],
  };

  /// Regenerates caption.
  void _regenerateCaption() {
    final occasion = _occasions[_occasionIndex];
    final tone = _tones[_toneIndex];
    final opener = _openers[tone]![occasion.label.hashCode.abs() % _openers[tone]!.length];
    final cta = _ctas[(occasion.label.length + tone.length) % _ctas.length];
    final tags = [..._baseTags, ...(_occasionTags[occasion.label] ?? [])];
    _captionController.text = '${occasion.emoji} $opener\n\n$cta\n\n${tags.join(' ')}';
  }

  /// Shares via the share sheet.
  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final text = await captionWithProfileLink(_captionController.text);
      final selected = _selected;
      final url = selected != null ? resolveMediaUrl(selected.fileUrl) : null;
      if (url != null) {
        final response = await ApiLog.get(Uri.parse(url), tag: 'HTTP/download');
        if (response.statusCode != 200) throw Exception("Couldn't Load This Photo To Share.");
        final dir = await getTemporaryDirectory();
        final ext = url.contains('.png') ? '.png' : '.jpg';
        final file = File('${dir.path}/post_preview$ext');
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: SunndariPageHeading(title: 'Create Post', subtitle: 'Pick A Look, Add A Caption And Share.'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loadingPortfolio
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : _loadError != null
                  ? AiraErrorState(message: _loadError!, onRetry: () {
                setState(() => _loadingPortfolio = true);
                _loadPortfolio();
              })
                  : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text('CHOOSE A PHOTO',
                      style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                  const SizedBox(height: 10),
                  if (_portfolio.isEmpty)
                    Text('No Portfolio Items Yet — Add Some From Settings → Portfolio.',
                        style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft))
                  else
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _portfolio.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final p = _portfolio[i];
                          final isSelected = p.portfolioId == _selected?.portfolioId;
                          final url = resolveMediaUrl(p.fileUrl);
                          return GestureDetector(
                            onTap: () => setState(() => _selected = p),
                            child: Container(
                              width: 84,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? AiraColors.rose : Colors.transparent, width: 2.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: url != null
                                    ? Image.network(url, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: AiraColors.blush))
                                    : Container(color: AiraColors.blush),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('OCCASION',
                      style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_occasions.length, (i) {
                      final selected = i == _occasionIndex;
                      return ChoiceChip(
                        label: Text('${_occasions[i].emoji} ${_occasions[i].label}'),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _occasionIndex = i;
                          _regenerateCaption();
                        }),
                        selectedColor: AiraColors.blush,
                        labelStyle: AiraText.sans(
                            fontSize: 12.5, color: selected ? AiraColors.roseDeep : AiraColors.charcoal),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text('TONE',
                      style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_tones.length, (i) {
                      final selected = i == _toneIndex;
                      return ChoiceChip(
                        label: Text(_tones[i]),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _toneIndex = i;
                          _regenerateCaption();
                        }),
                        selectedColor: AiraColors.blush,
                        labelStyle: AiraText.sans(
                            fontSize: 12.5, color: selected ? AiraColors.roseDeep : AiraColors.charcoal),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('CAPTION',
                          style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(_regenerateCaption),
                        child: Row(
                          children: [
                            const Icon(Icons.refresh, size: 14, color: AiraColors.roseDeep),
                            const SizedBox(width: 4),
                            Text('Regenerate', style: AiraText.sans(fontSize: 12, color: AiraColors.roseDeep)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AiraCard(
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 6,
                      style: AiraText.sans(fontSize: 13, height: 1.5),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _sharing ? 'Preparing…' : 'Share Post',
                    expand: true,
                    onTap: _sharing ? null : _share,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
