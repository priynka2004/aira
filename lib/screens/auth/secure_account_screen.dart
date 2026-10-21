// FILE: screens/auth/secure_account_screen.dart
// SCREEN: Secure Account — set a password right after OTP signup.
//
// APIs used:
//   POST /auth/password/set/

import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../utils/app_feedback.dart';
import '../../utils/service_locator.dart';
import '../../widgets/common.dart';
import '../onboarding/onboarding_flow_screen.dart';

/// SCREEN: Secure Account — set a password right after OTP signup.
class SecureAccountScreen extends StatefulWidget {
  final String email;
  final String phone;
  const SecureAccountScreen({super.key, this.email = '', this.phone = ''});

  @override
  State<SecureAccountScreen> createState() => _SecureAccountScreenState();
}

/// State of [SecureAccountScreen] — holds the screen data and logic.
class _SecureAccountScreenState extends State<SecureAccountScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hide1 = true;
  bool _hide2 = true;
  bool _saving = false;
  String? _error;

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Validates the input.
  String? _validate() {
    final p = _passCtrl.text;
    if (p.length < 8) return 'Use At Least 8 Characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
      return 'Use A Mix Of Letters And Numbers.';
    }
    if (p != _confirmCtrl.text) return 'The Two Passwords Do Not Match.';
    return null;
  }

  /// Saves the entered data.
  /// API: authService.setPassword → POST /auth/password/set/ (new_password + confirm_password)
  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // API call: authService.setPassword → POST /auth/password/set/
      await ServiceLocator.authService.setPassword(
        password: _passCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
    } catch (e) {
      // Show the real reason (for example a weak password) and let the user fix it or continue without one.
      debugPrint('[SecureAccount] setPassword failed: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppFeedback.friendlyMessage(e);
      });
      return;
    }
    if (!mounted) return;
    AppFeedback.showSuccess(context, 'Password Saved');
    _goOnboarding();
  }

  /// Continues to onboarding (also used by "Continue without a password").
  void _goOnboarding() {
    // Navigates to OnboardingFlowScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
      (_) => false,
    );
  }

  /// UI piece: eye.
  Widget _eye(bool hidden, VoidCallback onTap) => IconButton(
        icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20, color: AiraColors.roseDeep),
        onPressed: onTap,
      );

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SunndariBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: SunndariFlowBar(
                  title: 'Account Security',
                  onBack: Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: SunndariLogo(width: 110)),
                      const SizedBox(height: 18),
                      const Center(child: Icon(Icons.lock_outline_rounded, size: 46, color: AiraColors.roseDeep)),
                      const SizedBox(height: 10),
                      Center(
                        child: const SunndariTitle(
                          title: 'Secure Your\nAccount',
                          subtitle: 'Create A Password To Sign In To\nYour Artist Account.',
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SunndariField(
                        label: 'Create Password',
                        controller: _passCtrl,
                        hint: 'Enter Your Password',
                        obscure: _hide1,
                        suffix: _eye(_hide1, () => setState(() => _hide1 = !_hide1)),
                      ),
                      SunndariField(
                        label: 'Confirm Password',
                        controller: _confirmCtrl,
                        hint: 'Re-Enter Your Password',
                        obscure: _hide2,
                        suffix: _eye(_hide2, () => setState(() => _hide2 = !_hide2)),
                      ),
                      Center(
                        child: Text(
                          'Choose A Strong, Unique Password.',
                          style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _goOnboarding,
                            child: Text('Continue Without A Password',
                                style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.rose)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
                child: PrimaryButton(
                  label: _saving ? 'Saving…' : 'Save & Continue',
                  arrow: true,
                  expand: true,
                  onTap: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
