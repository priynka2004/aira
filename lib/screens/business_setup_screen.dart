import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/auth/add_location.dart';
import '../models/auth/set_schedule.dart';
import '../models/auth/add_block.dart';
import '../models/artist/add_service.dart';
import '../models/core/service_sub_category.dart';
import '../models/core/location_type.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

List<dynamic> _asList(dynamic json) {
  if (json is List) return json;
  if (json is Map && json['data'] is List) return json['data'] as List;
  return const [];
}

/// One screen, three tabs — mirrors the artist's "business setup" area of
/// the Sunndari app: which services they offer, where they work, and when.
class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  String _tab = 'services';
  bool _loading = true;
  String? _error;

  List<ServiceSubCategory> _subCategories = [];
  List<LocationType> _locationTypes = [];
  List<dynamic> _myServices = [];
  List<dynamic> _myLocations = [];
  List<dynamic> _mySchedule = [];
  List<dynamic> _myBlocks = [];

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
        ServiceLocator.coreService.getAllServiceSubCategories(limit: 100),
        ServiceLocator.coreService.getAllLocationTypes(limit: 50),
        ServiceLocator.artistService.getAllServices(),
        ServiceLocator.artistService.getAllLocations(),
        ServiceLocator.artistService.getAllSchedules(),
        ServiceLocator.artistService.getAllBlocks(),
      ]);
      if (!mounted) return;
      setState(() {
        _subCategories = results[0].data as List<ServiceSubCategory>;
        _locationTypes = results[1].data as List<LocationType>;
        _myServices = _asList(results[2]);
        _myLocations = _asList(results[3]);
        _mySchedule = _asList(results[4]);
        _myBlocks = _asList(results[5]);
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

  String _subCategoryName(int? id) {
    final m = _subCategories.where((s) => s.subCategoryId == id);
    return m.isNotEmpty ? m.first.name : 'Service #$id';
  }

  String _locationTypeName(int? id) {
    final m = _locationTypes.where((l) => l.locationTypeId == id);
    return m.isNotEmpty ? m.first.name : 'Location #$id';
  }

  // ── Services ────────────────────────────────────────────────────────
  Future<void> _addService() async {
    final available =
        _subCategories.where((s) => !_myServices.any((m) => m['subCategoryId'] == s.subCategoryId)).toList();
    if (available.isEmpty) {
      AppFeedback.showInfo(context, 'You already offer every listed service');
      return;
    }
    int selected = available.first.subCategoryId;
    final priceCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AiraColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a service', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AiraColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiraColors.hair)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selected,
                    items: available.map((s) => DropdownMenuItem(value: s.subCategoryId, child: Text(s.name))).toList(),
                    onChanged: (v) => setSheet(() => selected = v!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AiraColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiraColors.hair)),
                child: TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Your price for this (optional)'),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Add service', expand: true, onTap: () => Navigator.of(ctx).pop(true)),
            ],
          ),
        );
      }),
    );

    if (ok != true) return;
    try {
      await ServiceLocator.artistService.addService(AddService(
        subCategoryId: selected,
        customPrice: double.tryParse(priceCtrl.text.trim()),
      ));
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  Future<void> _removeService(int subCategoryId) async {
    setState(() => _myServices = _myServices.where((m) => m['subCategoryId'] != subCategoryId).toList());
    try {
      await ServiceLocator.artistService.removeService(subCategoryId);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  // ── Locations ───────────────────────────────────────────────────────
  Future<void> _addLocation() async {
    final available =
        _locationTypes.where((l) => !_myLocations.any((m) => m['locationTypeId'] == l.locationTypeId)).toList();
    if (available.isEmpty) {
      AppFeedback.showInfo(context, 'All location types already added');
      return;
    }
    int selected = available.first.locationTypeId;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AiraColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a location type', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AiraColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiraColors.hair)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selected,
                    items: available.map((l) => DropdownMenuItem(value: l.locationTypeId, child: Text(l.name))).toList(),
                    onChanged: (v) => setSheet(() => selected = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Add location', expand: true, onTap: () => Navigator.of(ctx).pop(true)),
            ],
          ),
        );
      }),
    );
    if (ok != true) return;
    try {
      await ServiceLocator.artistService.addLocation(AddLocation(locationTypeId: selected));
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  Future<void> _removeLocation(int locationTypeId) async {
    setState(() => _myLocations = _myLocations.where((m) => m['locationTypeId'] != locationTypeId).toList());
    try {
      await ServiceLocator.artistService.removeLocation(locationTypeId);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  // ── Schedule ────────────────────────────────────────────────────────
  Future<void> _setDay(int dayOfWeek) async {
    final existing = _mySchedule.where((s) => s['dayOfWeek'] == dayOfWeek);
    TimeOfDay start = existing.isNotEmpty ? _parseTime(existing.first['startTime']) : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = existing.isNotEmpty ? _parseTime(existing.first['endTime']) : const TimeOfDay(hour: 18, minute: 0);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AiraColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> pick(bool isStart) async {
          final picked = await showTimePicker(context: ctx, initialTime: isStart ? start : end);
          if (picked != null) setSheet(() => isStart ? start = picked : end = picked);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_dayNames[dayOfWeek]} availability', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: GhostButton(label: 'Start ${start.format(ctx)}', onTap: () => pick(true))),
                  const SizedBox(width: 10),
                  Expanded(child: GhostButton(label: 'End ${end.format(ctx)}', onTap: () => pick(false))),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Save', expand: true, onTap: () => Navigator.of(ctx).pop(true)),
            ],
          ),
        );
      }),
    );
    if (ok != true) return;
    try {
      await ServiceLocator.artistService.setSchedule(SetSchedule(
        dayOfWeek: dayOfWeek,
        startTime: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
        endTime: '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
      ));
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  TimeOfDay _parseTime(dynamic v) {
    try {
      final parts = v.toString().split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<void> _removeDay(int dayOfWeek) async {
    setState(() => _mySchedule = _mySchedule.where((s) => s['dayOfWeek'] != dayOfWeek).toList());
    try {
      await ServiceLocator.artistService.removeSchedule(dayOfWeek);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  Future<void> _addBlock() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final dateStr = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      await ServiceLocator.artistService.addBlock(AddBlock(blockDate: dateStr));
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  Future<void> _removeBlock(String blockDate) async {
    setState(() => _myBlocks = _myBlocks.where((b) => b['blockDate'] != blockDate).toList());
    try {
      await ServiceLocator.artistService.removeBlock(blockDate);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
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
            AiraScreenHeader(title: 'Business setup', onBack: () => Navigator.of(context).pop()),
            AiraSegTabs(
              tabs: const [
                SegTabItem('services', 'Services'),
                SegTabItem('locations', 'Locations'),
                SegTabItem('schedule', 'Schedule'),
              ],
              active: _tab,
              onSelect: (t) => setState(() => _tab = t),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : _error != null
                      ? AiraErrorState(message: _error!, onRetry: _load)
                      : _buildTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 'locations':
        return _listSection(
          items: _myLocations,
          onAdd: _addLocation,
          addLabel: 'Add location',
          rowBuilder: (m) => _row(_locationTypeName(m['locationTypeId']), null, () => _removeLocation(m['locationTypeId'])),
          emptyText: 'No service locations yet — add where you work (salon / home visit / etc).',
        );
      case 'schedule':
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            ...List.generate(7, (i) {
              final existing = _mySchedule.where((s) => s['dayOfWeek'] == i);
              final has = existing.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AiraCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => _setDay(i),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text(_dayNames[i], style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600))),
                      Expanded(
                        child: Text(
                          has ? '${existing.first['startTime']} – ${existing.first['endTime']}' : 'Not available',
                          style: AiraText.sans(fontSize: 13, color: has ? AiraColors.charcoal : AiraColors.charcoalSoft),
                        ),
                      ),
                      if (has)
                        GestureDetector(
                          onTap: () => _removeDay(i),
                          child: const Icon(Icons.close, size: 16, color: AiraColors.errorText),
                        )
                      else
                        const Icon(Icons.chevron_right, size: 16, color: AiraColors.charcoalSoft),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Text('BLOCKED DATES', style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
            const SizedBox(height: 8),
            ..._myBlocks.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _row(b['blockDate']?.toString() ?? '', b['note']?.toString(), () => _removeBlock(b['blockDate']?.toString() ?? '')),
                )),
            const SizedBox(height: 8),
            GhostButton(label: 'Block a date', icon: Icons.event_busy_outlined, onTap: _addBlock),
          ],
        );
      case 'services':
      default:
        return _listSection(
          items: _myServices,
          onAdd: _addService,
          addLabel: 'Add service',
          rowBuilder: (m) => _row(
            _subCategoryName(m['subCategoryId']),
            m['customPrice'] != null ? '₹${m['customPrice']}' : null,
            () => _removeService(m['subCategoryId']),
          ),
          emptyText: 'No services added yet — add the services you offer clients.',
        );
    }
  }

  Widget _listSection({
    required List<dynamic> items,
    required VoidCallback onAdd,
    required String addLabel,
    required Widget Function(Map<String, dynamic>) rowBuilder,
    required String emptyText,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(emptyText, style: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft)),
          )
        else
          ...items.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: rowBuilder(Map<String, dynamic>.from(m as Map)),
              )),
        const SizedBox(height: 8),
        GhostButton(label: addLabel, icon: Icons.add, onTap: onAdd),
      ],
    );
  }

  Widget _row(String title, String? subtitle, VoidCallback onRemove) {
    return AiraCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AiraText.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
              ],
            ),
          ),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 16, color: AiraColors.errorText)),
        ],
      ),
    );
  }
}
