import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../utils/app_feedback.dart';

/// Generic rounded card — mirrors the React `<Card>` primitive.
class AiraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const AiraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AiraColors.card,
    this.gradient,
    this.borderColor = AiraColors.hair,
    this.borderWidth = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: clipBehavior,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(color: Color(0x0F2C2320), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: card,
    );
  }
}

/// Pill-shaped toggle/filter button — mirrors `<Pill>`.
class AiraPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const AiraPill({super.key, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AiraGradients.aira : null,
          color: active ? null : AiraColors.card,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: AiraColors.hair),
        ),
        child: Text(
          label,
          style: AiraText.sans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AiraColors.charcoal,
          ),
        ),
      ),
    );
  }
}

/// Solid rose call-to-action button — mirrors `<PrimaryBtn>`.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool small;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.small = false,
    this.onTap,
    this.background = AiraColors.rose,
    this.foreground = Colors.white,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: small ? 15 : 17, color: foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AiraText.sans(
            fontSize: small ? 13 : 15,
            fontWeight: FontWeight.w500,
            color: foreground,
          ),
        ),
      ],
    );

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20, vertical: small ? 10 : 14),
          child: child,
        ),
      ),
    );
  }
}

/// Outlined button — mirrors `<GhostBtn>`.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool small;
  final VoidCallback? onTap;
  final Color color;

  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.small = false,
    this.onTap,
    this.color = AiraColors.charcoal,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20, vertical: small ? 10 : 14),
          decoration: BoxDecoration(
            border: Border.all(color: AiraColors.hair),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 15 : 17, color: color),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AiraText.sans(fontSize: small ? 10 : 12, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The glowing gradient sparkle avatar used for AiRA — mirrors `<AiraOrb>`.
class AiraOrb extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const AiraOrb({super.key, this.size = 44, this.onTap});

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AiraGradients.avatarOrb,
        boxShadow: [
          BoxShadow(color: AiraColors.blush, blurRadius: 0, spreadRadius: 4),
        ],
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.42),
    );

    if (onTap == null) return orb;
    return GestureDetector(onTap: onTap, child: orb);
  }
}

