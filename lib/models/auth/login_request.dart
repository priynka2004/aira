// FILE: models/auth/login_request.dart  |  MODEL
// Request body: password login.

/// Model: Login Request.
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}
