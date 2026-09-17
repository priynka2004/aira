import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/artist_profile.dart';
import '../models/artist/artist_profile_update.dart';
import '../models/user/user_profile.dart';
import '../models/user/user_profile_update.dart';
import '../utils/service_locator.dart';
import '../utils/app_session.dart';
import '../utils/app_feedback.dart';

class EditProfileScreen extends StatefulWidget {
  final ArtistProfile? profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _radiusCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  bool _loadingAccount = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.profile?.bio ?? '');
    _cityCtrl = TextEditingController(text: widget.profile?.city ?? '');
    _experienceCtrl = TextEditingController(text: widget.profile?.yearsExperience.toString() ?? '');
    _radiusCtrl = TextEditingController(text: widget.profile?.serviceRadiusKm.toString() ?? '');
    _nameCtrl = TextEditingController(text: AppSession.instance.name ?? '');
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final userId = AppSession.instance.userId;
    if (userId == null) {
      setState(() => _loadingAccount = false);
      return;
    }
    try {
      final UserProfile account = await ServiceLocator.userService.getProfile(userId);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = account.name;
        _emailCtrl.text = account.email ?? '';
        _phoneCtrl.text = account.phoneNumber ?? '';
        _loadingAccount = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAccount = false);
      AppFeedback.showWarning(context, "Couldn't load your account details — you can still edit your artist profile below.");
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _experienceCtrl.dispose();
    _radiusCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? type, int maxLines = 1}) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              maxLines: maxLines,
              style: AiraText.sans(fontSize: 15),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Future.wait([
        ServiceLocator.artistService.updateProfile(ArtistProfileUpdate(
          bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          yearsExperience: int.tryParse(_experienceCtrl.text.trim()),
          serviceRadiusKm: int.tryParse(_radiusCtrl.text.trim()),
        )),
        ServiceLocator.userService.updateProfile(UserProfileUpdate(
          name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        )),
      ]);
      // Keep the locally-cached display name in sync.
      AppSession.instance.name = _nameCtrl.text.trim();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = AppFeedback.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
                ),
                const SizedBox(width: 12),
                Text('Edit profile', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),
            if (_loadingAccount)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose)),
              ),
            Text('ACCOUNT', style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
            const SizedBox(height: 10),
            _field('Full name', _nameCtrl),
            _field('Email', _emailCtrl, type: TextInputType.emailAddress),
            _field('Phone number', _phoneCtrl, type: TextInputType.phone),
            const SizedBox(height: 8),
            Text('ARTIST PROFILE', style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
            const SizedBox(height: 10),
            _field('Bio', _bioCtrl, maxLines: 3),
            _field('City', _cityCtrl),
            _field('Years of experience', _experienceCtrl, type: TextInputType.number),
            _field('Service radius (km)', _radiusCtrl, type: TextInputType.number),
            if (_error != null) ...[
              Text(_error!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
              const SizedBox(height: 10),
            ],
            PrimaryButton(label: _saving ? 'Saving…' : 'Save changes', expand: true, onTap: _saving ? null : _save),
          ],
        ),
      ),
    );
  }
}
