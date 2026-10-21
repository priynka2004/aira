// FILE: screens/onboarding/onboarding_agreement_step.dart
// SCREEN: Onboarding Step 4 — partner agreement (tick + accept).
//
// APIs used:
//   GET /artists/profile/get/
//   GET /core/pages/get/   (Terms / Privacy links)
//   POST /artists/profile/agreement/accept/

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

/// State of [AgreementStepScreen] — holds the screen data and logic.
class _AgreementStepScreenState extends State<AgreementStepScreen> {
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  bool _saving = false;
  String? _commission;
  String? _error;
  String? _termsUrl;
  String? _privacyUrl;
  bool _pagesLoaded = false;

  /// Runs once when the screen opens; starts: _loadCommission(), _loadConsents().
  @override
  void initState() {
    super.initState();
    _loadCommission();
    _loadConsents();
    _loadPages();
  }

  /// Loads the Terms / Privacy links.
  /// API: artistBusiness.getPages → GET /core/pages/get/ (a value is null until the admin configures it)
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

  /// Opens the Terms or Privacy page from the server.
  Future<void> _openPage({required bool terms}) async {
    var url = terms ? _termsUrl : _privacyUrl;
    if (url == null && !_pagesLoaded) {
      await _loadPages();
      url = terms ? _termsUrl : _privacyUrl;
    }
    if (!mounted) return;
    if (url == null) {
      AppFeedback.showInfo(context, terms ? 'The Partner Agreement Is Not Available Right Now. Please Try Again Shortly.' : 'The Privacy Policy Is Not Available Right Now. Please Try Again Shortly.');
      return;
    }
    await openLink(context, url);
  }

  /// Loads consents.
  Future<void> _loadConsents() async {
    final c = await OnboardingProgress.loadConsents();
    if (mounted) setState(() {
      _agreedTerms = c.terms;
      _agreedPrivacy = c.privacy;
    });
  }

  Future<void> _toggle({bool? terms, bool? privacy}) async {
    setState(() {
      if (terms != null) _agreedTerms = terms;
      if (privacy != null) _agreedPrivacy = privacy;
      _error = null;
    });
    await OnboardingProgress.saveConsents(terms: _agreedTerms, privacy: _agreedPrivacy);
  }

  /// Reads document.
  void _readDocument(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AiraColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(title, style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Text(body, style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft, height: 1.55)),
          ],
        ),
      ),
    );
  }

  /// Loads commission.
  /// API: artistService.getProfile → GET /artists/profile/get/
  Future<void> _loadCommission() async {
    try {
      final rate = (await ServiceLocator.artistService.getProfile()).commissionRate;
      if (rate <= 0) return;
      final pct = rate < 1 ? rate * 100 : rate;
      final text = pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
      if (mounted) setState(() => _commission = '$text%');
    } catch (_) {}
  }

  /// Accepts the request.
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
      // API call: artistBusiness.acceptAgreement → POST /artists/profile/agreement/accept/
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

  /// UI piece: point.
  Widget _point(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AiraColors.blush, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AiraColors.roseDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// UI piece: consent.
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

  /// UI piece: topic.
  Widget _topic(IconData icon, String title, String sub, String body, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AiraCard(
        onTap: onTap ?? () => _readDocument(title, body),
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
                  Text(sub, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22, color: AiraColors.roseDeep),
          ],
        ),
      ),
    );
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final fee = _commission == null ? 'A Small Platform Fee' : 'A $_commission Platform Fee';
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
        _topic(Icons.savings_outlined, 'Commission & Fees', 'Applicable Platform Charges.',
            'Sunndari Keeps $fee On Each Completed Booking. Any Other Charges Are Shown To You Before They Apply.'),
        _topic(Icons.credit_card_outlined, 'Payouts', 'How And When Payments Are Processed.',
            'Your Earnings Are Sent To The Bank Account You Added During Onboarding (And Your UPI ID, If You Added One).'),
        _topic(Icons.event_busy_outlined, 'Cancellations & Refunds', 'Terms For Booking Changes And Cancellations.',
            'Clients Can Change Or Cancel A Booking As Per The Cancellation Rules Shown At The Time Of Booking. Refunds Follow The Same Rules.'),
        _topic(Icons.verified_user_outlined, 'Artist Responsibilities', 'Service Standards And Professional Conduct.',
            'Keep Your Working Days And Hours Updated, Arrive On Time, Follow Hygiene Standards And Keep Your Documents And Details Genuine And Current.'),
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
}
