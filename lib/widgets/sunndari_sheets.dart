// FILE: widgets/sunndari_sheets.dart
// WIDGETS: select field + bottom sheets (single choice, multi choice, duration).

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Sunndari Select Field widget.
class SunndariSelectField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final String? optionalTag;
  final String? helper;
  final IconData? leading;
  final bool bottomPadding;

  const SunndariSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
    this.value,
    this.optionalTag,
    this.helper,
    this.leading,
    this.bottomPadding = true,
  });

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding ? 14 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label, style: AiraText.serif(fontSize: 15.5, fontWeight: FontWeight.w700)),
              if (optionalTag != null) ...[
                const SizedBox(width: 8),
                Text(optionalTag!, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
              ],
            ],
          ),
          if (label.isNotEmpty) const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: AiraColors.pinkFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AiraColors.pinkBorder, width: 1.1),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    Icon(leading, size: 18, color: AiraColors.rose),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      filled ? value! : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AiraText.sans(
                        fontSize: 13.5,
                        color: filled ? AiraColors.charcoal : AiraColors.charcoalSoft.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AiraColors.roseDeep),
                ],
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 5),
            Text(helper!, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
          ],
        ],
      ),
    );
  }
}

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder, {bool full = false}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AiraColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * (full ? 0.92 : 0.8)),
    builder: builder,
  );
}

/// UI piece: sheet header.
Widget _sheetHeader(BuildContext ctx, String title, String? subtitle, {bool centered = false}) => Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            decoration: BoxDecoration(color: AiraColors.pinkBorder, borderRadius: BorderRadius.circular(99)),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(title, style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft)),
                  ],
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close_rounded, color: AiraColors.roseDeep),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );

/// Ask text.
Future<String?> _askText(BuildContext context, String title, String hint) async {
  final c = TextEditingController();
  final v = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AiraColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: AiraText.serif(fontSize: 19)),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
          child: Text('Add', style: AiraText.sans(fontWeight: FontWeight.w700, color: AiraColors.rose)),
        ),
      ],
    ),
  );

  return (v == null || v.isEmpty) ? null : v;
}

/// Shows sunndari choice sheet.
Future<String?> showSunndariChoiceSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<String> options,
  String? selected,
  String? otherSubtitle,
  bool boxed = false,
  bool centeredTitle = false,
}) {
  return _showSheet<String>(context, (ctx) {
    Widget row(String label, {String? sub, required VoidCallback onTap, required bool on}) {
      final content = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                if (sub != null) Text(sub, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
              ],
            ),
          ),
          Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, size: 22, color: AiraColors.rose),
        ],
      );
      return InkWell(
        onTap: onTap,
        child: Container(
          margin: boxed ? const EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
          padding: EdgeInsets.symmetric(horizontal: boxed ? 14 : 0, vertical: boxed ? 13 : 12),
          decoration: boxed
              ? BoxDecoration(
                  color: AiraColors.pinkFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: on ? AiraColors.rose : AiraColors.pinkBorder, width: on ? 1.5 : 1.1),
                )
              : const BoxDecoration(border: Border(bottom: BorderSide(color: AiraColors.pinkBorder, width: 0.8))),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetHeader(ctx, title, subtitle, centered: centeredTitle),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final o in options)
                    row(o, on: selected == o, onTap: () => Navigator.of(ctx).pop(o)),
                  if (otherSubtitle != null)
                    row('Other', sub: otherSubtitle, on: selected != null && !options.contains(selected), onTap: () async {
                      final v = await _askText(ctx, title, otherSubtitle);
                      if (v != null && ctx.mounted) Navigator.of(ctx).pop(v);
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  });
}

const _durationPresets = <(String, int)>[
  ('30 minutes', 30),
  ('1 hour', 60),
  ('1 Hour 30 Minutes', 90),
  ('2 hours', 120),
  ('2 Hours 30 Minutes', 150),
  ('3 hours', 180),
];

