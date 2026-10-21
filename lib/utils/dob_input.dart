// FILE: utils/dob_input.dart
// Date of birth helpers — one format (DD/MM/YYYY) for the whole app, with the "/" added automatically.

import 'package:flutter/services.dart';

/// Typing `15081995` shows `15/08/1995`. The user never types the slash.
class DobInputFormatter extends TextInputFormatter {
  const DobInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final b = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2 || i == 4) b.write('/');
      b.write(capped[i]);
    }
    final text = b.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Formats a date as DD/MM/YYYY.
String formatDob(DateTime? d) => d == null
    ? ''
    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';

/// Parses DD/MM/YYYY. Returns null when the text is not a real calendar date.
DateTime? parseDob(String text) {
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text.trim());
  if (m == null) return null;
  final day = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  final d = DateTime(year, month, day);
  if (d.year != year || d.month != month || d.day != day) return null; // e.g. 31/02
  return d;
}

/// Returns an error message, or null when the DOB is valid (real date, artist is 18+).
String? validateDob(String text) {
  if (text.trim().isEmpty) return 'Please Enter Your Date Of Birth.';
  final d = parseDob(text);
  if (d == null) return 'Please Enter A Valid Date Of Birth (DD/MM/YYYY).';
  final now = DateTime.now();
  var age = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
  if (age < 18) return 'You Must Be At Least 18 Years Old.';
  if (age > 80) return 'Please Enter A Valid Date Of Birth (DD/MM/YYYY).';
  return null;
}
