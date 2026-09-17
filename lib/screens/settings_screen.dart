import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/artist_profile.dart';
import '../utils/app_feedback.dart';
import 'edit_profile_screen.dart';
import 'portfolio_manage_screen.dart';
import 'packages_screen.dart';
import 'business_setup_screen.dart';
import 'notifications_screen.dart';
import 'auth/registration_status_screen.dart';
import 'help_center_screen.dart';

class _Group {
  final String title;
  final List<String> rows;
  const _Group(this.title, this.rows);
}

class SettingsScreen extends StatelessWidget {
  final String name;
  final String? city;
  final ArtistProfile? profile;
  final VoidCallback onLogout;
  final VoidCallback? onProfileUpdated;

  const SettingsScreen({
    super.key,
    this.name = '',
    this.city,
    this.profile,
    required this.onLogout,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // "Verification" only makes sense to show while there's nothing saved
    // yet — once the artist has an approval_status_id on their profile
    // (submitted/pending/approved/rejected, whatever it resolves to), their
    // verification info has already been saved, so the row disappears
    // instead of nagging them again on every visit to Profile.
    final needsVerification = profile?.approvalStatusId == null;

    final accountRows = [
      'Edit profile',
      'Business setup',
      'My packages',
      'Portfolio',
      'Notifications',
      if (needsVerification) 'Verification',
    ];
    const supportRows = ['Help centre', 'Contact Sunndari', 'Terms & privacy', 'Log out'];

    Future<void> handleTap(String row) async {
      if (row == 'Edit profile') {
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
        );
        if (updated == true) {
          onProfileUpdated?.call();
          if (context.mounted) AppFeedback.showSuccess(context, 'Profile updated ✓');
        }
      } else if (row == 'Business setup') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusinessSetupScreen()));
      } else if (row == 'My packages') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PackagesScreen()));
      } else if (row == 'Portfolio') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PortfolioManageScreen()));
      } else if (row == 'Notifications') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      } else if (row == 'Verification') {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RegistrationStatusScreen(approvalStatusId: profile?.approvalStatusId)));
      } else if (row == 'Help centre') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
      } else if (row == 'Log out') {
        onLogout();
      } else {
        // 'Contact Sunndari', 'Terms & privacy' — no backing endpoint in
        // the Sunndari API yet, so be upfront instead of pretending to
        // navigate somewhere.
        AppFeedback.showInfo(context, "This isn't available yet — check back soon");
      }
    }

    Widget group(_Group g) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.title.toUpperCase(),
                style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
            const SizedBox(height: 8),
            AiraCard(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: g.rows.asMap().entries.map((e) {
                  final isLast = e.key == g.rows.length - 1;
                  final isLogout = e.value == 'Log out';
                  return InkWell(
                    onTap: () => handleTap(e.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: isLast ? null : const Border(bottom: BorderSide(color: AiraColors.hair)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.value,
                              style: AiraText.sans(
                                  fontSize: 14, color: isLogout ? AiraColors.errorText : AiraColors.charcoal)),
                          Icon(Icons.chevron_right,
                              size: 15, color: isLogout ? AiraColors.errorText : AiraColors.charcoalSoft),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      color: AiraColors.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AiraScreenHeader(title: 'Profile'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(gradient: AiraGradients.avatarOrb, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isNotEmpty ? name : 'Sunndari Artist',
                          style: AiraText.serif(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text(
                        'Makeup Artist${city != null && city!.isNotEmpty ? ' · $city' : ''}',
                        style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            group(_Group('Account', accountRows)),
            group(const _Group('Support', supportRows)),
          ],
        ),
      ),
    );
  }
}
