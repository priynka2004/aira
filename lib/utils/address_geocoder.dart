// FILE: utils/address_geocoder.dart
// Converts a text address into lat/lng (used for distance to customer) + LatLng class.

import 'dart:convert';
import 'api_logger.dart';
import '../models/user/customer_address.dart';

/// Address Geocoder.
class AddressGeocoder {
  static final Map<String, LatLng> _cache = {};

  /// Exact coordinates from the API if present, otherwise geocodes the address
  /// (full address first, then shorter fallbacks).
  static Future<LatLng?> forAddress(CustomerAddress address) async {
    if (address.hasCoordinates) return LatLng(address.latitude!, address.longitude!);
    for (final q in address.geocodeQueries) {
      final r = await geocode(q);
      if (r != null) return r;
    }
    return null;
  }

  /// Converts address to coordinates for.
  static Future<LatLng?> geocode(String query) async {
    if (query.trim().isEmpty) return null;
    final cached = _cache[query];
    if (cached != null) return cached;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query)}&format=json&limit=1&countrycodes=in',
      );
      final response = await ApiLog.get(
        url,
        headers: {'Accept-Language': 'en', 'User-Agent': 'SunndariArtistApp/1.0'},
        tag: 'HTTP/geocode',
      );
      if (response.statusCode != 200) return null;
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;
      final result = LatLng(lat, lng);
      _cache[query] = result;
      return result;
    } catch (e) {
      ApiLog.info('AddressGeocoder', 'geocode failed for "$query": $e');
      return null;
    }
  }
}

/// Lat Lng.
class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}
