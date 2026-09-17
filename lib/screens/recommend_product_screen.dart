import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../utils/app_feedback.dart';

/// Landing-page "Recommend Product" flow: browse a curated beauty-product
/// catalog by category, pick a few for a client, add a personal note, and
/// share the recommendation list with them.
///
/// There's no product-catalog endpoint in the Sunndari API, so this uses a
/// hand-picked reference catalog (real, well-known product lines rather
/// than placeholder text) — swap [_catalog] for a live call once a
/// products endpoint exists; nothing else about this screen would need to
/// change.
class RecommendProductScreen extends StatefulWidget {
  const RecommendProductScreen({super.key});

  @override
  State<RecommendProductScreen> createState() => _RecommendProductScreenState();
}

class _Product {
  final String name;
  final String brand;
  final String category;
  final String forConcern;
  const _Product(this.name, this.brand, this.category, this.forConcern);
}

class _RecommendProductScreenState extends State<RecommendProductScreen> {
  static const _catalog = [
    _Product('Hydrating Primer', 'Lakmé', 'Skin Prep', 'Dry skin, dull look'),
    _Product('Mattifying Primer', 'MAC', 'Skin Prep', 'Oily skin, long wear'),
    _Product('Foundation Stick', 'NARS', 'Base', 'Even coverage, glow finish'),
    _Product('Cushion Foundation', 'Lakmé', 'Base', 'Light everyday coverage'),
    _Product('Setting Powder', 'Laura Mercier', 'Base', 'Oily T-zone, humidity'),
    _Product('Concealer', 'NARS', 'Base', 'Under-eye, blemish coverage'),
    _Product('Eyeshadow Palette', 'Huda Beauty', 'Eyes', 'Bridal, festive looks'),
    _Product('Kohl Eyeliner', 'Lakmé', 'Eyes', 'Everyday definition'),
    _Product('Waterproof Mascara', 'Maybelline', 'Eyes', 'Long ceremonies, tears-proof'),
    _Product('Matte Lipstick', 'MAC', 'Lips', 'Bold party look'),
    _Product('Tinted Lip Balm', 'Nykaa', 'Lips', 'Natural everyday look'),
    _Product('Setting Spray', 'Urban Decay', 'Finish', 'All-day, humidity-proof wear'),
    _Product('Highlighter', 'Fenty Beauty', 'Finish', 'Glow for photos'),
    _Product('Makeup Remover Wipes', 'Simple', 'Aftercare', 'Gentle end-of-day removal'),
  ];

  String? _categoryFilter;
  final Set<String> _selected = {};
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _categories => _catalog.map((p) => p.category).toSet().toList();

  List<_Product> get _visible =>
      _categoryFilter == null ? _catalog : _catalog.where((p) => p.category == _categoryFilter).toList();

  Future<void> _share() async {
    if (_selected.isEmpty) {
      AppFeedback.showWarning(context, 'Pick at least one product first');
      return;
    }
    final picked = _catalog.where((p) => _selected.contains(p.name)).toList();
    final buffer = StringBuffer('✨ Here are my product picks for you:\n\n');
    for (final p in picked) {
      buffer.writeln('• ${p.name} (${p.brand}) — great for ${p.forConcern}');
    }
    if (_noteController.text.trim().isNotEmpty) {
      buffer.writeln('\n${_noteController.text.trim()}');
    }
    buffer.write('\n— Recommended via Sunndari');
    await Share.share(buffer.toString());
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
                  Expanded(child: Text('Recommend Product', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600))),
                  if (_selected.isNotEmpty)
                    AiraPill(label: '${_selected.length} selected', active: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _categoryChip(null, 'All'),
                    ..._categories.map((c) => _categoryChip(c, c)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                itemCount: _visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = _visible[i];
                  final selected = _selected.contains(p.name);
                  return AiraCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => setState(() {
                      if (selected) {
                        _selected.remove(p.name);
                      } else {
                        _selected.add(p.name);
                      }
                    }),
                    child: Row(
                      children: [
                        Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                            color: selected ? AiraColors.rose : AiraColors.hair, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p.name} · ${p.brand}',
                                  style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Best for: ${p.forConcern}',
                                  style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                            ],
                          ),
                        ),
                        AiraPill(label: p.category, active: false),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AiraCard(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: AiraText.sans(fontSize: 13),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add a personal note for your client (optional)',
                        hintStyle: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Share with Client', expand: true, onTap: _share),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final selected = _categoryFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _categoryFilter = value),
        selectedColor: AiraColors.blush,
        labelStyle: AiraText.sans(fontSize: 12.5, color: selected ? AiraColors.roseDeep : AiraColors.charcoal),
      ),
    );
  }
}
