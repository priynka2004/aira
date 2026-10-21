// FILE: utils/open_link.dart
// Opens a web link (Terms, Privacy, …) using the packages the app already has (no new plugin).
// Android → the phone's browser. Other platforms / failure → the link is copied so the user can paste it.

import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_feedback.dart';

/// Opens [url] in the browser. Returns true if it was opened.
Future<bool> openLink(BuildContext context, String url) async {
  final link = url.trim();
  if (link.isEmpty) return false;
  try {
    if (Platform.isAndroid) {
      await AndroidIntent(action: 'action_view', data: link).launch();
      return true;
    }
  } catch (_) {}
  try {
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) AppFeedback.showInfo(context, 'Link Copied. Paste It In Your Browser To Open.');
  } catch (_) {}
  return false;
}
