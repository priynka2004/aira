import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';
import '../utils/app_feedback.dart';

/// Landing-page "Create Post" flow: pick a portfolio photo, pick an
/// occasion + tone, get a ready-to-edit caption with hashtags, preview it
/// like a real Instagram post, then share it out.
///
/// There's no AI copy-generation endpoint in the Sunndari API, so the
/// caption is built from real template + tag logic (deterministic, not a
/// model call) rather than faked as "AI-generated" — it's fully editable
/// before sharing either way.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _Occasion {
  final String label;
  final String emoji;
  const _Occasion(this.label, this.emoji);
}

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
  static const _tones = ['Warm & friendly', 'Bold & confident', 'Elegant & minimal'];

  int _occasionIndex = 0;
  int _toneIndex = 0;
  final _captionController = TextEditingController();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
    _regenerateCaption();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

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
    'Warm & friendly': ['So happy with how this turned out! 🥰', 'Had the sweetest time creating this look 💕'],
    'Bold & confident': ['Unapologetically glam. 🔥', 'This is what confidence looks like. 💄'],
    'Elegant & minimal': ['Simple. Elegant. Timeless.', 'Less is more, always. ✨'],
  };
  static const _ctas = [
    'DM to book your slot!',
    'Slots filling fast this week — message me to grab yours.',
    'Tap the link in bio to book.',
  ];
  static const _baseTags = ['#SunndariArtist', '#MakeupArtist', '#BeautyLook'];
  static const _occasionTags = {
    'Everyday Glow': ['#EverydayMakeup', '#NaturalGlow'],
    'Bridal': ['#BridalMakeup', '#WeddingSeason', '#BrideToBe'],
    'Festive': ['#FestiveLook', '#GlowUp'],
    'Party': ['#PartyMakeup', '#GlamLook'],
    'New Look': ['#Transformation', '#NewLook'],
  };

  void _regenerateCaption() {
    final occasion = _occasions[_occasionIndex];
    final tone = _tones[_toneIndex];
    final opener = _openers[tone]![occasion.label.hashCode.abs() % _openers[tone]!.length];
    final cta = _ctas[(occasion.label.length + tone.length) % _ctas.length];
    final tags = [..._baseTags, ...(_occasionTags[occasion.label] ?? [])];
    _captionController.text = '${occasion.emoji} $opener\n\n$cta\n\n${tags.join(' ')}';
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final selected = _selected;
      final url = selected != null ? resolveMediaUrl(selected.fileUrl) : null;
      if (url != null) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) throw Exception("Couldn't load this photo to share.");
        final dir = await getTemporaryDirectory();
        final ext = url.contains('.png') ? '.png' : '.jpg';
        final file = File('${dir.path}/post_preview$ext');
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
                  Expanded(child: Text('Create Post', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600))),
                ],
              ),
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
                    Text('No portfolio items yet — add some from Settings → Portfolio.',
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
