// FILE: screens/booking_help_screen.dart
// SCREEN: Booking Help — report an issue about one booking; sends it to the Help Center.
//
// APIs used:
//   POST /help_center/messages/create/

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/tokens.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../widgets/common.dart';
import 'help_center_screen.dart';

/// SCREEN: Booking Help — report an issue about one booking; sends it to the Help Center.
class BookingHelpScreen extends StatefulWidget {
  final int bookingId;
  final String serviceName;
  final String dateTimeLabel;

  final Future<bool> Function()? onReschedule;

  const BookingHelpScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
    required this.dateTimeLabel,
    this.onReschedule,
  });

  @override
  State<BookingHelpScreen> createState() => _BookingHelpScreenState();
}

/// State of [BookingHelpScreen] — holds the screen data and logic.
class _BookingHelpScreenState extends State<BookingHelpScreen> {
  static const _issues = <(IconData, String)>[
    (Icons.person_off_outlined, 'Client Unavailable'),
    (Icons.location_off_outlined, 'Venue Or Address Issue'),
    (Icons.account_balance_wallet_outlined, 'Payment Or Payout Issue'),
    (Icons.miscellaneous_services_outlined, 'Service Concern'),
    (Icons.more_horiz_rounded, 'Something Else'),
  ];

  String? _issue;
  final List<XFile> _photos = [];
  final _details = TextEditingController();
  bool _sending = false;

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  /// Starts reschedule.
  Future<void> _startReschedule() async {
    final submitted = await widget.onReschedule!();
    if (submitted && mounted) Navigator.of(context).pop();
  }

  /// Opens requests.
  void _openRequests() =>
      // Navigates to HelpCenterScreen
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen()));

  /// Submits the form.
  /// API: helpCenterService.sendMessage → POST /help_center/messages/create/
  Future<void> _submit() async {
    if (_issue == null) {
      AppFeedback.showInfo(context, 'Choose What You Need Help With First');
      return;
    }
    final text = _details.text.trim();
    if (text.isEmpty) {
      AppFeedback.showInfo(context, 'Tell Us What Happened So We Can Help');
      return;
    }
    setState(() => _sending = true);
    try {
      final photoNote = _photos.isEmpty
          ? ''
          : ' (' + _photos.length.toString() + ' Photo(s) Chosen On The Artist Phone, Not Uploaded Yet)';
      await ServiceLocator.helpCenterService.sendMessage(
        'Booking Help - Booking #${widget.bookingId} (${widget.serviceName}, ${widget.dateTimeLabel})\n'
        'Issue: $_issue\n$text$photoNote',
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Support Request Sent ✓');
      _openRequestsAfterSend();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Opens requests after send.
  void _openRequestsAfterSend() {
    // Navigates to HelpCenterScreen
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
  }

  /// Lets the user pick photos.
  Future<void> _pickPhotos() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;
      setState(() {
        _photos.addAll(picked);
        if (_photos.length > 4) _photos.removeRange(4, _photos.length);
      });
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    }
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SunndariBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SunndariAppBar(onBack: () => Navigator.of(context).pop()),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: SunndariPageHeading(title: 'Booking Help', subtitle: 'Get Help With A Specific Booking.'),
                    ),
                    AiraCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const SunndariIconBubble(icon: Icons.calendar_month_outlined, size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Booking ID', style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                                Text('#${widget.bookingId}',
                                    style: AiraText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                                Text(widget.serviceName, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                Text(widget.dateTimeLabel, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('How Can We Help?', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    AiraCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (widget.onReschedule != null)
                            _issueRow(Icons.event_repeat_outlined, 'Booking Reschedule', onTap: _startReschedule),
                          for (var i = 0; i < _issues.length; i++) _issueRow(_issues[i].$1, _issues[i].$2, last: i == _issues.length - 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Describe The Issue', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AiraColors.hair),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _details,
                            maxLines: 4,
                            maxLength: 500,
                            onChanged: (_) => setState(() {}),
                            style: AiraText.sans(fontSize: 14),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              hintText: 'Tell Us What Happened…',
                              hintStyle: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft.withOpacity(0.8)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('${_details.text.length}/500', style: AiraText.sans(fontSize: 11, color: AiraColors.charcoalSoft)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text('Add Photos Or Screenshots', style: AiraText.serif(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text('(optional)', style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickPhotos,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AiraColors.pinkFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AiraColors.pinkBorder, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const SunndariIconBubble(icon: Icons.image_outlined, size: 48),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_photos.isEmpty ? 'Tap To Add Photos' : '${_photos.length} Photo${_photos.length == 1 ? '' : 's'} Added — Tap To Add More',
                                    style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AiraColors.roseDeep)),
                                Text('JPG, PNG Or HEIC', style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(_photos[i].path), width: 60, height: 60, fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: -6,
                                top: -6,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photos.removeAt(i)),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(color: AiraColors.roseDeep, shape: BoxShape.circle),
                                    child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 15, color: AiraColors.rose),
                        const SizedBox(width: 6),
                        Text('Avoid Uploading Sensitive Personal Details.',
                            style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _sending ? 'Sending…' : 'Submit Support Request',
                      expand: true,
                      onTap: _sending ? null : _submit,
                    ),
                    const SizedBox(height: 10),
                    GhostButton(label: 'View My Requests', icon: Icons.description_outlined, expand: true, onTap: _openRequests),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// UI piece: issue row.
  Widget _issueRow(IconData icon, String label, {bool last = false, VoidCallback? onTap}) {
    final selected = onTap == null && _issue == label;
    return InkWell(
      onTap: onTap ?? () => setState(() => _issue = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AiraColors.blush : Colors.transparent,
          border: last ? null : const Border(bottom: BorderSide(color: AiraColors.hair)),
        ),
        child: Row(
          children: [
            SunndariIconBubble(icon: icon, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
            ),
            Icon(selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded, size: 22, color: AiraColors.rose),
          ],
        ),
      ),
    );
  }
}