/// Centered "something went wrong" state with a Retry button — used
/// wherever a screen's initial data load fails outright.
class AiraErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AiraErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Every screen in the app just does `catch (e) { _error =
    // e.toString(); }` and hands that straight to this widget — so this
    // is the one place that needs to guard against a raw backend/DB
    // crash dump ending up on screen, regardless of which screen caught
    // it. See AppFeedback.friendlyMessage for what gets filtered.
    final displayMessage = AppFeedback.friendlyMessage(message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 28, color: AiraColors.errorText),
            const SizedBox(height: 10),
            Text(displayMessage,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft)),
            const SizedBox(height: 14),
            GhostButton(label: 'Retry', icon: Icons.refresh, small: true, onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Screen header with optional back button — mirrors `<ScreenHeader>`.
class AiraScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const AiraScreenHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
            ),
            const SizedBox(width: 12),
          ],
          Text(title, style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Small floating confirmation snackbar-style toast — mirrors `<Toast>`.
class AiraToast extends StatelessWidget {
  final String text;
  const AiraToast({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 96,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AiraColors.charcoal,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: AiraColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 11, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(text, style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItemData {
  final IconData icon;
  final String label;
  final String key;
  const NavItemData({required this.icon, required this.label, required this.key});
}

const kNavItems = [
  NavItemData(icon: Icons.wb_sunny_outlined, label: 'Home', key: 'home'),
  NavItemData(icon: Icons.trending_up, label: 'Business', key: 'business'),
  NavItemData(icon: Icons.auto_awesome, label: 'Grow', key: 'grow'),
  NavItemData(icon: Icons.school_outlined, label: 'Learn', key: 'learn'),
  NavItemData(icon: Icons.person_outline, label: 'Profile', key: 'profile'),
];

/// Bottom navigation bar — mirrors `<BottomNav>`.
class AiraBottomNav extends StatelessWidget {
  final String active;
  final ValueChanged<String> onSelect;

  const AiraBottomNav({super.key, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AiraColors.card,
        border: Border(top: BorderSide(color: AiraColors.hair)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: kNavItems.map((item) {
          final isActive = active == item.key;
          return GestureDetector(
            onTap: () => onSelect(item.key),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 20, color: isActive ? AiraColors.rose : AiraColors.charcoalSoft),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: AiraText.sans(
                    fontSize: 10,
                    color: isActive ? AiraColors.rose : AiraColors.charcoalSoft,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Formats a [DateTimeRange] as a compact human label, e.g. "3 Jan – 9 Jan",
/// or "28 Dec 2025 – 3 Jan 2026" when the range spans a year boundary.
String formatAiraDateRange(DateTimeRange range) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String short(DateTime d) => '${d.day} ${months[d.month - 1]}';
  String full(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';
  if (range.start.year != range.end.year) {
    return '${full(range.start)} – ${full(range.end)}';
  }
  return '${short(range.start)} – ${short(range.end)}';
}

/// Opens a date-range picker themed to match the AiRA palette. Defaults to
/// letting people reach back up to 3 years, so past bookings/earnings are
/// always reachable — not just the current week.
Future<DateTimeRange?> pickAiraDateRange(
    BuildContext context, {
      DateTimeRange? initialRange,
      DateTime? firstDate,
      DateTime? lastDate,
    }) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return showDateRangePicker(
    context: context,
    firstDate: firstDate ?? DateTime(now.year - 3),
    lastDate: lastDate ?? today,
    initialDateRange: initialRange,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AiraColors.rose,
            onPrimary: Colors.white,
            surface: AiraColors.card,
            onSurface: AiraColors.charcoal,
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Small calendar icon + label chip that opens (and optionally clears) a
/// date-range filter. Used on Bookings, Finance and Insights so people can
/// look back at old dates, not just the current week.
class AiraDateRangeButton extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String placeholder;

  const AiraDateRangeButton({
    super.key,
    required this.range,
    required this.onTap,
    this.onClear,
    this.placeholder = 'Date range',
  });

  @override
  Widget build(BuildContext context) {
    final active = range != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AiraColors.blush : AiraColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AiraColors.rose : AiraColors.hair),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: active ? AiraColors.roseDeep : AiraColors.charcoalSoft),
            const SizedBox(width: 6),
            Text(
              active ? formatAiraDateRange(range!) : placeholder,
              style: AiraText.sans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: active ? AiraColors.roseDeep : AiraColors.charcoalSoft,
              ),
            ),
            if (active && onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: AiraColors.roseDeep),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SegTabItem {
  final String key;
  final String label;
  const SegTabItem(this.key, this.label);
}

/// Confirmation dialog shown before cancelling a booking. Captures a short
/// reason (e.g. "Not available on this date") that gets sent to the backend
/// with the cancel request and surfaced to the customer — previously Cancel
/// fired the API immediately with no reason at all, so the customer only
/// ever saw a generic "This booking was cancelled." with no explanation.
///
/// Returns the trimmed reason string to proceed with cancellation (may be
/// empty if the artist skips it), or `null` if the artist backed out and
/// the booking should NOT be cancelled.
/// [isReject] switches the copy from "Cancel booking" (an already-confirmed
/// booking the artist can no longer honour) to "Reject booking" (a
/// still-`pending` request the artist is declining before ever accepting
/// it) — same reason-collection flow either way, since both end up as the
/// booking's `cancellationReason` and both need to tell the customer why.
Future<String?> showAiraCancelReasonDialog(BuildContext context, {String clientName = '', bool isReject = false}) {
  final controller = TextEditingController();
  const presets = [
    'Not available on this date',
    'Not available at this time',
    'Personal emergency',
  ];
  final verb = isReject ? 'Reject' : 'Cancel';

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              '$verb booking${clientName.isNotEmpty ? ' with $clientName' : ''}?',
              style: AiraText.serif(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReject
                      ? "Let the client know why — this is shown to them as the reason you're not available."
                      : 'Let the client know why — this is shown to them as the cancellation reason.',
                  style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets.map((p) {
                    return GestureDetector(
                      onTap: () => setState(() => controller.text = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: controller.text == p ? AiraColors.rose.withOpacity(0.12) : AiraColors.bg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: controller.text == p ? AiraColors.rose : AiraColors.hair),
                        ),
                        child: Text(p, style: AiraText.sans(fontSize: 11.5)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 2,
                  style: AiraText.sans(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: isReject ? 'Reason for declining (optional)' : 'Reason for cancelling (optional)',
                    hintStyle: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(isReject ? 'Keep request' : 'Keep booking',
                    style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft)),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
                child: Text('$verb booking',
                    style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AiraColors.errorText)),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Horizontal segmented pill-tab row — mirrors `<SegTabs>`.
class AiraSegTabs extends StatelessWidget {
  final List<SegTabItem> tabs;
  final String active;
  final ValueChanged<String> onSelect;

  const AiraSegTabs({super.key, required this.tabs, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs
              .map((t) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AiraPill(
              label: t.label,
              active: active == t.key,
              onTap: () => onSelect(t.key),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }
}
