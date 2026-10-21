// FILE: utils/onboarding_progress.dart
// Which onboarding steps are done (from profile + local flags).
//
// APIs used:
//   GET /artists/services/get_all/
//   GET /artists/portfolio/get_all/
//   GET /artists/onboarding/status/   (server checklist: documents, payoutAccount, agreement, ...)

import 'package:shared_preferences/shared_preferences.dart';
import '../models/artist/artist_extras.dart';
import '../models/artist/artist_profile.dart';
import 'app_session.dart';
import 'artist_extra_details.dart';
import 'service_locator.dart';

const int kMinPortfolioPhotos = 3;

/// As list.
List<dynamic> _asList(dynamic json) {
  if (json is List) return json;
  if (json is Map && json['data'] is List) return json['data'] as List;
  return const [];
}

/// Looks like real name.
bool looksLikeRealName(String? name) {
  final n = (name ?? '').trim();
  if (n.length < 2) return false;
  return !RegExp(r'^\+?[\d\s\-]{6,}$').hasMatch(n);
}

/// Onboarding Progress.
class OnboardingProgress {
  final bool details;
  final bool services;
  final bool documents;
  final bool agreement;

  const OnboardingProgress({
    required this.details,
    required this.services,
    required this.documents,
    required this.agreement,
  });

  /// Returns all.
  List<bool> get _all => [details, services, documents, agreement];

  /// Returns all done.
  bool get allDone => _all.every((d) => d);
  /// Nothing started.
  bool get nothingStarted => _all.every((d) => !d);
  /// Done count.
  int get doneCount => _all.where((d) => d).length;
  /// Returns true if done.
  bool isDone(int stepIndex) => _all[stepIndex];

  /// First pending.
  int get firstPending {
    final i = _all.indexWhere((d) => !d);
    return i == -1 ? 4 : i;
  }

  /// Agreement key.
  static String get _agreementKey =>
      'onboarding_agreement_${AppSession.instance.userId ?? 0}';

  /// Marks agreement accepted.
  static Future<void> markAgreementAccepted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_agreementKey, true);
  }

  /// Agreement accepted.
  static Future<bool> _agreementAccepted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_agreementKey) ?? false;
  }

  /// Terms key.
  static String get _termsKey => 'consent_terms_${AppSession.instance.userId ?? 0}';
  /// Privacy key.
  static String get _privacyKey => 'consent_privacy_${AppSession.instance.userId ?? 0}';

  /// Saves consents.
  static Future<void> saveConsents({required bool terms, required bool privacy}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_termsKey, terms);
    await p.setBool(_privacyKey, privacy);
  }

  static Future<({bool terms, bool privacy})> loadConsents() async {
    final p = await SharedPreferences.getInstance();
    return (terms: p.getBool(_termsKey) ?? false, privacy: p.getBool(_privacyKey) ?? false);
  }

  /// Documents key.
  static String get _documentsKey =>
      'onboarding_documents_local_${AppSession.instance.userId ?? 0}';

  /// Marks documents completed locally.
  static Future<void> markDocumentsCompletedLocally() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_documentsKey, true);
  }

  /// Documents completed locally.
  static Future<bool> _documentsCompletedLocally() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_documentsKey) ?? false;
  }

  /// Details key.
  static String get _detailsKey =>
      'onboarding_details_local_${AppSession.instance.userId ?? 0}';

  /// Marks details completed locally.
  static Future<void> markDetailsCompletedLocally() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_detailsKey, true);
  }

  /// Details completed locally.
  static Future<bool> _detailsCompletedLocally() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_detailsKey) ?? false;
  }

  /// Services key.
  static String get _servicesKey =>
      'onboarding_services_local_${AppSession.instance.userId ?? 0}';

  /// Marks services completed locally.
  static Future<void> markServicesCompletedLocally() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_servicesKey, true);
  }

  /// Services completed locally.
  static Future<bool> _servicesCompletedLocally() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_servicesKey) ?? false;
  }

  /// Safely runs.
  static Future<bool> _safe(Future<bool> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return false;
    }
  }

  /// Loads this screen's data.
  /// Uses 3 APIs (see inline notes).
  static Future<OnboardingProgress> load({ArtistProfile? profile}) async {
    final artist = ServiceLocator.artistService;

    // API call: artistBusiness.getOnboardingStatus → GET /artists/onboarding/status/
    // The server is the source of truth for documents / payout / agreement; the device flags below are
    // only a fallback when the call fails (offline).
    OnboardingStatus? server;
    try {
      server = await ServiceLocator.artistBusiness.getOnboardingStatus();
    } catch (_) {}

    final detailsF = _safe(() async {
      if (server != null && server.done('basicInfo') && server.done('registrationFields')) {
        return true;
      }
      final extra = await ArtistExtraDetails.load();
      if (!extra.isDetailsComplete) return false;
      if (await _detailsCompletedLocally()) return true;
      return looksLikeRealName(AppSession.instance.name);
    });

    final servicesF = _safe(() async {
      if (await _servicesCompletedLocally()) return true;
      // API call: artistService.getAllServices → GET /artists/services/get_all/
      if (_asList(await artist.getAllServices()).isEmpty) return false;
      // API call: artistService.getAllPortfolios → GET /artists/portfolio/get_all/
      final portfolios = await artist.getAllPortfolios(limit: 20);
      return portfolios.data.length >= kMinPortfolioPhotos;
    });

    final documentsF = _safe(() async {
      if (server != null) return server.done('documents') && server.done('payoutAccount');
      return _documentsCompletedLocally();
    });

    final agreementF = _safe(() async {
      if (server != null) return server.done('agreement');
      return _agreementAccepted();
    });

    final r = await Future.wait<bool>([detailsF, servicesF, documentsF, agreementF]);
    return OnboardingProgress(
      details: r[0],
      services: r[1],
      documents: r[2],
      agreement: r[3],
    );
  }
}
