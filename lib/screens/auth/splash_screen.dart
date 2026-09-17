import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../utils/app_session.dart';
import '../../utils/service_locator.dart';
import '../../utils/approval_status.dart';
import '../../app_shell.dart';
import 'login_screen.dart';
import 'registration_status_screen.dart';

/// First screen shown on launch. Loads the persisted session, and — if a
/// token exists — verifies it's still valid by pulling the artist profile
/// before dropping the user into the app. This mirrors the Sunndari
/// Artist app's splash → auth-check flow, just re-skinned in AiRA's style.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AppSession.instance.load();

    debugPrint("==================================");
    debugPrint("Splash Token = ${AppSession.instance.accessToken}");
    debugPrint("Splash LoggedIn = ${AppSession.instance.isLoggedIn}");
    debugPrint("==================================");

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    if (!AppSession.instance.isLoggedIn) {
      _goTo(const LoginScreen());
      return;
    }

    try {
      final profile = await ServiceLocator.artistService.getProfile();

      debugPrint("Splash Status = ${profile.approvalStatusId}");

      final approved = await isApprovedStatusId(profile.approvalStatusId);

      debugPrint("Splash Approved = $approved");

      if (!mounted) return;

      if (approved) {
        debugPrint("Going to AppShell");
        _goTo(const AiraAppShell());
      } else {
        debugPrint("Going to RegistrationStatus");
        _goTo(
          RegistrationStatusScreen(
            approvalStatusId: profile.approvalStatusId,
          ),
        );
      }
    } catch (e) {
      debugPrint("Splash Error = $e");
      await AppSession.instance.clear();

      if (!mounted) return;

      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AiraGradients.avatarOrb),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('AiRA', style: AiraText.serif(fontSize: 28, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('for Sunndari Artists', style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft)),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose),
            ),
          ],
        ),
      ),
    );
  }
}
