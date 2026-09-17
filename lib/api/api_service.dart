import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_session.dart';
import 'api_endpoints.dart';

class ApiService {
  static const String baseUrl = ApiEndpoints.baseUrl;

  String? get _token => AppSession.instance.accessToken;

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  // Coalesces concurrent 401s into a single in-flight refresh call.
  Future<bool>? _refreshInFlight;

  // GET
  Future<http.Response> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters:
      queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );
    return _sendWithRetry(() {
      _logRequest('GET', uri);
      return http.get(uri, headers: _headers);
    });
  }

  // POST
  Future<http.Response> post(String endpoint, {dynamic data}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _sendWithRetry(() {
      _logRequest('POST', uri, data);
      return http.post(uri,
          headers: _headers, body: data != null ? jsonEncode(data) : null);
    });
  }

  // PUT
  Future<http.Response> put(String endpoint, {dynamic data}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _sendWithRetry(() {
      _logRequest('PUT', uri, data);
      return http.put(uri,
          headers: _headers, body: data != null ? jsonEncode(data) : null);
    });
  }

  // DELETE
  Future<http.Response> delete(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters:
      queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );
    return _sendWithRetry(() {
      _logRequest('DELETE', uri);
      return http.delete(uri, headers: _headers);
    });
  }

  /// Runs [doRequest]; on a 401 (with a refresh token available) calls
  /// POST /auth/token/refresh/ once and retries the original request
  /// exactly once with the new access token.
  Future<http.Response> _sendWithRetry(
      Future<http.Response> Function() doRequest) async {
    var response = await _safeSend(doRequest);

    if (response.statusCode == 401 &&
        (AppSession.instance.refreshToken?.isNotEmpty ?? false)) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // _headers is recomputed on every call, so the retry picks up
        // the freshly-saved access token automatically.
        response = await _safeSend(doRequest);
      }
    }

    return _handle(response);
  }

  /// Runs [doRequest] with a timeout and converts low-level failures
  /// (no internet, DNS failure, connection reset, server unreachable,
  /// slow/hung request) into a single clean, user-readable [Exception]
  /// instead of letting a raw SocketException/ClientException/
  /// TimeoutException string reach the UI.
  static const _requestTimeout = Duration(seconds: 20);

  Future<http.Response> _safeSend(
      Future<http.Response> Function() doRequest) async {
    try {
      return await doRequest().timeout(_requestTimeout);
    } on TimeoutException catch (e) {
      if (kDebugMode) debugPrint('[ApiService] timeout: $e');
      throw Exception(
          'The request is taking longer than expected. Please check your connection and try again.');
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('[ApiService] socket error: $e');
      throw Exception(
          'No internet connection. Please check your network and try again.');
    } on HandshakeException catch (e) {
      if (kDebugMode) debugPrint('[ApiService] TLS handshake error: $e');
      throw Exception('A secure connection could not be established. Please try again.');
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint('[ApiService] client error: $e');
      throw Exception(
          'Could not reach the server. Please check your connection and try again.');
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('[ApiService] format error: $e');
      throw Exception('Received an unexpected response from the server.');
    } catch (e) {
      // Anything already an Exception with a clean message (e.g. rethrown
      // from _handle on a retry) passes straight through unchanged.
      if (e is Exception) rethrow;
      if (kDebugMode) debugPrint('[ApiService] unexpected error: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }

  Future<bool> _refreshToken() {
    return _refreshInFlight ??= _doRefreshToken().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefreshToken() async {
    final refreshToken = AppSession.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl${ApiEndpoints.authTokenRefresh}');
      _logRequest('POST', uri, {'refresh_token': refreshToken});
      final response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (kDebugMode) {
        debugPrint('[ApiService] token-refresh <- ${response.statusCode} '
            '| ${response.body}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppSession.instance.clear();
        return false;
      }

      Map<String, dynamic> j = jsonDecode(response.body) as Map<String, dynamic>;
      for (final key in ['data', 'result']) {
        final v = j[key];
        if (v is Map<String, dynamic>) {
          j = v;
          break;
        }
      }
      Map<String, dynamic> tokenSrc = j;
      final nested = j['tokens'] ?? j['token'];
      if (nested is Map<String, dynamic>) tokenSrc = nested;

      String findToken(List<String> keys) {
        for (final k in keys) {
          final v = tokenSrc[k];
          if (v is String && v.isNotEmpty) return v;
        }
        return '';
      }

      final newAccess = findToken(['access_token', 'access', 'token', 'accessToken']);
      final newRefresh = findToken(['refresh_token', 'refresh', 'refreshToken']);

      if (newAccess.isEmpty) {
        AppSession.instance.clear();
        return false;
      }

      AppSession.instance.accessToken = newAccess;
      if (newRefresh.isNotEmpty) AppSession.instance.refreshToken = newRefresh;
      await AppSession.instance.save(
        accessToken: newAccess,
        refreshToken: newRefresh.isNotEmpty ? newRefresh : refreshToken,
        userId: AppSession.instance.userId ?? 0,
        name: AppSession.instance.name ?? '',
        role: AppSession.instance.role ?? '',
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ApiService] token-refresh failed: $e');
      return false;
    }
  }

  void _logRequest(String method, Uri uri, [dynamic body]) {
    if (kDebugMode) {
      final hasAuth = _headers.containsKey('Authorization');
      debugPrint('[ApiService] $method $uri | auth=$hasAuth'
          '${body != null ? ' | body=${jsonEncode(body)}' : ''}');
    }
  }

  http.Response _handle(http.Response response) {
    if (kDebugMode) {
      debugPrint('[ApiService] <- ${response.statusCode} ${response.request?.url} '
          '| ${response.body}');
    }
    if (response.statusCode == 401) {
      AppSession.instance.clear();
      throw Exception('Session expired. Please login again.');
    }
    if (response.statusCode >= 500) {
      if (kDebugMode) {
        debugPrint('[ApiService] server error ${response.statusCode}: ${response.body}');
      }
      throw Exception('Something went wrong on our end. Please try again shortly.');
    }
    if (response.statusCode >= 400) {
      String msg = 'Something went wrong. Please try again.';
      try {
        final body = jsonDecode(response.body);
        // Backend has been observed sending the real reason under several
        // different keys depending on the endpoint — `detail` (DRF-style
        // auth errors), `message` (most endpoints' top-level wrapper), and
        // `error` as a list of strings (this API's own custom ValueError
        // responses, e.g. {"error":["Conversation not found"]} or
        // {"error":["Updating records is not allowed"]}). Only checking
        // `detail`/`message` silently dropped every `error`-only response
        // and fell back to the generic "Something went wrong" even though
        // the backend had already sent the specific reason.
        dynamic candidate;
        if (body is Map) {
          candidate = body['detail'] ?? body['message'];
          if (candidate == null) {
            final err = body['error'] ?? body['errors'];
            if (err is List && err.isNotEmpty) {
              candidate = err.first;
            } else if (err is String) {
              candidate = err;
            }
          }
        }
        if (candidate is String && candidate.trim().isNotEmpty) {
          msg = candidate;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[ApiService] failed to parse error body: $e');
      }
      throw Exception(msg);
    }
    return response;
  }
}
