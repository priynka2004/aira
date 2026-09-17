import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../models/artist/update_portfolio.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';

/// Full-detail view for a single portfolio item. Opened by tapping a tile in
/// [PortfolioManageScreen]. Lets the artist see the full-size image, its
/// approval status, and edit the caption — wiring up
/// PUT /artists/portfolio/update/, which existed in the API layer but had no
/// screen calling it anywhere in the app.
class PortfolioDetailScreen extends StatefulWidget {
  final Portfolio portfolio;
  const PortfolioDetailScreen({super.key, required this.portfolio});

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  late Portfolio _portfolio;
  bool _saving = false;
  // True if anything changed (caption edited or item deleted) — tells the
  // screen that opened this one whether it needs to refresh its list.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _portfolio = widget.portfolio;
  }

  String _approvalLabel(int? id) {
    // Best-effort label — the app doesn't currently fetch
    // /core/approval-status/get_all/ on this screen to resolve the real
    // name, so this stays a neutral fallback rather than guessing wrong.
    if (id == null) return 'Pending review';
    return 'Status #$id';
  }

  Future<void> _editCaption() async {
    final ctrl = TextEditingController(text: _portfolio.caption ?? '');
    final newCaption = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AiraColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit caption', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: AiraColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiraColors.hair)),
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Caption'),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Save', expand: true, onTap: () => Navigator.of(ctx).pop(ctrl.text.trim())),
          ],
        ),
      ),
    );
    if (newCaption == null || newCaption == (_portfolio.caption ?? '')) return;

    setState(() => _saving = true);
    try {
      await ServiceLocator.artistService.updatePortfolio(
        UpdatePortfolio(portfolioId: _portfolio.portfolioId, caption: newCaption),
      );
      if (!mounted) return;
      setState(() {
        _portfolio = Portfolio(
          portfolioId: _portfolio.portfolioId,
          artistId: _portfolio.artistId,
          fileUrl: _portfolio.fileUrl,
          mediaType: _portfolio.mediaType,
          subCategoryId: _portfolio.subCategoryId,
          caption: newCaption,
          approvalStatusId: _portfolio.approvalStatusId,
          isActive: _portfolio.isActive,
          createdAt: _portfolio.createdAt,
          updatedAt: DateTime.now(),
        );
        _changed = true;
      });
      AppFeedback.showSuccess(context, 'Caption updated ✓');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This will remove it from your portfolio for good.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AiraColors.errorText)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await ServiceLocator.artistService.deletePortfolio(_portfolio.portfolioId);
      _changed = true;
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_changed),
                    child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _saving ? null : _delete,
                    child: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Center(
                  child: Image.network(
                    resolveMediaUrl(_portfolio.fileUrl) ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _portfolio.caption?.isNotEmpty == true ? _portfolio.caption! : 'No caption',
                          style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: _saving ? null : _editCaption,
                        child: const Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_portfolio.mediaType} · ${_approvalLabel(_portfolio.approvalStatusId)}',
                    style: AiraText.sans(fontSize: 12, color: Colors.white54),
                  ),
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
