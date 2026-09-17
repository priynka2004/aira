import 'package:flutter/material.dart';
import '../../utils/app_feedback.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../models/auth/login_request.dart';
import '../../utils/service_locator.dart';
import 'post_login_router.dart';

/// POST /auth/login/ — for artists who registered with a password
/// (via RegisterScreen) instead of using OTP.
class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({super.key});

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your username/email and password');
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
      setState(() => _error = AppFeedback.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
      String label,
      TextEditingController ctrl, {
        bool obscure = false,
        TextInputType? type,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
              ),
              const SizedBox(height: 24),
              Text('Log in with password', style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              _field('Username or email', _usernameCtrl),
              _field(
                'Password',
                _passwordCtrl,
                obscure: true,
              ),
              if (_error != null) ...[
                Text(_error!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
                const SizedBox(height: 10),
              ],
              PrimaryButton(
                label: _loading ? 'Logging in…' : 'Log in',
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
