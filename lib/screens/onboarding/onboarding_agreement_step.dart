// FILE: screens/onboarding/onboarding_agreement_step.dart
// SCREEN: Onboarding Step 4 — partner agreement (tick + accept).

import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../utils/app_feedback.dart';
import '../../utils/onboarding_progress.dart';
import '../../utils/open_link.dart';
import '../../utils/service_locator.dart';
import '../../widgets/common.dart';
import 'onboarding_widgets.dart';

/// SCREEN: Onboarding Step 4 — partner agreement (tick + accept).
class AgreementStepScreen extends StatefulWidget {
  const AgreementStepScreen({super.key});

  @override
  State<AgreementStepScreen> createState() => _AgreementStepScreenState();
}

class _AgreementStepScreenState extends State<AgreementStepScreen> {
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  bool _saving = false;
  String? _commission;
  String? _error;
  String? _termsUrl;
  String? _privacyUrl;
  bool _pagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCommission();
    _loadConsents();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final p = await ServiceLocator.artistBusiness.getPages();
      String? clean(dynamic v) => (v == null || '$v'.trim().isEmpty) ? null : '$v'.trim();
      if (!mounted) return;
      setState(() {
        _termsUrl = clean(p['termsUrl'] ?? p['terms_url']);
        _privacyUrl = clean(p['privacyUrl'] ?? p['privacy_url']);
        _pagesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _pagesLoaded = true);
    }
  }

  Future<void> _openPage({required bool terms}) async {
    var url = terms ? _termsUrl : _privacyUrl;
    if (url == null && !_pagesLoaded) {
      await _loadPages();
      url = terms ? _termsUrl : _privacyUrl;
    }

    if (!mounted) return;

    if (url != null) {
      await openLink(context, url);
      return;
    }

    if (terms) {
      _showDocumentSheet('Partner Agreement', _buildPartnerAgreementView());
    } else {
      _showDocumentSheet('Privacy Policy', _buildPrivacyPolicyView());
    }
  }

  Future<void> _loadConsents() async {
    final c = await OnboardingProgress.loadConsents();
    if (mounted) {
      setState(() {
        _agreedTerms = c.terms;
        _agreedPrivacy = c.privacy;
      });
    }
  }

  Future<void> _toggle({bool? terms, bool? privacy}) async {
    setState(() {
      if (terms != null) _agreedTerms = terms;
      if (privacy != null) _agreedPrivacy = privacy;
      _error = null;
    });
    await OnboardingProgress.saveConsents(terms: _agreedTerms, privacy: _agreedPrivacy);
  }

  /// Khulne wali Bottom Sheet jismein ab formatted widgets pass honge
  void _showDocumentSheet(String title, Widget content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AiraColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600, color: AiraColors.roseDeep))),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AiraColors.charcoal),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: AiraColors.hair),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Future<void> _loadCommission() async {
    try {
      final rate = (await ServiceLocator.artistService.getProfile()).commissionRate;
      if (rate <= 0) return;
      final pct = rate < 1 ? rate * 100 : rate;
      final text = pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
      if (mounted) setState(() => _commission = '$text%');
    } catch (_) {}
  }

  Future<void> _accept() async {
    if (!_agreedTerms) {
      setState(() => _error = 'Please Accept The Terms & Conditions To Continue.');
      return;
    }
    if (!_agreedPrivacy) {
      setState(() => _error = 'Please Accept The Privacy Policy To Continue.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ServiceLocator.artistBusiness.acceptAgreement();
      await OnboardingProgress.saveConsents(terms: true, privacy: true);
      await OnboardingProgress.markAgreementAccepted();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _consent({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String prefix,
    required String linkText,
    required VoidCallback onLink,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: value ? AiraColors.roseDeep : Colors.transparent,
                border: Border.all(color: value ? AiraColors.roseDeep : AiraColors.charcoalSoft.withOpacity(0.5)),
              ),
              child: value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(!value),
              child: RichText(
                text: TextSpan(
                  style: AiraText.sans(fontSize: 13.5, height: 1.4),
                  children: [
                    TextSpan(text: prefix),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: onLink,
                        child: Text(
                          linkText,
                          style: AiraText.sans(
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AiraColors.roseDeep,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topic(IconData icon, String title, String sub, String body, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AiraCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(icon, size: 30, color: AiraColors.roseDeep),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AiraText.sans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                  const SizedBox(height: 2),
                  if (sub.isNotEmpty) ...[
                    Text(sub, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                    const SizedBox(height: 4),
                  ],
                  if (body.isNotEmpty)
                    Text(body, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft, height: 1.4)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 22, color: AiraColors.roseDeep),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fee = _commission == null ? '10%' : '$_commission';
    final canContinue = _agreedTerms && _agreedPrivacy && !_saving;
    return OnbScaffold(
      step: 4,
      art: OnbArt.agreement,
      title: 'Let’s Grow Together',
      subtitle: 'Review The Partnership Terms Before You Continue.',
      error: _error,
      ctaLabel: _saving ? 'Saving…' : 'Agree & Continue',
      onCta: canContinue ? _accept : null,
      onBack: () => Navigator.of(context).pop(false),
      children: [
        _topic(Icons.description_outlined, 'Read Partner Agreement', 'View The Complete Terms', '',
            onTap: () => _openPage(terms: true)),
        const SizedBox(height: 10),
        Text('What The Agreement Covers', style: AiraText.serif(fontSize: 19)),
        const SizedBox(height: 12),
        _topic(Icons.savings_outlined, 'Commission & Fees', '',
            'Current platform commission: $fee. Future changes will be communicated in advance and will apply only to future bookings.'),
        _topic(Icons.credit_card_outlined, 'Payouts', '',
            'Your eligible payout will be processed to your registered bank account within a maximum of 7 days after successful service completion.'),
        _topic(Icons.event_busy_outlined, 'Cancellations & Refunds', '',
            'Booking changes, cancellations, refunds and no-show situations must be handled through Sunndari.'),
        _topic(Icons.verified_user_outlined, 'Artist Responsibilities', '',
            'Keep your profile accurate, honour confirmed bookings, behave professionally, protect customer information and follow Sunndari policies.'),
        const SizedBox(height: 6),
        _consent(
          value: _agreedTerms,
          onChanged: (v) => _toggle(terms: v),
          prefix: 'I Have Read And Agree To The ',
          linkText: 'Partner Agreement',
          onLink: () => _openPage(terms: true),
        ),
        _consent(
          value: _agreedPrivacy,
          onChanged: (v) => _toggle(privacy: v),
          prefix: 'I Have Read And Agree To The ',
          linkText: 'Privacy Policy',
          onLink: () => _openPage(terms: false),
        ),
      ],
    );
  }

  // --- DESIGNED FALLBACK WIDGETS ---

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
  );

  Widget _paragraph(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft, height: 1.55)),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•', style: TextStyle(fontSize: 16, color: AiraColors.roseDeep, height: 1.3)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft, height: 1.55))),
      ],
    ),
  );

  Widget _buildPartnerAgreementView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text('SUNNDARI ARTIST', style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AiraColors.rose)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text("Let's Grow Together", style: AiraText.serif(fontSize: 20, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
        ),
        const SizedBox(height: 24),

        _paragraph('Sunndari connects customers with independent makeup artists. By joining as a Sunndari Artist Partner, you agree to follow the booking, payment, cancellation and professional-service rules below.'),

        _sectionTitle('1. Your Partnership with Sunndari'),
        _paragraph('You join Sunndari as an independent Artist Partner. Sunndari provides the technology platform through which customers can discover and book your services. You remain responsible for the services you offer and deliver to customers.'),

        _sectionTitle('2. Commission & Fees'),
        _paragraph('Sunndari currently charges a 10% commission on every successfully completed booking made through the platform.\n\nThe commission rate may change in the future. Any change will be communicated to you in advance and will apply only to future bookings. The commission applicable to an already confirmed booking will not be changed later.'),

        _sectionTitle('3. Payouts'),
        _paragraph('Your earnings become eligible for payout after the service is successfully completed.\n\nYour eligible payout will be processed to your registered bank account within a maximum of 7 days after successful service completion.\n\nA payout may be temporarily held if the booking is under a refund, cancellation, payment verification, dispute or fraud review. You will be able to track the payout status through the Sunndari Artist App.'),

        _sectionTitle('4. Cancellations, Reschedules & Refunds'),
        _bullet('Once you accept or receive a confirmed booking, you should make every reasonable effort to honour it.'),
        _bullet('If you cannot fulfil a booking, cancel it through the Sunndari Artist App as early as possible and provide the correct reason.'),
        _bullet('If the customer cancels, the applicable Sunndari cancellation and refund policy will apply.'),
        _bullet('If you cancel, the customer will not be treated as responsible for an artist-caused cancellation.'),
        _bullet('Reschedules must be managed through Sunndari and may require customer confirmation.'),
        _bullet('Repeated last-minute cancellations or no-shows may affect your profile visibility or ability to receive future bookings.'),

        _sectionTitle('5. Artist Responsibilities'),
        _paragraph('As a Sunndari Artist Partner, you agree to:'),
        _bullet('Keep your profile, services, prices and availability accurate and updated.'),
        _bullet('Provide the service booked by the customer at the agreed date, time, location and package terms.'),
        _bullet('Maintain professional behaviour, reasonable hygiene and clean tools/products suitable for the service.'),
        _bullet('Use genuine portfolio images that belong to you or that you have permission to use.'),
        _bullet('Never demand any undisclosed mandatory charge from a customer after confirmation.'),
        _bullet('Keep customer phone numbers, addresses, photographs and personal information private.'),
        _bullet('Use customer information only for the relevant Sunndari booking/service purpose.'),
        _bullet('Manage booking changes, cancellations and platform payments through Sunndari as required by platform policy.'),
        _bullet('Not manipulate reviews, create fake bookings, misuse customer data or deliberately double-book confirmed slots.'),
        _paragraph('Serious or repeated violations may lead to restriction, suspension or removal from Sunndari.'),

        _sectionTitle('6. Agreement Updates'),
        _paragraph('Sunndari may update these terms or related platform policies in the future. Material changes that affect your commercial or operational obligations will be communicated before they take effect. Where required, Sunndari may ask you to accept the updated agreement before continuing to receive new bookings.'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPrivacyPolicyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _paragraph('By joining as a Sunndari Artist Partner, you agree to handle customer data responsibly and strictly for business purposes related to Sunndari bookings.'),

        _sectionTitle('1. Data Collection & Use'),
        _paragraph('We collect your profile details, KYC documents, and payout information to verify your identity and process your earnings. Your public profile and portfolio images will be visible to customers on the Sunndari platform.'),

        _sectionTitle('2. Customer Information'),
        _paragraph('You will receive customer details (such as address and contact number) solely to fulfil confirmed bookings. You must not:'),
        _bullet('Use this information for unauthorized marketing.'),
        _bullet('Share this information publicly or with third parties.'),
        _bullet('Retain this information longer than necessary for the service.'),

        _sectionTitle('3. Account Security'),
        _paragraph('You are responsible for keeping your login credentials secure. Sunndari will never ask for your passwords or OTPs outside the app.'),

        _sectionTitle('4. Data Protection'),
        _paragraph('Sunndari employs standard security measures to protect your personal and financial information. For full details on data rights, deletion requests, and our comprehensive privacy practices, please refer to the official Sunndari Privacy Policy available on our website.'),
        const SizedBox(height: 20),
      ],
    );
  }
}