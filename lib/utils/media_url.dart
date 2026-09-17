import '../api/api_endpoints.dart';

/// The backend sometimes returns portfolio/media file paths as relative
/// paths (e.g. "portfolios/artist_5/scaled_Screenshot.jpg") instead of a
/// full URL. Passing a relative path straight to Image.network() throws
/// "No host specified in URI" and the image never loads.
///
/// This resolves any relative path against the API's base host + the
/// standard Django media prefix ("/media/"). If the value is already a
/// full http(s) URL it's returned unchanged.
///
/// NOTE: this assumes the backend serves uploaded media under "/media/"
/// (Django's default MEDIA_URL). If your backend uses a different prefix
/// (e.g. a CDN domain, or no "/media/" segment at all), update
/// `_mediaPrefix` below to match — this couldn't be verified against the
/// live server from this environment.
String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;

  const mediaPrefix = '/media/';
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return '${ApiEndpoints.baseUrl}$mediaPrefix$cleanPath';
}
