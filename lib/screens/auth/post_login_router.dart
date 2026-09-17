import 'package:flutter/material.dart';
import '../../utils/service_locator.dart';
import '../../utils/approval_status.dart';
import '../../app_shell.dart';
import 'registration_status_screen.dart';

/// Decides where to send the artist right after a successful login.
///
/// This used to decide based on whether the artist had *filled in their
/// profile form* (bio/city/experience) — which has nothing to do with
/// whether an admin has actually approved their account. That mismatch
/// was the real cause of a login/relaunch inconsistency: an artist who
/// filled in their profile but was still "pending" admin review would be
/// sent straight into the app on login (profile looked "complete"), then
/// correctly bounced to the registration-status screen the next time they
/// reopened the app (which checks the real approval status). Both flows
/// now check the same thing: the actual approval status from
/// GET /core/approval-status/get_all/.
Future<void> routeAfterLogin(BuildContext context) async {
  try {
    final profile = await ServiceLocator.artistService.getProfile();

    debugPrint("Bio = ${profile.bio}");
    debugPrint("City = ${profile.city}");
    debugPrint("Experience = ${profile.yearsExperience}");

    if (!context.mounted) return;

    final approved = await isApprovedStatusId(profile.approvalStatusId);
    if (!context.mounted) return;

    if (approved) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const AiraAppShell(),
        ),
            (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationStatusScreen(
            approvalStatusId: profile.approvalStatusId,
          ),
        ),
            (_) => false,
      );
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}
