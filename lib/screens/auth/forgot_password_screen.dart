// FILE: screens/auth/forgot_password_screen.dart
// SCREEN: Reset Your Password — 1. Verify mobile number · 2. Enter SUNNDARI CODE · 3. New password.
//
// APIs used:
//   POST /auth/password/forgot/   (send code)
//   POST /auth/password/reset/    (code + new password)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/auth/forgot_password_request.dart';
import '../../models/auth/reset_password_request.dart';
import '../../theme/tokens.dart';
import '../../utils/app_feedback.dart';
import '../../utils/service_locator.dart';
import '../../widgets/common.dart';

/// SCREEN: Reset Your Password.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialId;
  const ForgotPasswordScreen({super.key, this.initialId});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

/// State of [ForgotPasswordScreen] — holds the screen data and logic.
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _phoneCtrl;
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _codeSent = false;
  bool _codeChecked = false; // 6 digits entered → ready for a new password
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _phoneError;
  String? _codeError;
  String? _passError;

  /// Runs once when the screen opens.
  @override
  void initState() {
    super.initState();
    final init = (widget.initialId ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    _phoneCtrl = TextEditingController(text: init.length >= 10 ? init.substring(init.length - 10) : init);
    _codeCtrl.addListener(() => setState(() => _codeError = null));
  }

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _phone => _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

  /// Validates the mobile number.
  String? _validatePhone() {
    if (_phone.isEmpty) return 'Please Enter Your Mobile Number.';
    if (_phone.length != 10 || !RegExp(r'^[6-9]').hasMatch(_phone)) return 'Please Enter A Valid 10-digit Mobile Number.';
    return null;
  }

  /// Sends the code.
  /// API: authService.requestPasswordReset → POST /auth/password/forgot/
  Future<void> _sendCode() async {
    final problem = _validatePhone();
    if (problem != null) {
      setState(() => _phoneError = problem);
      return;
    }
    setState(() {
      _loading = true;
      _phoneError = null;
    });
    try {
      await ServiceLocator.authService.requestPasswordReset(ForgotPasswordRequest(identifier: _phone));
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _codeChecked = false;
        _codeCtrl.clear();
      });
      AppFeedback.showSuccess(context, 'SUNNDARI Code Sent To +91 $_phone');
      _codeFocus.requestFocus();
    } catch (e) {
      if (mounted) setState(() => _phoneError = AppFeedback.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Checks the code length, then asks for the new password (the server verifies the code on reset).
  void _verifyCode() {
    if (_codeCtrl.text.length != 6) {
      setState(() => _codeError = 'Please Enter The 6-digit SUNNDARI Code.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _codeChecked = true);
  }

  /// Sets the new password.
  /// API: authService.resetPassword → POST /auth/password/reset/
  Future<void> _reset() async {
    final pass = _passCtrl.text;
    String? problem;
    if (pass.length < 8) {
      problem = 'Password Must Be At Least 8 Characters.';
    } else if (pass != _confirmCtrl.text) {
      problem = 'Passwords Do Not Match.';
    }
    if (problem != null) {
      setState(() => _passError = problem);
      return;
    }
    setState(() {
      _loading = true;
      _passError = null;
    });
    try {
      await ServiceLocator.authService
          .resetPassword(ResetPasswordRequest(identifier: _phone, otp: _codeCtrl.text.trim(), newPassword: pass));
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Password Updated. Please Log In.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = AppFeedback.friendlyMessage(e);
      // A wrong / expired code is reported on reset — send the artist back to the code box.
      final codeProblem = msg.toLowerCase().contains('otp') || msg.toLowerCase().contains('code');
      setState(() {
        if (codeProblem) {
          _codeChecked = false;
          _codeError = msg;
        } else {
          _passError = msg;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _error(String? text) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AiraColors.errorText),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText, height: 1.35))),
          ]),
        );

  Widget _cardHeader(IconData icon, String title, String subtitle) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SunndariIconBubble(icon: icon, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AiraText.sans(fontSize: 15.5, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
              const SizedBox(height: 2),
              Text(subtitle, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.35)),
            ]),
          ),
        ],
      );

  /// Six boxes, one hidden text field behind them.
  Widget _codeBoxes() {
    final text = _codeCtrl.text;
    return GestureDetector(
      onTap: _codeSent ? () => _codeFocus.requestFocus() : null,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 6; i++)
                Container(
                  width: 44,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _codeSent ? AiraColors.pinkFill : AiraColors.pinkFill.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _codeError != null
                          ? AiraColors.errorText
                          : (i == text.length && _codeSent ? AiraColors.rose : AiraColors.pinkBorder),
                      width: i == text.length && _codeSent ? 1.6 : 1.1,
                    ),
                  ),
                  child: Text(i < text.length ? text[i] : '',
                      style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                ),
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _codeCtrl,
                focusNode: _codeFocus,
                enabled: _codeSent,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                enableInteractiveSelection: false,
                showCursor: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController c, bool obscure, VoidCallback toggle) {
    return SunndariField(
      label: label,
      controller: c,
      obscure: obscure,
      hint: label == 'New Password' ? 'At Least 8 Characters' : 'Re-Enter New Password',
      serifLabel: false,
      onChanged: (_) => setState(() => _passError = null),
      suffix: IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AiraColors.charcoalSoft),
        onPressed: toggle,
      ),
    );
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final ready = _codeSent && _codeCtrl.text.length == 6;
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SunndariBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
                  child: Stack(alignment: Alignment.center, children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SunndariBackChip(
                        onTap: () {
                          if (_codeChecked) {
                            setState(() => _codeChecked = false);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                    const SunndariLogo(width: 120),
                  ]),
                ),
                const SizedBox(height: 14),
                Text('Reset Your Password', style: AiraText.serif(fontSize: 28, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                const SizedBox(height: 6),
                Text('Verify Your Registered Mobile Number To Recover Your Account.',
                    style: AiraText.sans(fontSize: 14, color: AiraColors.charcoalSoft, height: 1.4)),
                const SizedBox(height: 18),

                // 1. Verify mobile number
                AiraCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _cardHeader(Icons.smartphone_rounded, '1. Verify Mobile Number', 'Enter Your Registered Mobile Number.'),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AiraColors.pinkFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _phoneError != null ? AiraColors.errorText : AiraColors.pinkBorder, width: 1.1),
                      ),
                      child: Row(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('+91', style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        Container(width: 1, height: 26, color: AiraColors.pinkBorder),
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            enabled: !_codeSent || !_codeChecked,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                            onChanged: (_) => setState(() => _phoneError = null),
                            style: AiraText.sans(fontSize: 15),
                            cursorColor: AiraColors.roseDeep,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter Mobile Number',
                              hintStyle: AiraText.sans(fontSize: 14.5, color: AiraColors.charcoalSoft.withOpacity(0.7)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    _error(_phoneError),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: _loading && !_codeSent ? 'Sending…' : (_codeSent ? 'Resend SUNNDARI CODE' : 'Send SUNNDARI CODE'),
                      icon: Icons.arrow_forward_rounded,
                      expand: true,
                      onTap: _loading ? null : _sendCode,
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                // 2. Enter SUNNDARI CODE
                AiraCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _cardHeader(Icons.shield_outlined, '2. Enter SUNNDARI CODE', 'Enter The 6-digit Code Sent To Your Mobile Number.'),
                    const SizedBox(height: 16),
                    _codeBoxes(),
                    _error(_codeError),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Verify & Continue',
                      icon: Icons.arrow_forward_rounded,
                      expand: true,
                      onTap: ready && !_codeChecked ? _verifyCode : null,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text('After Verification, You Can Create A New Password.',
                          style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                    ),
                  ]),
                ),

                // 3. New password (only after the code is entered)
                if (_codeChecked) ...[
                  const SizedBox(height: 14),
                  AiraCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _cardHeader(Icons.lock_outline_rounded, '3. Create New Password', 'Use At Least 8 Characters.'),
                      const SizedBox(height: 16),
                      _passwordField('New Password', _passCtrl, _obscure, () => setState(() => _obscure = !_obscure)),
                      _passwordField('Confirm Password', _confirmCtrl, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                      _error(_passError),
                      const SizedBox(height: 14),
                      PrimaryButton(label: _loading ? 'Updating…' : 'Reset Password', expand: true, onTap: _loading ? null : _reset),
                    ]),
                  ),
                ],
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.arrow_back_rounded, size: 16, color: AiraColors.rose),
                      const SizedBox(width: 6),
                      Text('Back To Sign In', style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AiraColors.rose)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
