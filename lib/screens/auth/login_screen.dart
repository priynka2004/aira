// FILE: screens/auth/login_screen.dart
// SCREEN: Login — mobile + password sign in, OTP (Sunndari code) sign in, and onboarding for new artists.
//
// APIs used:
//   POST /auth/login/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/auth/login_request.dart';
import '../../theme/tokens.dart';
import '../../utils/login_error.dart';
import '../../utils/service_locator.dart';
import '../../widgets/common.dart';
import 'about_screen.dart';
import 'forgot_password_screen.dart';
import 'post_login_router.dart';
import 'register_screen.dart';

/// SCREEN: Login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// API: authService.login → POST /auth/login/
  Future<void> _submit() async {
    final id = _idCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (id.isEmpty && password.isEmpty) {
      setState(() => _error = 'Please Enter Your Mobile Number And Password.');
      return;
    }
    if (id.isEmpty) {
      setState(() => _error = 'Please Enter Your Mobile Number.');
      return;
    }
    if (id.length != 10) {
      setState(() => _error = 'Mobile Number Must Be 10 Digits. Please Check And Try Again.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please Enter Your Password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ServiceLocator.authService.login(LoginRequest(username: id, password: password));
      if (!mounted) return;
      await routeAfterLogin(context);
    } catch (e) {
      if (mounted) setState(() => _error = loginErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SunndariBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SunndariLogo(width: 120),
                  const SizedBox(height: 8),
                  const SunndariTitle(
                    title: 'Welcome To Your\nNext Chapter.',
                    subtitle: 'Your Artistry. Your Ambition. Your Business.',
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  SunndariField(
                    label: 'Mobile Number',
                    serifLabel: false,
                    controller: _idCtrl,
                    hint: 'Enter Mobile Number',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    prefix: const _CountryPrefix(),
                  ),
                  SunndariField(
                    label: 'Password',
                    serifLabel: false,
                    controller: _passwordCtrl,
                    hint: 'Enter Password',
                    obscure: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _submit(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AiraColors.roseDeep,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialId: _idCtrl.text.trim())),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Forgot Password?',
                            style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.rose)),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AiraColors.errorText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: AiraText.sans(fontSize: 13, color: AiraColors.errorText, height: 1.35)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Main action
                  SizedBox(
                    height: 52,
                    child: PrimaryButton(
                      label: _loading ? 'Signing In…' : 'Sign In',
                      expand: true,
                      onTap: _loading ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Alternative: OTP
                  GhostButton(
                    label: 'Sign In With Sunndari Code',
                    expand: true,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const RegisterScreen(loginMode: true))),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A One-Time Code On Your Registered Mobile.',
                    textAlign: TextAlign.center,
                    style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft),
                  ),

                  // New artists
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AiraColors.hair)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('New To Sunndari?',
                            style: AiraText.sans(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                      ),
                      const Expanded(child: Divider(color: AiraColors.hair)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: PrimaryButton(
                      label: 'Start Onboarding',
                      expand: true,
                      arrow: true,
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Private Country Prefix widget.
class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 12),
      height: 26,
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AiraColors.pinkBorder))),
      alignment: Alignment.center,
      child: Text('+91', style: AiraText.sans(fontSize: 14.5, fontWeight: FontWeight.w600)),
    );
  }
}
