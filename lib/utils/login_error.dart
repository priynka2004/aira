// FILE: utils/login_error.dart
// Turns a failed login into a clear, specific message
// (wrong password / account not found / account blocked / no internet ...)
// instead of the bare "Authentication Error".

import 'app_feedback.dart';

/// Returns the message to show on the login screen for [error].
String loginErrorMessage(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  final e = raw.toLowerCase();

  bool has(List<String> keys) => keys.any(e.contains);

  // Account does not exist.
  if (has(['not found', 'no user', 'no account', 'does not exist', "doesn't exist", 'not registered', 'user not exist', 'invalid user', 'invalid mobile', 'invalid phone'])) {
    return 'No Account Found With This Mobile Number. Please Check The Number, Or Tap "Start Onboarding" To Create One.';
  }
  // Account blocked / not allowed.
  if (has(['inactive', 'disabled', 'blocked', 'suspended', 'deactivated', 'banned'])) {
    return 'This Account Is Not Active. Please Contact Sunndari Support.';
  }
  // Password is wrong.
  if (has(['wrong password', 'incorrect password', 'invalid password', 'password is incorrect', 'password incorrect', 'password does not match', "password doesn't match"])) {
    return 'Incorrect Password. Please Try Again, Or Tap "Forgot Password?" To Reset It.';
  }
  // Too many tries.
  if (has(['too many', 'locked', 'try again later', 'rate limit', 'throttle'])) {
    return 'Too Many Attempts. Please Wait A Few Minutes Before Trying Again.';
  }
  // Generic server rejection of the credentials (the server does not say which one is wrong).
  if (has(['authentication', 'invalid credentials', 'invalid login', 'unable to log in', 'unauthorized', 'credentials', '401', 'incorrect', 'invalid'])) {
    return 'Mobile Number Or Password Is Incorrect. Please Check Both And Try Again, Or Tap "Forgot Password?".';
  }
  // Network / server problems and everything else.
  return AppFeedback.friendlyMessage(error);
}
