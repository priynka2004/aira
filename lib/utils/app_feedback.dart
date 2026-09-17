import 'package:flutter/material.dart';

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

  /// Green success toast.
  static void showSuccess(BuildContext context, String message) => _show(
    context,
    message: message,
    color: _green,
    icon: Icons.check_circle_outline,
  );

  /// Red error toast. Automatically strips a leading "Exception: " prefix,
  /// since every thrown [Exception] in this app already carries a clean,
  /// user-readable message.
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

  /// Amber/warning toast — for non-fatal issues the user should know about.
  static void showWarning(BuildContext context, String message) => _show(
    context,
    message: message,
    color: _amber,
    icon: Icons.warning_amber_rounded,
  );

  /// Neutral/info toast — e.g. "this feature isn't available yet".
  static void showInfo(BuildContext context, String message) => _show(
    context,
    message: message,
    color: _pink,
    icon: Icons.info_outline,
  );

  /// Public entry point for turning any thrown error (or a raw string
  /// already sitting in a screen's `_error` field) into UI-safe text —
  /// used by [showError] and also by [AiraErrorState] so a raw
  /// backend/DB crash dump never renders on screen, no matter which
  /// screen catches it.
  static String friendlyMessage(Object error, {String? fallback}) =>
      _cleanError(error, fallback: fallback);

  static String _cleanError(Object error, {String? fallback}) {
    var raw = error.toString().replaceFirst('Exception: ', '').trim();
    // Backend sometimes leaks the raw Python exception class name in front
    // of its message (e.g. "Value Error Updating records is not allowed").
    // That's an implementation detail, not something a user should see —
    // strip it before any further matching/display.
    raw = raw.replaceFirst(RegExp(r'^Value ?Error:?\s*', caseSensitive: false), '').trim();
    final e = raw.toLowerCase();

    // A raw server-side crash dump (DB errors, Python dict/serializer
    // error reprs, stack traces) leaking through a 400/500 — these are
    // never meant for an end user (they can be hundreds of characters
    // long and reference internal column/table names). Catch them by
    // pattern regardless of length, log the real detail for diagnosis,
    // and show a clean generic message instead.
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
      return fallback ?? "Something went wrong on our end. Please try again in a moment.";
    }

    // Known backend business-rule messages that are technically accurate
    // but not user-friendly — map them to something actionable instead of
    // showing the backend's internal wording verbatim.
    if (e.contains('updating records is not allowed')) {
      return "This booking can't be updated right now. Please try again in a moment, or contact support if it keeps happening.";
    }

    if (e.contains('timeout')) {
      return "The server is taking longer than expected. Please try again in a moment.";
    }

    if (e.contains('socket') ||
        e.contains('failed host lookup') ||
        e.contains('connection refused') ||
        e.contains('network')) {
      return "Unable to connect. Please check your internet connection and try again.";
    }

    if (e.contains('401') || e.contains('unauthorized')) {
      return "Your session has expired. Please sign in again.";
    }

    if (e.contains('403')) {
      return "You don't have permission to perform this action.";
    }

    if (e.contains('404')) {
      return "The requested information could not be found.";
    }

    if (e.contains('409')) {
      return "This action cannot be completed because the data already exists.";
    }

    if (e.contains('422')) {
      return "Some information is invalid. Please check and try again.";
    }

    if (e.contains('500') ||
        e.contains('502') ||
        e.contains('503') ||
        e.contains('504')) {
      return "Our server is currently unavailable. Please try again later.";
    }

    if (e.contains('cancel')) {
      return "The request was cancelled.";
    }

    // No known network/HTTP-status pattern matched — this is almost always
    // a specific, human-readable message the backend sent on purpose (e.g.
    // "Booking cannot be marked complete before the scheduled date" or
    // "Invalid status transition from confirmed to completed"). Show it
    // instead of silently swapping it out for a generic string — that was
    // hiding the real, actionable reason behind every 400/422-style
    // business-rule rejection (Mark complete, Cancel, etc.).
    if (raw.isNotEmpty && raw.length <= 200) {
      return raw;
    }

    return fallback ??
        "Something went wrong. Please try again.";
  }
}
