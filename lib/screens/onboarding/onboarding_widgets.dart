// FILE: screens/onboarding/onboarding_widgets.dart
// WIDGETS: shared onboarding UI — hero banner, scaffold, labels, fields, image picker, tip box, Aadhaar formatter.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../utils/media_url.dart';

/// Enum: Onb Art values.
enum OnbArt { welcome, details, documents, services, agreement, review }

const Map<OnbArt, String> _onbPhotoUrls = {
  OnbArt.welcome: 'https://images.unsplash.com/photo-1709477542149-f4e0e21d590b?w=1200&q=80',
  OnbArt.details: 'https://koala.sh/api/image/v2-o8sjr-lb6qg.jpg?width=1216&height=832&dream',
  OnbArt.documents: 'https://images.unsplash.com/photo-1576243165717-ce0a37f0ac8b?w=1200&q=80',
  OnbArt.services: 'https://images.unsplash.com/photo-1596704017254-9b121068fb31?w=1200&q=80',
  OnbArt.agreement: 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=1200&q=80',
  OnbArt.review: 'https://images.unsplash.com/photo-1501139083538-0139583c060f?w=1200&q=80',
};

/// Onb Hero widget.
class OnbHero extends StatelessWidget {
  final OnbArt art;
  final double height;
  final String? assetPath;

  const OnbHero({super.key, required this.art, this.height = 190, this.assetPath});

  List<IconData> get _icons {
    switch (art) {
      case OnbArt.welcome:
        return const [Icons.face_retouching_natural, Icons.brush, Icons.palette];
      case OnbArt.details:
        return const [Icons.person_outline, Icons.location_on_outlined, Icons.schedule];
      case OnbArt.documents:
        return const [Icons.badge_outlined, Icons.account_balance_outlined, Icons.verified_user_outlined];
      case OnbArt.services:
        return const [Icons.brush, Icons.photo_library_outlined, Icons.currency_rupee];
      case OnbArt.agreement:
        return const [Icons.description_outlined, Icons.verified_outlined, Icons.percent];
      case OnbArt.review:
        return const [Icons.hourglass_top, Icons.check_circle_outline, Icons.notifications_none];
    }
  }

  /// UI piece: circle.
  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  /// UI piece: badge.
  Widget _badge(IconData icon) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AiraColors.rose.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: AiraColors.roseDeep),
      );

  /// UI piece: drawn.
  Widget _drawn() {
    final icons = _icons;
    final main = icons[0];
    final left = icons[1];
    final right = icons[2];
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AiraColors.blush, AiraColors.goldSoft],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: const Alignment(-1.15, -1.2), child: _circle(150, Colors.white.withOpacity(0.35))),
          Align(alignment: const Alignment(1.2, 1.3), child: _circle(170, AiraColors.rose.withOpacity(0.12))),
          Align(alignment: const Alignment(0.85, -0.75), child: _circle(16, AiraColors.gold.withOpacity(0.45))),
          Align(alignment: const Alignment(-0.8, 0.8), child: _circle(10, AiraColors.rose.withOpacity(0.35))),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AiraGradients.avatarOrb,
              boxShadow: [
                BoxShadow(
                  color: AiraColors.rose.withOpacity(0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(main, size: 48, color: Colors.white),
          ),
          Align(alignment: const Alignment(-0.62, -0.35), child: _badge(left)),
          Align(alignment: const Alignment(0.62, 0.4), child: _badge(right)),
          const Align(
            alignment: Alignment(0.55, -0.8),
            child: Icon(Icons.auto_awesome, size: 18, color: AiraColors.gold),
          ),
        ],
      ),
    );
  }

  /// UI piece: photo.
  Widget _photo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.network(
        _onbPhotoUrls[art]!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AiraColors.rose),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _drawn(),
      ),
    );
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    if (assetPath == null) return _photo();
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.asset(
        assetPath!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photo(),
      ),
    );
  }
}

/// Onb Scaffold widget.
class OnbScaffold extends StatelessWidget {
  final int step;
  final String? partLabel;
  final String title;
  final String? subtitle;
  final OnbArt art;
  final List<Widget> children;
  final String ctaLabel;
  final VoidCallback? onCta;
  final VoidCallback onBack;
  final String? error;

  const OnbScaffold({
    super.key,
    required this.step,
    this.partLabel,
    required this.title,
    this.subtitle,
    required this.art,
    required this.children,
    required this.ctaLabel,
    required this.onCta,
    required this.onBack,
    this.error,
  });

