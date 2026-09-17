import 'package:flutter/material.dart';
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

enum OtpMode { phone, email }

class OtpScreen extends StatefulWidget {
  final OtpMode mode;
  final String contact; // phone number or email address
  const OtpScreen({super.key, required this.mode, required this.contact});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _error = 'Enter the code we sent you');
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
      setState(() => _error = AppFeedback.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
        AppFeedback.showSuccess(context, 'OTP resent');
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppFeedback.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
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
              Text('Enter the code', style: AiraText.serif(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('We sent a verification code to ${widget.contact}',
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
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: AiraText.serif(fontSize: 22).copyWith(letterSpacing: 8),
                  decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
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
                  child: Text(_resending ? 'Resending…' : "Didn't get a code? Resend",
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
