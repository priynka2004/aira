import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../models/artist/artist_profile_update.dart';
import '../../utils/service_locator.dart';
import '../../utils/app_session.dart';
import '../../utils/app_feedback.dart';
import '../../utils/approval_status.dart';
import '../../app_shell.dart';
import 'login_screen.dart';

class RegistrationStatusScreen extends StatefulWidget {
  final int? approvalStatusId;

  const RegistrationStatusScreen({super.key, required this.approvalStatusId});

  @override
  State<RegistrationStatusScreen> createState() =>
      _RegistrationStatusScreenState();
}

class _RegistrationStatusScreenState extends State<RegistrationStatusScreen> {
  bool _showProfileForm = false;
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ServiceLocator.artistService.updateProfile(
        ArtistProfileUpdate(
          bio: _bioCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          yearsExperience: int.tryParse(_experienceCtrl.text.trim()),
        ),
      );

      if (!mounted) return;

      // Profile ko dobara fetch karo
      final profile = await ServiceLocator.artistService.getProfile();

      final approved = await isApprovedStatusId(profile.approvalStatusId);

      if (!mounted) return;

      if (approved) {
        AppFeedback.showSuccess(
          context,
          "Profile updated successfully.",
        );

        goToAppShell(context);
      } else {
        AppFeedback.showInfo(
          context,
          "Profile submitted successfully. Your account is still under review.",
        );

        setState(() {
          _showProfileForm = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await AppSession.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  bool _checkingStatus = false;

  Future<void> _retryStatus() async {
    setState(() => _checkingStatus = true);
    try {
      final profile = await ServiceLocator.artistService.getProfile();
      if (!mounted) return;

      final approved = await isApprovedStatusId(profile.approvalStatusId);
      if (!mounted) return;

      if (approved) {
        AppFeedback.showSuccess(context, "Your account is approved — taking you in ✓");
        goToAppShell(context);
      } else {
        AppFeedback.showInfo(context, "Still under review — we'll notify you as soon as you're approved.");
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, onRetry: _retryStatus);
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  int? _currentApprovalStatusId;
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final profile = await ServiceLocator.artistService.getProfile();

      if (!mounted) return;

      setState(() {
        _currentApprovalStatusId = profile.approvalStatusId;
        _loadingStatus = false;
      });

      final approved = await isApprovedStatusId(profile.approvalStatusId);

      if (!mounted) return;

      if (approved) {
        goToAppShell(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStatus = false;
        _error = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: _loadingStatus
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : _showProfileForm
              ? _buildForm()
              : _buildStatus(),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final status = _currentApprovalStatusId;

    // Approved
    if (status == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AiraColors.goldSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AiraColors.roseDeep,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "You're approved! ✨",
            style: AiraText.serif(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your artist account has been approved. You can now continue to the app.',
            style: AiraText.sans(
              fontSize: 14,
              color: AiraColors.charcoalSoft,
              height: 1.5,
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Continue',
            expand: true,
            onTap: () => goToAppShell(context),
          ),
        ],
      );
    }

    // Rejected
    if (status == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            size: 60,
            color: AiraColors.errorText,
          ),
          const SizedBox(height: 20),
          Text(
            'Profile needs changes',
            style: AiraText.serif(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your profile was not approved. Please update your profile and submit it again.',
            style: AiraText.sans(
              fontSize: 14,
              color: AiraColors.charcoalSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Update my profile',
            expand: true,
            onTap: () => setState(() {
              _showProfileForm = true;
            }),
          ),
          const Spacer(),
          Center(
            child: GestureDetector(
              onTap: _logout,
              child: Text(
                'Log out',
                style: AiraText.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.errorText,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Suspended
    if (status == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.block,
            size: 60,
            color: AiraColors.errorText,
          ),
          const SizedBox(height: 20),
          Text(
            'Account suspended',
            style: AiraText.serif(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your artist account is currently suspended. Please contact support for more information.',
            style: AiraText.sans(
              fontSize: 14,
              color: AiraColors.charcoalSoft,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Center(
            child: GestureDetector(
              onTap: _logout,
              child: Text(
                'Log out',
                style: AiraText.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.errorText,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Pending / default
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AiraColors.goldSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.hourglass_top,
            color: AiraColors.roseDeep,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "You're almost in ✨",
          style: AiraText.serif(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your Sunndari artist account is being reviewed. Complete your profile so our team can approve you faster — you\'ll be notified as soon as you\'re live.',
          style: AiraText.sans(
            fontSize: 14,
            color: AiraColors.charcoalSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Complete my profile',
          expand: true,
          onTap: () => setState(() {
            _showProfileForm = true;
          }),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: GhostButton(
            label: _checkingStatus
                ? 'Checking…'
                : 'I\'ll do this later — retry status',
            onTap: _checkingStatus ? null : _retryStatus,
          ),
        ),
        const Spacer(),
        Center(
          child: GestureDetector(
            onTap: _logout,
            child: Text(
              'Log out',
              style: AiraText.sans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AiraColors.errorText,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildForm() {
    Widget field(String label, TextEditingController ctrl,
        {TextInputType? type}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: AiraText.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AiraColors.charcoalSoft)),
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
                maxLines: label == 'Bio' ? 3 : 1,
                style: AiraText.sans(fontSize: 15),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showProfileForm = false),
          child: const Icon(Icons.arrow_back,
              size: 20, color: AiraColors.charcoal),
        ),
        const SizedBox(height: 20),
        Text('Tell us about you',
            style: AiraText.serif(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        field('Bio', _bioCtrl),
        field('City', _cityCtrl),
        field('Years of experience', _experienceCtrl,
            type: TextInputType.number),
        if (_error != null) ...[
          Text(_error!,
              style:
                  AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
          const SizedBox(height: 10),
        ],
        PrimaryButton(
          label: _saving ? 'Saving…' : 'Save profile',
          expand: true,
          onTap: _saving ? null : _saveProfile,
        ),
      ],
    );
  }
}

/// Convenience navigation used elsewhere in the app.
void goToAppShell(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AiraAppShell()), (r) => false);
}
