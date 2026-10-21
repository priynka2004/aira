// FILE: screens/auth/logout_helper.dart
// Shared "Log Out" flow used by onboarding screens (and anywhere a user may need to get out).
// Asks for confirmation, clears the session + push/notification state, then returns to Login
// with a clean back stack.

import 'package:flutter/material.dart';

import '../../api/help_center_notifier.dart';
import '../../services/push_notification_service.dart';
import '../../theme/tokens.dart';
import '../../utils/notification_badge.dart';
import '../../utils/service_locator.dart';
import 'login_screen.dart';

/// Clears the session and goes to the Login screen (no confirmation).
Future<void> performLogout(BuildContext context) async {
  final navigator = Navigator.of(context);
  try {
    await PushNotificationService.instance.resetForLogout();
  } catch (_) {}
  try {
    await HelpCenterNotifier.instance.stop();
  } catch (_) {}
  try {
    await ServiceLocator.authService.logout();
  } catch (_) {}
  try {
    NotificationBadge.instance.clear();
  } catch (_) {}
  navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
}

/// Shows a confirmation sheet, then logs out. Returns true if the user logged out.
Future<bool> confirmAndLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Back To Sign In?', style: AiraText.serif(fontSize: 20, fontWeight: FontWeight.w700)),
      content: Text(
        'Already Have An Account? Log Out Here And Sign In With Your Mobile Number Or SUNNDARI Code.',
        style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Stay Here',
              style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Log Out', style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.rose)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  await performLogout(context);
  return true;
}