  /// Bar title.
  String get _barTitle {
    switch (art) {
      case OnbArt.welcome:
        return 'Welcome';
      case OnbArt.details:
        return 'Professional Details';
      case OnbArt.documents:
        return 'Document Verification';
      case OnbArt.services:
        return 'Services & Portfolio';
      case OnbArt.agreement:
        return 'Partner Agreement';
      case OnbArt.review:
        return 'Application Status';
    }
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SunndariBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: SunndariFlowBar(title: _barTitle, onBack: onBack),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: SunndariTitle(title: title, subtitle: subtitle, size: 32)),
                      const SizedBox(height: 22),
                      ...children,
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AiraColors.errorText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error!,
                              style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    PrimaryButton(label: ctaLabel, arrow: true, expand: true, onTap: onCta),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onb Label widget.
class OnbLabel extends StatelessWidget {
  final String text;
  const OnbLabel(this.text, {super.key});

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AiraText.serif(fontSize: 15.5)),
    );
  }
}

/// Onb Field widget.
class OnbField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? hint;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;
  final bool showLabel;
  final bool plainLabel;
  final String? optionalTag;

  const OnbField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.hint,
    this.capitalization = TextCapitalization.none,
    this.formatters,
    this.showLabel = true,
    this.plainLabel = false,
    this.optionalTag,
  });

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    label,
                    style: plainLabel
                        ? AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft)
                        : AiraText.serif(fontSize: 15.5),
                  ),
                  if (optionalTag != null) ...[
                    const SizedBox(width: 8),
                    Text(optionalTag!, style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                  ],
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AiraColors.pinkFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AiraColors.pinkBorder, width: 1.1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              maxLength: maxLength,
              textCapitalization: capitalization,
              inputFormatters: formatters,
              cursorColor: AiraColors.roseDeep,
              style: AiraText.sans(fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: hint,
                hintStyle: AiraText.sans(fontSize: 14, color: AiraColors.charcoalSoft.withOpacity(0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter: Dashed Border Painter.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, this.radius = 14});

  /// Draws the shape on the canvas.
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  /// Tells Flutter whether to repaint.
  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

/// Onb Image Picker widget.
class OnbImagePicker extends StatelessWidget {
  final String label;
  final String hint;
  final String? hint2;
  final IconData icon;
  final double height;
  final XFile? picked;
  final String? existingUrl;
  final VoidCallback onTap;

  const OnbImagePicker({
    super.key,
    required this.label,
    required this.hint,
    this.hint2,
    required this.picked,
    required this.existingUrl,
    required this.onTap,
    this.icon = Icons.note_add_outlined,
    this.height = 130,
  });

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final hasExisting = existingUrl != null && existingUrl!.isNotEmpty;
    final hasImage = picked != null || hasExisting;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(color: AiraColors.pinkBorder),
        child: Container(
          height: height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AiraColors.pinkFill.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    picked != null
                        ? Image.file(File(picked!.path), fit: BoxFit.cover)
                        : Image.network(
                            resolveMediaUrl(existingUrl)!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined, color: AiraColors.charcoalSoft),
                            ),
                          ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Change',
                            style: AiraText.sans(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 34, color: AiraColors.roseDeep),
                    const SizedBox(height: 8),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: AiraText.serif(fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(hint,
                        textAlign: TextAlign.center,
                        style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                    if (hint2 != null)
                      Text(hint2!,
                          textAlign: TextAlign.center,
                          style: AiraText.sans(fontSize: 11.5, color: AiraColors.charcoalSoft)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Onb Tip widget.
class OnbTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const OnbTip({super.key, required this.text, this.icon = Icons.lightbulb_outline});

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AiraColors.pinkFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AiraColors.hair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AiraColors.roseDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoal, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the user pick onb image.
Future<XFile?> pickOnbImage() =>
    ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);

/// Input formatter: Aadhaar Input Formatter.
class AadhaarInputFormatter extends TextInputFormatter {
  /// Formats the text while the user types.
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 12 ? digits.substring(0, 12) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(capped[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Aadhaar digits.
String aadhaarDigits(String v) => v.replaceAll(RegExp(r'\D'), '');

/// Formats Aadhaar.
String formatAadhaar(String? digits) {
  final d = aadhaarDigits(digits ?? '');
  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && i % 4 == 0) buf.write(' ');
    buf.write(d[i]);
  }
  return buf.toString();
}
