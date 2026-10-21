// FILE: main.dart  |  APP ENTRY POINT
// Flow: main() -> Firebase init -> push handler -> ServiceLocator.init() -> local notifications
//       -> runApp(AiraApp) -> SplashScreen (first screen).

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'api/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'services/deep_link_service.dart';
import 'services/push_notification_service.dart';
import 'theme/tokens.dart';
import 'utils/nav_key.dart';
import 'utils/service_locator.dart';

/// APP ENTRY POINT: starts Firebase, push handler, services, then runs the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  ServiceLocator.init();

  // Session died (logged in elsewhere / refresh token expired): go back to
  // the login screen and drop every other screen.
  ApiService.onSessionExpired = () {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  };

  await PushNotificationService.instance.initLocalNotifications();

  // Shared profile link (sunndari://app/profile) -> opens Public Profile Preview.
  await DeepLinkService.instance.init();

  runApp(const AiraApp());
}

/// Root MaterialApp: theme + navigator key; first screen = SplashScreen.
class AiraApp extends StatelessWidget {
  const AiraApp({super.key});

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Sunndari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AiraColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AiraColors.rose,
          primary: AiraColors.rose,
          onPrimary: Colors.white,
          surface: AiraColors.bg,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AiraColors.roseDeep,
          selectionHandleColor: AiraColors.rose,
        ),
        splashFactory: InkRipple.splashFactory,
      ),
      home: const SplashScreen(),
    );
  }
}
