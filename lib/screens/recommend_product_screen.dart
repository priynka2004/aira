// FILE: screens/recommend_product_screen.dart
// SCREEN: Recommend Product — pick beauty products for a client and share the list (local catalog).

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../utils/app_feedback.dart';

/// SCREEN: Recommend Product — pick beauty products for a client and share the list (local catalog).
class RecommendProductScreen extends StatefulWidget {
  const RecommendProductScreen({super.key});

  @override
  State<RecommendProductScreen> createState() => _RecommendProductScreenState();
}

/// Product.
class _Product {
  final String name;
  final String brand;
  final String category;
  final String forConcern;
  const _Product(this.name, this.brand, this.category, this.forConcern);
}

/// State of [RecommendProductScreen] — holds the screen data and logic.
class _RecommendProductScreenState extends State<RecommendProductScreen> {
  static const _catalog = [
    _Product('Hydrating Primer', 'Lakmé', 'Skin Prep', 'Dry Skin, Dull Look'),
    _Product('Mattifying Primer', 'MAC', 'Skin Prep', 'Oily Skin, Long Wear'),
    _Product('Foundation Stick', 'NARS', 'Base', 'Even Coverage, Glow Finish'),
    _Product('Cushion Foundation', 'Lakmé', 'Base', 'Light Everyday Coverage'),
    _Product('Setting Powder', 'Laura Mercier', 'Base', 'Oily T-Zone, Humidity'),
    _Product('Concealer', 'NARS', 'Base', 'Under-Eye, Blemish Coverage'),
    _Product('Eyeshadow Palette', 'Huda Beauty', 'Eyes', 'Bridal, Festive Looks'),
    _Product('Kohl Eyeliner', 'Lakmé', 'Eyes', 'Everyday Definition'),
    _Product('Waterproof Mascara', 'Maybelline', 'Eyes', 'Long Ceremonies, Tears-Proof'),
    _Product('Matte Lipstick', 'MAC', 'Lips', 'Bold Party Look'),
    _Product('Tinted Lip Balm', 'Nykaa', 'Lips', 'Natural Everyday Look'),
    _Product('Setting Spray', 'Urban Decay', 'Finish', 'All-Day, Humidity-Proof Wear'),
    _Product('Highlighter', 'Fenty Beauty', 'Finish', 'Glow For Photos'),
    _Product('Makeup Remover Wipes', 'Simple', 'Aftercare', 'Gentle End-Of-Day Removal'),
  ];

  String? _categoryFilter;
  final Set<String> _selected = {};
  final _noteController = TextEditingController();

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _categories => _catalog.map((p) => p.category).toSet().toList();

  List<_Product> get _visible =>
      _categoryFilter == null ? _catalog : _catalog.where((p) => p.category == _categoryFilter).toList();

  /// Shares via the share sheet.
  Future<void> _share() async {
    if (_selected.isEmpty) {
      AppFeedback.showWarning(context, 'Pick At Least One Product First');
      return;
    }
    final picked = _catalog.where((p) => _selected.contains(p.name)).toList();
    final buffer = StringBuffer('✨ Here Are My Product Picks For You:\n\n');
    for (final p in picked) {
      buffer.writeln('• ${p.name} (${p.brand}) — Great For ${p.forConcern}');
    }
    if (_noteController.text.trim().isNotEmpty) {
      buffer.writeln('\n${_noteController.text.trim()}');
    }
    buffer.write('\n— Recommended via Sunndari');
    await Share.share(buffer.toString());
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
                  const Expanded(child: SunndariPageHeading(title: 'Recommend Product', subtitle: 'Pick Products To Suggest To Your Client.')),
                  if (_selected.isNotEmpty) AiraPill(label: '${_selected.length} selected', active: true),
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
                              Text('Best For: ${p.forConcern}',
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
                        hintText: 'Add A Personal Note For Your Client (Optional)',
                        hintStyle: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Share With Client', expand: true, onTap: _share),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// UI piece: category chip.
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
