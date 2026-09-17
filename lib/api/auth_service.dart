import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../models/auth/auth_response.dart';
import '../models/auth/register_request.dart';
import '../models/auth/login_request.dart';
import '../models/auth/email_otp_request.dart';
import '../models/auth/email_otp_verify.dart';
import '../models/auth/phone_otp_request.dart';
import '../models/auth/phone_otp_verify.dart';
import '../models/auth/google_auth.dart';
import '../models/auth/token_refresh.dart';
import '../utils/app_session.dart';

class AuthService {
  final ApiService _apiService;
  AuthService(this._apiService);

  Future<AuthResponse> register(RegisterRequest data) async {
    final response = await _apiService.post(ApiEndpoints.authRegister, data: data.toJson());
    final auth = _parseAndLog('register', response.body);
    await _persist(auth);
    return auth;
  }

  Future<AuthResponse> login(LoginRequest data) async {
    final response = await _apiService.post(ApiEndpoints.authLogin, data: data.toJson());
    final auth = _parseAndLog('login', response.body);
    await _persist(auth);
    return auth;
  }

  Future<void> requestEmailOtp(EmailOtpRequest data) async {
    await _apiService.post(ApiEndpoints.authEmailOtpRequest, data: data.toJson());
  }

  Future<AuthResponse> verifyEmailOtp(EmailOtpVerify data) async {
    final response = await _apiService.post(ApiEndpoints.authEmailOtpVerify, data: data.toJson());
    final auth = _parseAndLog('verifyEmailOtp', response.body);
    await _persist(auth);
    return auth;
  }

  Future<void> requestPhoneOtp(PhoneOtpRequest data) async {
    await _apiService.post(ApiEndpoints.authPhoneOtpRequest, data: data.toJson());
  }

  Future<AuthResponse> verifyPhoneOtp(PhoneOtpVerify data) async {
    final response = await _apiService.post(ApiEndpoints.authPhoneOtpVerify, data: data.toJson());
    final auth = _parseAndLog('verifyPhoneOtp', response.body);
    await _persist(auth);
    return auth;
  }

  Future<AuthResponse> googleAuth(GoogleAuth data) async {
    final response = await _apiService.post(ApiEndpoints.authGoogle, data: data.toJson());
    final auth = _parseAndLog('googleAuth', response.body);
    await _persist(auth);
    return auth;
  }

  Future<AuthResponse> refreshToken(TokenRefresh data) async {
    final response = await _apiService.post(ApiEndpoints.authTokenRefresh, data: data.toJson());
    final auth = _parseAndLog('refreshToken', response.body);
    await _persist(auth);
    return auth;
  }

  Future<void> logout() async {
    await AppSession.instance.clear();
  }

  AuthResponse _parseAndLog(String tag, String body) {
    if (kDebugMode) {
      // ── DEBUG: prints the raw backend response to your Run/Logcat console ──
      debugPrint('[AuthService:$tag] raw response => $body');
    }
    final auth = AuthResponse.fromJson(jsonDecode(body));
    if (kDebugMode) {
      debugPrint('[AuthService:$tag] parsed => userId=${auth.userId}, '
          'access="${auth.accessToken}", refresh="${auth.refreshToken}"');
    }
    return auth;
  }

  Future<void> _persist(AuthResponse auth) async {
    await AppSession.instance.save(
      accessToken:  auth.accessToken,
      refreshToken: auth.refreshToken,
      userId:       auth.userId,
      name:         auth.name,
      role:         auth.role ?? '',
    );
    if (kDebugMode) {
      debugPrint('[AuthService] session saved -> '
          'isLoggedIn=${AppSession.instance.isLoggedIn}, '
          'token="${AppSession.instance.accessToken}"');
    }
  }
}
