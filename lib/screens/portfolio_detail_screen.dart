// FILE: screens/portfolio_detail_screen.dart
// SCREEN: Portfolio Detail — full photo, approval status, edit caption, delete.
//
// APIs used:
//   GET /artists/portfolio/get/   (latest copy of this item when the screen opens)
//   PUT /artists/portfolio/update/
//   DELETE /artists/portfolio/delete/

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../models/artist/update_portfolio.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';

/// SCREEN: Portfolio Detail — full photo, approval status, edit caption, delete.
class PortfolioDetailScreen extends StatefulWidget {
  final Portfolio portfolio;
  const PortfolioDetailScreen({super.key, required this.portfolio});

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

/// State of [PortfolioDetailScreen] — holds the screen data and logic.
class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  late Portfolio _portfolio;
  bool _saving = false;
  bool _changed = false;

  /// Runs once when the screen opens.
  @override
  void initState() {
    super.initState();
    _portfolio = widget.portfolio;
    _refresh();
  }

  /// Fetches the latest copy of this item (caption, approval status). If it fails the list copy stays on screen.
  /// API: artistService.getPortfolio → GET /artists/portfolio/get/
  Future<void> _refresh() async {
    try {
      final fresh = await ServiceLocator.artistService.getPortfolio(widget.portfolio.portfolioId);
      if (mounted) setState(() => _portfolio = fresh);
    } catch (_) {}
  }

  /// Approval label.
  String _approvalLabel(int? id) {
    if (id == null) return 'Pending Review';
    return 'Status #$id';
  }

  /// Edits caption.
  /// API: artistService.updatePortfolio → PUT /artists/portfolio/update/
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
            Text('Edit Caption', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
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
      // API call: artistService.updatePortfolio → PUT /artists/portfolio/update/
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
      AppFeedback.showSuccess(context, 'Caption Updated ✓');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Deletes the item.
  /// API: artistService.deletePortfolio → DELETE /artists/portfolio/delete/
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete This Item?'),
        content: const Text('This Will Remove It From Your Portfolio For Good.'),
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
      // API call: artistService.deletePortfolio → DELETE /artists/portfolio/delete/
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

  /// Builds the UI.
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
                  SunndariBackChip(onTap: () => Navigator.of(context).pop(_changed)),
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
                          _portfolio.caption?.isNotEmpty == true ? _portfolio.caption! : 'No Caption',
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
