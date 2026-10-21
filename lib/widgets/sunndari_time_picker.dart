// FILE: widgets/sunndari_time_picker.dart
// Time picker used everywhere in the app (replaces Flutter's showTimePicker).
//
// Differences from the built-in picker:
//   • No clock dial — the artist types the hour and minute directly.
//   • AM / PM is NOT selected by default. The artist must tap AM or PM herself,
//     and OK stays disabled until hour, minute and AM/PM are all set.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';

/// Shows the Sunndari time picker. Returns null when cancelled.
///
/// [initial] pre-fills the hour and minute only. AM/PM is left empty unless
/// [prefillPeriod] is true (use that only when you want to show a saved value).
Future<TimeOfDay?> pickSunndariTime(
  BuildContext context, {
  TimeOfDay? initial,
  String helpText = 'Enter time',
  bool prefillPeriod = false,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _SunndariTimeDialog(
      initial: initial,
      helpText: helpText,
      prefillPeriod: prefillPeriod,
    ),
  );
}

class _SunndariTimeDialog extends StatefulWidget {
  final TimeOfDay? initial;
  final String helpText;
  final bool prefillPeriod;
  const _SunndariTimeDialog({required this.initial, required this.helpText, required this.prefillPeriod});

  @override
  State<_SunndariTimeDialog> createState() => _SunndariTimeDialogState();
}

class _SunndariTimeDialogState extends State<_SunndariTimeDialog> {
  late final TextEditingController _hour;
  late final TextEditingController _minute;
  bool? _isPm; // null = nothing chosen yet
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    var h = '';
    var m = '';
    if (t != null) {
      final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      h = '$h12';
      m = t.minute.toString().padLeft(2, '0');
      if (widget.prefillPeriod) _isPm = t.period == DayPeriod.pm;
    }
    _hour = TextEditingController(text: h);
    _minute = TextEditingController(text: m);
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  int? get _h {
    final v = int.tryParse(_hour.text);
    return (v != null && v >= 1 && v <= 12) ? v : null;
  }

  int? get _m {
    if (_minute.text.isEmpty) return null;
    final v = int.tryParse(_minute.text);
    return (v != null && v >= 0 && v <= 59) ? v : null;
  }

  bool get _ready => _h != null && _m != null && _isPm != null;

  void _ok() {
    if (!_ready) {
      setState(() {
        _error = _h == null
            ? 'Enter An Hour Between 1 And 12'
            : _m == null
                ? 'Enter Minutes Between 00 And 59'
                : 'Please Select AM Or PM';
      });
      return;
    }
    var hour = _h! % 12;
    if (_isPm!) hour += 12;
    Navigator.of(context).pop(TimeOfDay(hour: hour, minute: _m!));
  }

  Widget _box(TextEditingController c, String label, {bool autofocus = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: AiraColors.pinkFill,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: c,
              autofocus: autofocus,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              style: AiraText.sans(fontSize: 40, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '--',
                hintStyle: AiraText.sans(fontSize: 40, color: AiraColors.charcoalSoft.withOpacity(0.35)),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
        ],
      ),
    );
  }

  Widget _periodButton(String label, bool pm) {
    final on = _isPm == pm;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _isPm = pm;
          _error = null;
        }),
        child: Container(
          alignment: Alignment.center,
          color: on ? AiraColors.blush : Colors.transparent,
          child: Text(
            label,
            style: AiraText.sans(
              fontSize: 16,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on ? AiraColors.roseDeep : AiraColors.charcoalSoft,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AiraColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.helpText, style: AiraText.sans(fontSize: 14, color: AiraColors.charcoal)),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(_hour, 'Hour', autofocus: true),
                  Padding(
                    padding: const EdgeInsets.only(top: 14, left: 8, right: 8),
                    child: Text(':', style: AiraText.sans(fontSize: 44, fontWeight: FontWeight.w600)),
                  ),
                  _box(_minute, 'Minute'),
                  const SizedBox(width: 12),
                  Container(
                    width: 74,
                    height: 78,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AiraColors.pinkBorder, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        _periodButton('AM', false),
                        const Divider(height: 1, thickness: 1.2, color: AiraColors.pinkBorder),
                        _periodButton('PM', true),
                      ],
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: AiraText.sans(fontSize: 14.5, fontWeight: FontWeight.w600, color: AiraColors.rose)),
                  ),
                  TextButton(
                    onPressed: _ok,
                    child: Text(
                      'OK',
                      style: AiraText.sans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _ready ? AiraColors.rose : AiraColors.charcoalSoft.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
