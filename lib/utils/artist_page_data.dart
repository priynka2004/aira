// FILE: utils/artist_page_data.dart
// On-device data for Build My Artist Page: package meta, add-ons, location prefs.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/artist/package.dart';
import 'app_session.dart';
import 'service_locator.dart';

/// Package Meta.
class PackageMeta {
  final String category;
  final String makeupType;
  final List<String> brands;
  final String products;

  const PackageMeta({this.category = '', this.makeupType = '', this.brands = const [], this.products = ''});

  static const _tag = '[sunndari-meta]';

  /// Reads the package's category / makeup type / brands / products.
  /// New packages carry real API fields (makeupType, brands, productDetails); older ones that hid this
  /// inside the description (`[sunndari-meta]{...}`) are still understood.
  static PackageMeta fromPackage(Package? p) {
    if (p == null) return const PackageMeta();
    final old = decode(p.description);
    final plainDesc = (p.description ?? '').contains(_tag) ? '' : (p.description ?? '').trim();
    return PackageMeta(
      category: old.category.isNotEmpty ? old.category : (plainDesc.isNotEmpty ? plainDesc : (p.category ?? '')),
      makeupType: (p.makeupType ?? '').isNotEmpty ? p.makeupType! : old.makeupType,
      brands: p.brands.isNotEmpty ? p.brands : old.brands,
      products: (p.productDetails ?? '').isNotEmpty ? p.productDetails! : old.products,
    );
  }

  static String encode({
    required String category,
    required String makeupType,
    required List<String> brands,
    required String products,
  }) =>
      '$_tag${jsonEncode({'c': category, 't': makeupType, 'b': brands, 'p': products})}';

  static PackageMeta decode(String? description) {
    final d = description ?? '';
    final i = d.indexOf(_tag);
    if (i < 0) return const PackageMeta();
    try {
      final m = jsonDecode(d.substring(i + _tag.length)) as Map;
      return PackageMeta(
        category: (m['c'] ?? '').toString(),
        makeupType: (m['t'] ?? '').toString(),
        brands: ((m['b'] as List?) ?? const []).map((e) => '$e').toList(),
        products: (m['p'] ?? '').toString(),
      );
    } catch (_) {
      return const PackageMeta();
    }
  }
}

/// Formats duration.
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h hr';
  return '$h Hr $m Min';
}

/// Add On.
class AddOn {
  /// Server id (null for items that only exist in the on-device cache).
  final int? addOnId;
  final String name;
  final double price;
  final int extraMinutes;
  final String description;
  final List<int> packageIds;

  const AddOn({
    this.addOnId,
    required this.name,
    required this.price,
    this.extraMinutes = 0,
    this.description = '',
    this.packageIds = const [],
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() =>
      {'i': addOnId, 'n': name, 'p': price, 'm': extraMinutes, 'd': description, 'k': packageIds};

  /// Builds this object from API JSON.
  factory AddOn.fromJson(Map<String, dynamic> j) => AddOn(
        addOnId: (j['i'] as num?)?.toInt(),
        name: (j['n'] ?? '').toString(),
        price: (j['p'] as num?)?.toDouble() ?? 0,
        extraMinutes: (j['m'] as num?)?.toInt() ?? 0,
        description: (j['d'] ?? '').toString(),
        packageIds: ((j['k'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
      );
}

/// Service Location Prefs.
class ServiceLocationPrefs {
  final int venue;
  final List<String> areas;
  final bool travelFree;
  final double travelAmount;
  final String travelUnit;

  const ServiceLocationPrefs({
    this.venue = 0,
    this.areas = const [],
    this.travelFree = true,
    this.travelAmount = 0,
    this.travelUnit = 'Per visit',
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() =>
      {'v': venue, 'a': areas, 'f': travelFree, 'amt': travelAmount, 'u': travelUnit};

  /// Builds this object from API JSON.
  factory ServiceLocationPrefs.fromJson(Map<String, dynamic> j) => ServiceLocationPrefs(
        venue: (j['v'] as num?)?.toInt() ?? 0,
        areas: ((j['a'] as List?) ?? const []).map((e) => '$e').toList(),
        travelFree: j['f'] != false,
        travelAmount: (j['amt'] as num?)?.toDouble() ?? 0,
        travelUnit: (j['u'] ?? 'Per visit').toString(),
      );

  /// Venue label.
  String get venueLabel => switch (venue) {
        1 => 'At My Studio',
        2 => 'At Your Venue · Studio Appointments',
        _ => 'At Your Venue',
      };
}

/// Artist Page Local.
class ArtistPageLocal {
  ArtistPageLocal._();

  static String _k(String name) => 'artist_page_${name}_${AppSession.instance.userId ?? 0}';

  /// Add-ons. Source of truth is the server (GET /artists/addons/get_all/); the on-device copy is only an
  /// offline cache, refreshed on every successful fetch.
  static Future<List<AddOn>> addOns() async {
    try {
      final list = await ServiceLocator.artistBusiness.getAddOns();
      final out = list
          .where((a) => a.isActive)
          .map((a) => AddOn(
                addOnId: a.addOnId,
                name: a.name,
                price: a.price,
                extraMinutes: a.durationMinutes,
                description: a.description ?? '',
                packageIds: a.packageIds,
              ))
          .toList();
      await saveAddOns(out);
      return out;
    } catch (_) {
      try {
        final p = await SharedPreferences.getInstance();
        final raw = p.getString(_k('addons'));
        if (raw == null) return [];
        return (jsonDecode(raw) as List).map((e) => AddOn.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Saves the offline cache of add-ons (does NOT call the server).
  static Future<void> saveAddOns(List<AddOn> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k('addons'), jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<ServiceLocationPrefs> location() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k('location'));
      if (raw == null) return const ServiceLocationPrefs();
      return ServiceLocationPrefs.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const ServiceLocationPrefs();
    }
  }

  /// Saves location.
  static Future<void> saveLocation(ServiceLocationPrefs v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k('location'), jsonEncode(v.toJson()));
  }

  /// Service photos.
  static Future<Map<int, String>> servicePhotos() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k('service_photos'));
      if (raw == null) return {};
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(int.parse('$k'), '$v'));
    } catch (_) {
      return {};
    }
  }

  /// Saves service photo.
  static Future<void> saveServicePhoto(int packageId, String path) async {
    final m = await servicePhotos();
    m[packageId] = path;
    final p = await SharedPreferences.getInstance();
    await p.setString(_k('service_photos'), jsonEncode(m.map((k, v) => MapEntry('$k', v))));
  }

  /// Portfolio order.
  static Future<List<int>> portfolioOrder() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_k('portfolio_order')) ?? const []).map(int.parse).toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves portfolio order.
  static Future<void> savePortfolioOrder(List<int> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_k('portfolio_order'), ids.map((e) => '$e').toList());
    try {
      // API call: artistBusiness.reorderPortfolio → PUT /artists/portfolio/reorder/ (unlisted items follow)
      await ServiceLocator.artistBusiness.reorderPortfolio(ids);
    } catch (_) {
      // order is still kept on the device; the server copy catches up on the next successful save
    }
  }

  static List<T> applyOrder<T>(List<T> items, List<int> order, int Function(T) idOf) {
    final pos = {for (var i = 0; i < order.length; i++) order[i]: i};
    final sorted = [...items];
    sorted.sort((a, b) => (pos[idOf(a)] ?? 1 << 20).compareTo(pos[idOf(b)] ?? 1 << 20));
    return sorted;
  }
}
