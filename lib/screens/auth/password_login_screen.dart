// FILE: screens/auth/password_login_screen.dart
// SCREEN: Login with email + password. Has link to Forgot Password.
//
// APIs used:
//   POST /auth/login/

import 'package:flutter/material.dart';
import '../../utils/login_error.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../models/auth/login_request.dart';
import '../../utils/service_locator.dart';
import 'forgot_password_screen.dart';
import 'post_login_router.dart';

/// SCREEN: Login with email + password. Has link to Forgot Password.
class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({super.key});

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

/// State of [PasswordLoginScreen] — holds the screen data and logic.
class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Submits the form.
  /// API: authService.login → POST /auth/login/
  Future<void> _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter Your Username/Email And Password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ServiceLocator.authService.login(LoginRequest(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      ));
      if (!mounted) return;
      await routeAfterLogin(context);
    } catch (e) {
      if (mounted) setState(() => _error = loginErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// UI piece: field.
  Widget _field(
      String label,
      TextEditingController ctrl, {
        bool obscure = false,
        TextInputType? type,
        String? hint,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AiraText.sans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AiraColors.charcoalSoft,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AiraColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AiraColors.hair),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              obscureText: obscure ? _obscurePassword : false,
              style: AiraText.sans(fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AiraText.sans(
                  fontSize: 15,
                  color: AiraColors.charcoalSoft.withOpacity(0.55),
                ),
                suffixIcon: obscure
                    ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AiraColors.charcoalSoft,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SunndariBackChip(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 24),
              Text('Log In With Password', style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              _field('Username Or Email', _usernameCtrl,
                  type: TextInputType.emailAddress, hint: 'Username Or Email'),
              _field(
                'Password',
                _passwordCtrl,
                obscure: true,
                hint: 'Enter Your Password',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Navigates to ForgotPasswordScreen
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ForgotPasswordScreen(initialId: _usernameCtrl.text.trim()),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Forgot Password?',
                      style: AiraText.sans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AiraColors.roseDeep,
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                Text(_error!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
                const SizedBox(height: 10),
              ],
              PrimaryButton(
                label: _loading ? 'Logging In…' : 'Log In',
                expand: true,
                onTap: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
