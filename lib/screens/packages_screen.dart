import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/artist/package.dart';
import '../models/artist/create_package.dart';
import '../models/artist/update_package.dart';
import '../models/core/service_sub_category.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  bool _loading = true;
  String? _error;
  List<Package> _items = [];
  List<ServiceSubCategory> _subCategories = [];

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
        ServiceLocator.artistService.getAllPackages(limit: 30),
        ServiceLocator.coreService.getAllServiceSubCategories(limit: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0].data as List<Package>;
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

  Future<void> _delete(Package p) async {
    setState(() => _items = _items.where((x) => x.packageId != p.packageId).toList());
    try {
      await ServiceLocator.artistService.deletePackage(p.packageId);
      if (mounted) AppFeedback.showSuccess(context, 'Package deleted');
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  /// Shared form for both "Add package" and "Edit package". When [existing]
  /// is non-null this calls PUT /artists/packages/update/ instead of
  /// POST /artists/packages/create/ — updatePackage() already existed in
  /// artist_service.dart but no screen was calling it.
  Future<void> _openForm({Package? existing}) async {
    if (_subCategories.isEmpty) {
      AppFeedback.showWarning(context, 'Add a service first, then create a package for it');
      return;
    }
    final isEdit = existing != null;
    int subCategoryId = existing?.subCategoryId ?? _subCategories.first.subCategoryId;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final durationCtrl = TextEditingController(text: (existing?.durationMinutes ?? 60).toString());
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    bool isActive = existing?.isActive ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AiraColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          Widget field(String label, TextEditingController c, {TextInputType? type}) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                      color: AiraColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiraColors.hair)),
                  child: TextField(
                    controller: c,
                    keyboardType: type,
                    decoration: InputDecoration(border: InputBorder.none, hintText: label),
                  ),
                ),
              );

          return Padding(
            padding: EdgeInsets.only(
                left: 24, right: 24, top: 20, bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Edit package' : 'New package', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: AiraColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiraColors.hair)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: subCategoryId,
                        items: _subCategories
                            .map((s) => DropdownMenuItem(value: s.subCategoryId, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) => setSheet(() => subCategoryId = v!),
                      ),
                    ),
                  ),
                  field('Package name (e.g. Bridal Glam)', nameCtrl),
                  field('Price (₹)', priceCtrl, type: TextInputType.number),
                  field('Duration (minutes)', durationCtrl, type: TextInputType.number),
                  field('Description (optional)', descCtrl),
                  if (isEdit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Active — visible to clients for booking',
                                style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft)),
                          ),
                          Switch(
                            value: isActive,
                            activeColor: AiraColors.rose,
                            onChanged: (v) => setSheet(() => isActive = v),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  PrimaryButton(
                    label: isEdit ? 'Save changes' : 'Create package',
                    expand: true,
                    onTap: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (saved != true) return;
    if (nameCtrl.text.trim().isEmpty || double.tryParse(priceCtrl.text.trim()) == null) {
      AppFeedback.showWarning(context, 'Enter a name and a valid price');
      return;
    }

    try {
      if (isEdit) {
        await ServiceLocator.artistService.updatePackage(UpdatePackage(
          packageId: existing.packageId,
          subCategoryId: subCategoryId,
          name: nameCtrl.text.trim(),
          price: double.parse(priceCtrl.text.trim()),
          durationMinutes: int.tryParse(durationCtrl.text.trim()) ?? 60,
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          isActive: isActive,
        ));
        await _load();
        if (mounted) AppFeedback.showSuccess(context, 'Package updated ✓');
      } else {
        await ServiceLocator.artistService.createPackage(CreatePackage(
          subCategoryId: subCategoryId,
          name: nameCtrl.text.trim(),
          price: double.parse(priceCtrl.text.trim()),
          durationMinutes: int.tryParse(durationCtrl.text.trim()) ?? 60,
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        ));
        await _load();
        if (mounted) AppFeedback.showSuccess(context, 'Package created ✓');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
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
                  Expanded(child: Text('My packages', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600))),
                  PrimaryButton(label: 'Add', small: true, icon: Icons.add, onTap: () => _openForm()),
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
                              child: Text('No packages yet — add one so clients can book it.',
                                  textAlign: TextAlign.center,
                                  style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final p = _items[i];
                                return AiraCard(
                                  padding: const EdgeInsets.all(14),
                                  onTap: () => _openForm(existing: p),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name, style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 3),
                                            Text('₹${p.price.toStringAsFixed(0)} · ${p.durationMinutes} min'
                                                '${p.isActive ? '' : ' · Inactive'}',
                                                style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, size: 16, color: AiraColors.charcoalSoft),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _delete(p),
                                        child: const Icon(Icons.delete_outline, size: 18, color: AiraColors.errorText),
                                      ),
                                    ],
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
