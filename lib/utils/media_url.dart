// FILE: utils/media_url.dart
// Turns a relative media path from the API into a full image URL.

import '../api/api_endpoints.dart';

/// Resolves media URL.
String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;

  const mediaPrefix = '/media/';
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return '${ApiEndpoints.baseUrl}$mediaPrefix$cleanPath';
}