/// Shows sunndari duration sheet.
Future<int?> showSunndariDurationSheet(BuildContext context, {int? initial}) {
  return _showSheet<int>(context, (ctx) {
    int? picked = initial;
    bool custom = initial != null && !_durationPresets.any((p) => p.$2 == initial);
    final hCtrl = TextEditingController(text: custom ? '${initial! ~/ 60}' : '');
    final mCtrl = TextEditingController(text: custom ? '${initial! % 60}' : '');
    String? error;

    return StatefulBuilder(builder: (ctx, setS) {
      int? customMinutes() {
        final h = int.tryParse(hCtrl.text.trim()) ?? 0;
        final m = int.tryParse(mCtrl.text.trim()) ?? 0;
        final total = h * 60 + m;
        return total > 0 ? total : null;
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 18 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHeader(ctx, 'Service Duration', 'How Much Time Does This Service Take?'),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final p in _durationPresets)
                      GestureDetector(
                        onTap: () => setS(() {
                          picked = p.$2;
                          custom = false;
                          error = null;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AiraColors.pinkFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: !custom && picked == p.$2 ? AiraColors.rose : AiraColors.pinkBorder,
                                width: !custom && picked == p.$2 ? 1.5 : 1.1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(p.$1,
                                      style: AiraText.sans(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.roseDeep))),
                              Icon(!custom && picked == p.$2 ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 22, color: AiraColors.rose),
                            ],
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => setS(() {
                        custom = true;
                        error = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AiraColors.pinkFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: custom ? AiraColors.rose : AiraColors.pinkBorder, width: custom ? 1.5 : 1.1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text('Custom Duration',
                                        style: AiraText.sans(
                                            fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.roseDeep))),
                                Icon(custom ? Icons.radio_button_checked : Icons.radio_button_off,
                                    size: 22, color: AiraColors.rose),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _numBox('Hours', 'e.g. 2', hCtrl, custom, () => setS(() => custom = true))),
                                const SizedBox(width: 12),
                                Expanded(child: _numBox('Minutes', 'e.g. 30', mCtrl, custom, () => setS(() => custom = true))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(error!, style: AiraText.sans(fontSize: 12, color: AiraColors.errorText)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Apply Duration',
              expand: true,
              onTap: () {
                final minutes = custom ? customMinutes() : picked;
                if (minutes == null) {
                  setS(() => error = custom ? 'Enter Hours And/Or Minutes' : 'Choose A Duration');
                  return;
                }
                if (minutes > 24 * 60) {
                  setS(() => error = 'Duration Can Be At Most 24 Hours');
                  return;
                }
                Navigator.of(ctx).pop(minutes);
              },
            ),
          ],
        ),
      );
    });
  });
}

/// UI piece: num box.
Widget _numBox(String label, String hint, TextEditingController c, bool enabled, VoidCallback onTap) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AiraText.sans(fontSize: 11, color: AiraColors.charcoalSoft)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          keyboardType: TextInputType.number,
          onTap: onTap,
          onChanged: (_) => onTap(),
          maxLength: 2,
          style: AiraText.sans(fontSize: 13.5),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AiraColors.pinkBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AiraColors.pinkBorder)),
          ),
        ),
      ],
    );

/// Shows sunndari multi sheet.
Future<Set<String>?> showSunndariMultiSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<String> items,
  required Set<String> selected,
  String searchHint = 'Search',
  String? addLabel,
  String? addPrompt,
  String doneLabel = 'Done',
  bool single = false,
  Map<String, String>? itemSubtitles,
}) {
  return _showSheet<Set<String>>(context, (ctx) {
    final chosen = {...selected};
    final all = [...items];
    final q = TextEditingController();
    String query = '';

    return StatefulBuilder(builder: (ctx, setS) {
      final shown = all.where((e) => e.toLowerCase().contains(query.toLowerCase())).toList();
      return Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 18 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHeader(ctx, title, subtitle),
            Container(
              decoration: BoxDecoration(
                color: AiraColors.pinkFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AiraColors.pinkBorder, width: 1.1),
              ),
              child: TextField(
                controller: q,
                onChanged: (v) => setS(() => query = v),
                style: AiraText.sans(fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AiraColors.rose, size: 21),
                  hintText: searchHint,
                  hintStyle: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft.withOpacity(0.7)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final it in shown)
                    InkWell(
                      onTap: () => setS(() {
                        if (single) {
                          chosen
                            ..clear()
                            ..add(it);
                        } else if (!chosen.add(it)) {
                          chosen.remove(it);
                        }
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: AiraColors.pinkFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: chosen.contains(it) ? AiraColors.rose : AiraColors.pinkBorder,
                              width: chosen.contains(it) ? 1.4 : 1.0),
                        ),
                        child: Row(
                          children: [
                            Icon(chosen.contains(it) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 20, color: chosen.contains(it) ? AiraColors.roseDeep : AiraColors.charcoalSoft),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it, style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoal)),
                                  if (itemSubtitles?[it] != null)
                                    Text(itemSubtitles![it]!,
                                        style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (addLabel != null)
                    InkWell(
                      onTap: () async {
                        final v = await _askText(ctx, addLabel, addPrompt ?? 'Name');
                        if (v == null) return;
                        setS(() {
                          if (!all.any((e) => e.toLowerCase() == v.toLowerCase())) all.add(v);
                          if (single) chosen.clear();
                          chosen.add(all.firstWhere((e) => e.toLowerCase() == v.toLowerCase()));
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: AiraColors.pinkFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AiraColors.pinkBorder, width: 1.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, size: 20, color: AiraColors.charcoalSoft),
                            const SizedBox(width: 10),
                            Text(addLabel, style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoal)),
                          ],
                        ),
                      ),
                    ),
                  if (shown.isEmpty && addLabel == null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text('Nothing Found', style: AiraText.sans(color: AiraColors.charcoalSoft))),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: chosen.isEmpty ? doneLabel : '$doneLabel · ${chosen.length} selected',
              expand: true,
              onTap: () => Navigator.of(ctx).pop(chosen),
            ),
          ],
        ),
      );
    });
  }, full: true);
}
