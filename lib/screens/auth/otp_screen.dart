// FILE: screens/auth/otp_screen.dart
// SCREEN: OTP — enter the 6-digit code (phone or email), verify, resend.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../models/auth/phone_otp_verify.dart';
import '../../models/auth/phone_otp_request.dart';
import '../../models/auth/email_otp_verify.dart';
import '../../models/auth/email_otp_request.dart';
import '../../models/enums/role_enum.dart';
import '../../utils/service_locator.dart';
import '../../utils/app_feedback.dart';
import 'post_login_router.dart';

/// Enum: Otp Mode values.
enum OtpMode { phone, email }

/// SCREEN: OTP — enter the 6-digit code (phone or email), verify, resend.
class OtpScreen extends StatefulWidget {
  final OtpMode mode;
  final String contact;
  const OtpScreen({super.key, required this.mode, required this.contact});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

/// State of [OtpScreen] — holds the screen data and logic.
class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Verifies the entered code.
  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6 || int.tryParse(otp) == null) {
      setState(() => _error = 'Enter The 6-digit Code We Sent You');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.mode == OtpMode.phone) {
        await ServiceLocator.authService
            .verifyPhoneOtp(PhoneOtpVerify(phoneNumber: widget.contact, otp: otp));
      } else {
        await ServiceLocator.authService
            .verifyEmailOtp(EmailOtpVerify(email: widget.contact, otp: otp));
      }
      if (!mounted) return;
      await routeAfterLogin(context);
    } catch (e) {
      // A wrong / expired code must never let the user in.
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Resends the code.
  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      if (widget.mode == OtpMode.phone) {
        await ServiceLocator.authService
            .requestPhoneOtp(PhoneOtpRequest(phoneNumber: widget.contact, role: RoleEnum.artist));
      } else {
        await ServiceLocator.authService
            .requestEmailOtp(EmailOtpRequest(email: widget.contact, role: RoleEnum.artist));
      }
      if (mounted) {
        AppFeedback.showSuccess(context, 'OTP Resent');
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppFeedback.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
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
              Text('Enter The Code', style: AiraText.serif(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('We Sent A Verification Code To ${widget.contact}',
                  style: AiraText.sans(fontSize: 14, color: AiraColors.charcoalSoft)),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: AiraColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AiraColors.hair),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: AiraText.serif(fontSize: 22).copyWith(letterSpacing: 8),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: AiraText.serif(fontSize: 22, color: AiraColors.charcoalSoft.withOpacity(0.4))
                        .copyWith(letterSpacing: 8),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: _loading ? 'Verifying…' : 'Verify & Continue',
                expand: true,
                onTap: _loading ? null : _verify,
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: _resending ? null : _resend,
                  child: Text(_resending ? 'Resending…' : "Didn't Get A Code? Resend",
                      style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
