import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/portfolio.dart';
import '../models/artist/create_portfolio.dart';
import '../models/core/service_sub_category.dart';
import '../models/enums/media_type_enum.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../utils/media_url.dart';
import 'portfolio_detail_screen.dart';

class PortfolioManageScreen extends StatefulWidget {
  const PortfolioManageScreen({super.key});

  @override
  State<PortfolioManageScreen> createState() => _PortfolioManageScreenState();
}

class _PortfolioManageScreenState extends State<PortfolioManageScreen> {
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<Portfolio> _items = [];
  List<ServiceSubCategory> _subCategories = [];

  /// portfolioId currently being downloaded/shared, so we can show a small
  /// spinner on just that tile's share button instead of blocking the UI.
  int? _sharingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ServiceLocator.artistService.getAllPortfolios(limit: 30),
        ServiceLocator.coreService.getAllServiceSubCategories(limit: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0].data as List<Portfolio>;
        _subCategories = results[1].data as List<ServiceSubCategory>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (xfile == null) return;
    if (!mounted) return;

    int? subCategoryId =
    _subCategories.isNotEmpty ? _subCategories.first.subCategoryId : null;

    final captionCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AiraColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add to portfolio',
                      style: AiraText.serif(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_subCategories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AiraColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AiraColors.hair),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: subCategoryId,
                            items: _subCategories
                                .map(
                                  (s) => DropdownMenuItem<int>(
                                value: s.subCategoryId,
                                child: Text(s.name),
                              ),
                            )
                                .toList(),
                            onChanged: (value) {
                              setSheet(() {
                                subCategoryId = value;
                              });
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: AiraColors.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AiraColors.hair),
                      ),
                      child: TextField(
                        controller: captionCtrl,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Caption (optional)",
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Upload',
                      expand: true,
                      onTap: () {
                        Navigator.pop(ctx, true);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _uploading = true);

    try {
      await ServiceLocator.artistService.createPortfolio(
        CreatePortfolio(
          mediaType: MediaTypeEnum.image,
          subCategoryId: subCategoryId ?? 1,
          file: xfile,
          caption: captionCtrl.text.trim().isEmpty
              ? null
              : captionCtrl.text.trim(),
        ),
      );

      await _load();

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'Added to your portfolio ✓',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    } finally {
      captionCtrl.dispose();

      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _delete(Portfolio p) async {
    setState(() => _items = _items.where((x) => x.portfolioId != p.portfolioId).toList());
    try {
      await ServiceLocator.artistService.deletePortfolio(p.portfolioId);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  /// Best-guess file extension from the media URL, so the shared file opens
  /// correctly in whatever app the person picks (WhatsApp, Gallery, etc).
  String _extensionFromUrl(String url) {
    final clean = url.split('?').first;
    final dot = clean.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = clean.substring(dot);
    // Guard against a stray "." with no real extension after it.
    if (ext.length < 2 || ext.length > 5) return '.jpg';
    return ext;
  }

  /// Downloads the portfolio image to a temp file, then opens the native
  /// share sheet (WhatsApp, Instagram, Messages, etc). share_plus needs a
  /// real file on disk — it can't share a bare network URL directly.
  Future<void> _share(Portfolio p) async {
    final url = resolveMediaUrl(p.fileUrl);
    if (url == null) return;

    setState(() => _sharingId = p.portfolioId);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception("Couldn't load this image to share.");
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/portfolio_${p.portfolioId}${_extensionFromUrl(url)}');
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: (p.caption != null && p.caption!.isNotEmpty) ? p.caption : 'Shared via AiRA',
      );
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _sharingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Portfolio', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                  PrimaryButton(
                    label: _uploading ? 'Uploading…' : 'Add',
                    small: true,
                    icon: Icons.add,
                    onTap: _uploading ? null : _add,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : _error != null
                  ? AiraErrorState(message: _error!, onRetry: _load)
                  : _items.isEmpty
                  ? Center(
                child: Text('No portfolio items yet — tap Add to upload your work.',
                    textAlign: TextAlign.center,
                    style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft)),
              )
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final p = _items[i];
                  final sharingThis = _sharingId == p.portfolioId;
                  return GestureDetector(
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => PortfolioDetailScreen(portfolio: p)),
                      );
                      if (changed == true) _load();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            resolveMediaUrl(p.fileUrl) ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AiraColors.blush),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: GestureDetector(
                              onTap: sharingThis ? null : () => _share(p),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                child: sharingThis
                                    ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                    : const Icon(Icons.ios_share, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _delete(p),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                          if (p.caption != null && p.caption!.isNotEmpty)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                color: Colors.black38,
                                child: Text(p.caption!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AiraText.sans(fontSize: 11, color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
