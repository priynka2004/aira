// FILE: utils/share_profile.dart
// Shares the artist's public profile link via the system share sheet.
//
// APIs used:
//   GET /artists/profile/get/
//   GET /artists/services/get_all/
//   Link: DeepLinkService.profileShareUrl() -> https redirect page -> opens app on Public Profile Preview

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/deep_link_service.dart';
import 'app_feedback.dart';
import 'app_session.dart';
import 'artist_extra_details.dart';
import 'service_locator.dart';

/// Shares artist profile.
/// Uses 2 APIs (see inline notes) + the in-app profile link.
Future<void> shareArtistProfile(BuildContext context) async {
  try {
    final extra = await ArtistExtraDetails.load();
    String? city;
    try {
      // API call: artistService.getProfile → GET /artists/profile/get/
      city = (await ServiceLocator.artistService.getProfile()).city;
    } catch (_) {}

    final services = <String>[];
    try {
      // API call: artistService.getAllServices → GET /artists/services/get_all/
      final mine = await ServiceLocator.artistService.getAllServices();
      final rows = mine is List ? mine : (mine is Map && mine['data'] is List ? mine['data'] as List : const []);
      for (final r in rows) {
        if (r is Map) {
          final n = (r['subCategoryName'] ?? r['name'] ?? '').toString().trim();
          if (n.isNotEmpty) services.add(n);
        }
      }
    } catch (_) {}

    final name = [extra.professionalName, extra.displayName, AppSession.instance.name]
        .map((e) => (e ?? '').trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => 'A Sunndari Artist');

    // Link that opens this artist's profile screen in the app (works from WhatsApp, SMS, Telegram, etc.).
    final String link = DeepLinkService.profileShareUrl();

    final b = StringBuffer('Book $name On Sunndari');
    if (city != null && city.trim().isNotEmpty) b.write(' — makeup artist in ${city.trim()}');
    b.write('.');
    if (services.isNotEmpty) b.write('\nServices: ${services.take(6).join(', ')}');
    b.write('\n$link');
    await SharePlus.instance.share(ShareParams(text: b.toString()));
  } catch (e) {
    if (context.mounted) AppFeedback.showError(context, e);
  }
}

/// Adds the artist's public profile link ("Book me here: <link>") to a caption before sharing a post / reel.
/// Link opens the app on the Public Profile Preview screen (see DeepLinkService).
Future<String> captionWithProfileLink(String caption) async {
  final link = DeepLinkService.profileShareUrl();
  if (caption.contains(link)) return caption;
  return '${caption.trimRight()}\n\nBook me here: $link';
}
