import 'package:flutter/material.dart';
import '../../utils/app_feedback.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../models/auth/phone_otp_request.dart';
import '../../models/auth/email_otp_request.dart';
import '../../models/auth/google_auth.dart';
import '../../models/enums/role_enum.dart';
import '../../utils/service_locator.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import 'post_login_router.dart';
import 'password_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _mode = 'phone';
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loadingOtp = false;
  bool _loadingGoogle = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _error = null);

    if (_mode == 'phone') {
      final phone = _phoneCtrl.text.trim();
      if (phone.length < 10) {
        setState(() => _error = 'Please enter a valid phone number');
        return;
      }
      setState(() => _loadingOtp = true);
      try {
        await ServiceLocator.authService.requestPhoneOtp(
          PhoneOtpRequest(phoneNumber: phone, role: RoleEnum.artist),
        );
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(mode: OtpMode.phone, contact: phone),
          ),
        );
      } catch (e) {
        setState(() => _error = AppFeedback.friendlyMessage(e));
      } finally {
        if (mounted) setState(() => _loadingOtp = false);
      }
    } else {
      final email = _emailCtrl.text.trim();
      if (!email.contains('@') || !email.contains('.')) {
        setState(() => _error = 'Please enter a valid email address');
        return;
      }
      setState(() => _loadingOtp = true);
      try {
        await ServiceLocator.authService.requestEmailOtp(
          EmailOtpRequest(email: email, role: RoleEnum.artist),
        );
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(mode: OtpMode.email, contact: email),
          ),
        );
      } catch (e) {
        setState(() => _error = AppFeedback.friendlyMessage(e));
      } finally {
        if (mounted) setState(() => _loadingOtp = false);
      }
    }
  }

  // Future<void> _continueWithGoogle() async {
  //   setState(() {
  //     _error = null;
  //     _loadingGoogle = true;
  //   });
  //   try {
  //     final googleSignIn = GoogleSignIn(scopes: const ['email']);
  //     final account = await googleSignIn.signIn();
  //     if (account == null) {
  //       setState(() => _loadingGoogle = false);
  //       return;
  //     }
  //     final auth = await account.authentication;
  //     final idToken = auth.idToken;
  //     if (idToken == null) {
  //       throw Exception('Google sign-in did not return an ID token');
  //     }
  //     await ServiceLocator.authService.googleAuth(
  //       GoogleAuth(idToken: idToken, role: RoleEnum.artist),
  //     );
  //     if (!mounted) return;
  //     await routeAfterLogin(context);
  //   } catch (e) {
  //     setState(() => _error = AppFeedback.friendlyMessage(e));
  //   } finally {
  //     if (mounted) setState(() => _loadingGoogle = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isPhone = _mode == 'phone';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(28, 36, 28, bottomInset > 0 ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Brand ────────────────────────────────────────
                    const Center(child: AiraOrb(size: 64)),
                    const SizedBox(height: 32),

                    // ── Heading ──────────────────────────────────────
                    Text(
                      'Welcome back',
                      style: AiraText.serif(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your Sunndari account',
                      style: AiraText.sans(
                        fontSize: 15,
                        color: AiraColors.charcoalSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Segmented control ────────────────────────────
                    AiraSegTabs(
                      tabs: const [
                        SegTabItem('phone', 'Phone'),
                        SegTabItem('email', 'Email'),
                      ],
                      active: _mode,
                      onSelect: (m) => setState(() {
                        _mode = m;
                        _error = null;
                      }),
                    ),
                    const SizedBox(height: 24),

                    // ── Field label ──────────────────────────────────
                    Text(
                      isPhone ? 'PHONE NUMBER' : 'EMAIL ADDRESS',
                      style: AiraText.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AiraColors.charcoalSoft,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Input ────────────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: AiraColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _error != null
                              ? AiraColors.errorText.withOpacity(0.55)
                              : AiraColors.hair,
                          width: 1.25,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: isPhone ? _phoneCtrl : _emailCtrl,
                        keyboardType: isPhone
                            ? TextInputType.phone
                            : TextInputType.emailAddress,
                        style: AiraText.sans(fontSize: 15.5, height: 1.3),
                        cursorColor: AiraColors.roseDeep,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          hintText: isPhone ? '+91 00000 00000' : 'email@.com',
                          hintStyle: AiraText.sans(
                            fontSize: 15,
                            color: AiraColors.charcoalSoft.withOpacity(0.55),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 10),
                            child: Icon(
                              isPhone
                                  ? Icons.phone_iphone_rounded
                                  : Icons.mail_outline_rounded,
                              size: 20,
                              color: AiraColors.charcoalSoft.withOpacity(0.75),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 24,
                          ),
                        ),
                      ),
                    ),

                    // ── Error ────────────────────────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: _error != null
                          ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AiraColors.errorText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AiraText.sans(
                                  fontSize: 13,
                                  color: AiraColors.errorText,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 28),

                    // ── Primary CTA ──────────────────────────────────
                    PrimaryButton(
                      label: _loadingOtp ? 'Sending OTP…' : 'Send OTP',
                      expand: true,
                      onTap: _loadingOtp ? null : _sendOtp,
                    ),
                    const SizedBox(height: 28),

                    // ── Divider ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AiraColors.hair.withOpacity(0.9),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: AiraText.sans(
                              fontSize: 13,
                              color: AiraColors.charcoalSoft,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AiraColors.hair.withOpacity(0.9),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Google ───────────────────────────────────────
                    // GhostButton(
                    //   label: _loadingGoogle ? 'Connecting…' : 'Continue with Google',
                    //   icon: Icons.g_mobiledata_rounded,
                    //   onTap: _loadingGoogle ? null : _continueWithGoogle,
                    // ),
                    // const SizedBox(height: 12),

                    // ── Password fallback ────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PasswordLoginScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AiraColors.charcoalSoft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Log in with password instead',
                          style: AiraText.sans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom register bar ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 22),
              decoration: BoxDecoration(
                color: AiraColors.bg,
                border: Border(
                  top: BorderSide(
                    color: AiraColors.hair.withOpacity(0.7),
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AiraText.sans(
                      fontSize: 14.5,
                      color: AiraColors.charcoalSoft,
                    ),
                    children: [
                      const TextSpan(text: 'New to Sunndari?  '),
                      TextSpan(
                        text: 'Create account',
                        style: AiraText.sans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AiraColors.roseDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
