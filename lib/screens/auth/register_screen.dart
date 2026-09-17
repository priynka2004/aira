import 'package:flutter/material.dart';
import '../../utils/app_feedback.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../models/auth/register_request.dart';
import '../../models/enums/role_enum.dart';
import '../../utils/service_locator.dart';
import 'post_login_router.dart';

/// Password-based signup (POST /auth/register/) for a brand new artist.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? type, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
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
              obscureText: obscure,
              style: AiraText.sans(fontSize: 15),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().length < 10 ||
        _passwordCtrl.text.trim().length < 6) {
      setState(() => _error = 'Fill your name, a valid phone number and a password (6+ chars)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ServiceLocator.authService.register(RegisterRequest(
        name: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: RoleEnum.artist,
      ));
      if (!mounted) return;
      await routeAfterLogin(context);
    } catch (e) {
      setState(() => _error = AppFeedback.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
            ),
            const SizedBox(height: 20),
            Text('Create your artist account', style: AiraText.serif(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Join Sunndari and let AiRA run the business side for you.',
                style: AiraText.sans(fontSize: 14, color: AiraColors.charcoalSoft)),
            const SizedBox(height: 28),
            _field('Full name', _nameCtrl),
            _field('Phone number', _phoneCtrl, type: TextInputType.phone),
            _field('Email (optional)', _emailCtrl, type: TextInputType.emailAddress),
            _field('Password', _passwordCtrl, obscure: true),
            if (_error != null) ...[
              Text(_error!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            PrimaryButton(
              label: _loading ? 'Creating account…' : 'Create account',
              expand: true,
              onTap: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
