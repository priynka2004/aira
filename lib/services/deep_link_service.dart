// FILE: services/deep_link_service.dart
// Opens the Public Profile Preview screen when a shared profile link is tapped.
//
// Link format (what the app receives):  sunndari://app/profile?id=<artistUserId>
// The shared https link (web/open/index.html hosted on GitHub Pages / Netlify) opens this.
//
// Flow: link arrives (cold start or app already open) -> kept as "pending" ->
// once Splash / Login has opened the main screen (markReady) -> profile screen is pushed on top.

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/public_profile_preview_screen.dart';
import '../utils/app_session.dart';
import '../utils/nav_key.dart';

/// Custom scheme + host registered in AndroidManifest.xml.
const String kDeepLinkScheme = 'sunndari';
const String kDeepLinkHost = 'app';

/// Hosted redirect page (upload web/open/index.html there). Put YOUR page address here.
/// Example GitHub Pages: https://<github-username>.github.io/sunndari-open/
const String kProfileOpenPageUrl = 'https://priynka2004.github.io/sunndari-open/';
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Uri? _pending;
  bool _ready = false;

  /// Builds the https link that is shared (WhatsApp, Telegram, SMS, Instagram, anywhere).
  static String profileShareUrl() {
    final id = AppSession.instance.userId;
    final base = kProfileOpenPageUrl.endsWith('/') ? kProfileOpenPageUrl : '$kProfileOpenPageUrl/';
    return id == null ? base : '$base?id=$id';
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

  /// Call after Splash / Login has opened the first real screen (user logged in).
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
    if (!AppSession.instance.isLoggedIn) return;
    // Let the screen opened by Splash/Login finish its first frame first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null || _pending == null) return;
      _pending = null;
      nav.push(MaterialPageRoute(
        builder: (_) => PublicProfilePreviewScreen(name: AppSession.instance.name ?? ''),
      ));
    });
  }
}
