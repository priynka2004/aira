import 'dart:convert';
import 'package:http/http.dart' as http;

/// One-time text-address -> lat/lng lookup via OpenStreetMap Nominatim --
/// the same free/no-key geocoding service the customer app already uses
/// (in reverse) for its "detect my location" address form.
///
/// This is deliberately called ONCE per address and cached by the
/// caller: a booking's service address is a fixed point (it doesn't
/// move), unlike the artist's own position, which is why only this
/// lookup is a one-shot while the artist's side of the distance
/// calculation comes from a live GPS stream.
class AddressGeocoder {
  static final Map<String, LatLng> _cache = {};

  static Future<LatLng?> geocode(String query) async {
    if (query.trim().isEmpty) return null;
    final cached = _cache[query];
    if (cached != null) return cached;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'Accept-Language': 'en', 'User-Agent': 'SunndariArtistApp/1.0'},
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
    } catch (_) {
      return null;
    }
  }
}

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}
