// FILE: utils/app_feedback.dart
// Snackbar helper: success / error / warning / info messages + friendly error text.

import 'package:flutter/material.dart';

/// App Feedback.
class AppFeedback {
  AppFeedback._();

  static const _pink = Color(0xFF9B0F4D);
  static const _green = Color(0xFF1F9254);
  static const _red = Color(0xFFD64545);
  static const _amber = Color(0xFFB4780A);

  static void _show(
      BuildContext context, {
        required String message,
        required Color color,
        required IconData icon,
        Duration duration = const Duration(seconds: 3),
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null
            ? SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction ?? () {},
        )
            : null,
      ),
    );
  }

  /// Shows success.
  static void showSuccess(BuildContext context, String message) => _show(
    context,
    message: message,
    color: _green,
    icon: Icons.check_circle_outline,
  );

  /// Shows error.
  static void showError(BuildContext context, Object error,
      {String? fallback, VoidCallback? onRetry}) {
    final message = _cleanError(error, fallback: fallback);
    _show(
      context,
      message: message,
      color: _red,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 4),
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  /// Shows warning.
  static void showWarning(BuildContext context, String message) => _show(
    context,
    message: message,
    color: _amber,
    icon: Icons.warning_amber_rounded,
  );

  /// Shows info.
  static void showInfo(BuildContext context, String message) => _show(
    context,
    message: message,
    color: _pink,
    icon: Icons.info_outline,
  );

  /// Friendly message.
  static String friendlyMessage(Object error, {String? fallback}) =>
      _cleanError(error, fallback: fallback);

  /// Clean error.
  static String _cleanError(Object error, {String? fallback}) {
    var raw = error.toString().replaceFirst('Exception: ', '').trim();
    raw = raw.replaceFirst(RegExp(r'^Value ?Error:?\s*', caseSensitive: false), '').trim();
    final e = raw.toLowerCase();
    const technicalMarkers = [
      'exception error',
      'database error',
      'no such column',
      'no such table',
      'errordetail(',
      'traceback',
      "{'data'",
      "': [",
      '": [',
      'null pointer',
      'stack trace',
      'syntaxerror',
      'keyerror',
      'typeerror',
    ];
    if (technicalMarkers.any((m) => e.contains(m))) {
      debugPrint('[AppFeedback] Suppressed technical error from UI: $raw');
      return fallback ?? "Sunndari Server Had A Problem. Please Try Again In A Few Minutes.";
    }

    if (e.contains('updating records is not allowed')) {
      return "This Booking Can't Be Updated Right Now. Please Try Again In A Moment, Or Contact Support If It Keeps Happening.";
    }

    if (e.contains('timeout')) {
      return "The Server Is Slow To Respond. Please Check Your Internet And Try Again.";
    }

    if (e.contains('socket') ||
        e.contains('failed host lookup') ||
        e.contains('connection refused') ||
        e.contains('network')) {
      return "No Internet Connection. Please Turn On Mobile Data Or Wi-Fi And Try Again.";
    }

    if (e.contains('401') || e.contains('unauthorized')) {
      return "Your Login Has Expired. Please Log In Again.";
    }

    if (e.contains('403')) {
      return "You Don't Have Permission To Perform This Action.";
    }

    if (e.contains('404')) {
      return "This Information Was Not Found. It May Have Been Removed.";
    }

    if (e.contains('409')) {
      return "This Action Cannot Be Completed Because The Data Already Exists.";
    }

    if (e.contains('422')) {
      return "Some Details Are Not Valid. Please Check The Highlighted Fields.";
    }

    if (e.contains('500') ||
        e.contains('502') ||
        e.contains('503') ||
        e.contains('504')) {
      return "Sunndari Server Is Not Available Right Now. Please Try Again In A Few Minutes.";
    }

    if (e.contains('cancel')) {
      return "The Request Was Cancelled.";
    }

    if (raw.isNotEmpty && raw.length <= 200) {
      return raw;
    }

    return fallback ??
        "Could Not Complete This. Please Check Your Internet And Try Again.";
  }
}
