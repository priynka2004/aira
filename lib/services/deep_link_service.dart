// FILE: services/deep_link_service.dart
// Opens the Public Profile Preview screen when a shared profile link is tapped.
//
// Link format (what the app receives):  sunndari://app/profile?slug=<publicSlug>
// The shared https link (web/open/index.html hosted on GitHub Pages / Netlify) opens this.
//
// Flow: link arrives (cold start or app already open) -> kept as "pending" ->
// once Splash has opened the first screen (markReady) -> PublicArtistProfileScreen(slug) is pushed on top.
// That screen calls GET /public/artists/get/?slug=... (no login needed).

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/public_artist_profile_screen.dart';
import '../utils/service_locator.dart';
import '../utils/nav_key.dart';

/// Custom scheme + host registered in AndroidManifest.xml.
const String kDeepLinkScheme = 'sunndari';
const String kDeepLinkHost = 'app';

/// Hosted redirect page (docs/index.html on GitHub Pages, repo aira, folder /docs).
const String kProfileOpenPageUrl = 'https://priynka2004.github.io/aira/';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Uri? _pending;
  bool _ready = false;

  /// Builds the https link that is shared (WhatsApp, Telegram, SMS, Instagram, anywhere).
  /// Example: https://priynka2004.github.io/aira/?slug=priya-sheoran-e4c2de
  static String profileShareUrl(String slug) {
    final base = kProfileOpenPageUrl.endsWith('/') ? kProfileOpenPageUrl : '$kProfileOpenPageUrl/';
    return '$base?slug=${Uri.encodeQueryComponent(slug)}';
  }

  /// The logged-in artist's public slug.
  /// API: GET /artists/profile/get/ (publicSlug); if empty, GET /artists/profile/share_link/ (slug read from the URL).
  static Future<String?> mySlug() async {
    try {
      final s = (await ServiceLocator.artistService.getProfile()).publicSlug?.trim();
      if (s != null && s.isNotEmpty) return s;
    } catch (_) {}
    try {
      final link = (await ServiceLocator.artistBusiness.getShareLink())?.trim();
      if (link != null && link.isNotEmpty) {
        final u = Uri.tryParse(link);
        final q = u?.queryParameters['slug'];
        if (q != null && q.isNotEmpty) return q;
        final segs = u?.pathSegments.where((e) => e.isNotEmpty).toList() ?? const [];
        if (segs.isNotEmpty) return segs.last;
      }
    } catch (_) {}
    return null;
  }

  /// Ready-to-share link for the logged-in artist (null if the slug could not be loaded).
  static Future<String?> myProfileShareUrl() async {
    final slug = await mySlug();
    return slug == null ? null : profileShareUrl(slug);
  }

  /// Call once in main() before runApp. Catches cold-start and warm (app already open) links.
  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      debugPrint('DeepLink initial error = $e');
    }
    _sub ??= _appLinks.uriLinkStream.listen(_handle, onError: (e) => debugPrint('DeepLink stream error = $e'));
  }

  /// Call after Splash has opened the first screen (Login or the app). The public profile needs no login.
  void markReady() {
    _ready = true;
    _flush();
  }

  bool _isProfileLink(Uri uri) =>
      uri.scheme == kDeepLinkScheme && uri.host == kDeepLinkHost && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'profile';

  void _handle(Uri uri) {
    debugPrint('DeepLink received = $uri');
    if (!_isProfileLink(uri)) return;
    _pending = uri;
    _flush();
  }

  void _flush() {
    if (!_ready || _pending == null) return;
    final slug = (_pending!.queryParameters['slug'] ?? '').trim();
    if (slug.isEmpty) {
      _pending = null; // old ?id= links have no slug
      return;
    }
    // Let the screen opened by Splash finish its first frame first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null || _pending == null) return;
      _pending = null;
      nav.push(MaterialPageRoute(builder: (_) => PublicArtistProfileScreen(slug: slug)));
    });
  }
}
