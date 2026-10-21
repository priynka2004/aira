// FILE: utils/ifsc_lookup.dart
// IFSC → bank details. Uses the free public IFSC directory (no key needed).

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result of an IFSC lookup.
class IfscInfo {
  final String bank;
  final String branch;
  const IfscInfo({required this.bank, required this.branch});
}

/// Bank lookup by IFSC code.
class IfscLookup {
  IfscLookup._();

  static final RegExp format = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final Map<String, IfscInfo?> _cache = {};

  /// True when [code] looks like an IFSC (4 letters, 0, 6 letters/digits).
  static bool isValidFormat(String code) => format.hasMatch(code.trim().toUpperCase());

  /// Returns the bank for a valid IFSC, or null when it does not exist / cannot be reached.
  static Future<IfscInfo?> fetch(String code) async {
    final ifsc = code.trim().toUpperCase();
    if (!isValidFormat(ifsc)) return null;
    if (_cache.containsKey(ifsc)) return _cache[ifsc];
    try {
      final r = await http.get(Uri.parse('https://ifsc.razorpay.com/$ifsc')).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) {
        if (r.statusCode == 404) _cache[ifsc] = null;
        return null;
      }
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final info = IfscInfo(bank: (j['BANK'] ?? '').toString(), branch: (j['BRANCH'] ?? '').toString());
      if (info.bank.isEmpty) return null;
      _cache[ifsc] = info;
      return info;
    } catch (_) {
      return null;
    }
  }
}
