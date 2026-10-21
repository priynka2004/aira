// FILE: screens/business_setup_screen.dart
// SCREEN: Business Setup — services offered, work locations, availability.
//
// APIs used:
//   GET /core/service-sub-category/get_all/
//   GET /core/location-type/get_all/
//   GET /artists/services/get_all/
//   GET /artists/locations/get_all/
//   GET /artists/availability/schedule/get_all/
//   GET /artists/availability/block/get_all/
//   GET /core/service-category/get_all/
//   POST /artists/services/add/
//   DELETE /artists/services/remove/
//   POST /artists/locations/add/
//   DELETE /artists/locations/remove/
//   POST /artists/availability/schedule/set/
//   DELETE /artists/availability/schedule/remove/
//   POST /artists/availability/block/add/
//   (+1 more)

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'packages_screen.dart';
import '../widgets/common.dart';
import '../models/auth/add_location.dart';
import '../models/auth/set_schedule.dart';
import '../models/auth/add_block.dart';
import '../models/artist/add_service.dart';
import '../models/core/service_category.dart';
import '../models/core/service_sub_category.dart';
import '../models/core/location_type.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../widgets/sunndari_time_picker.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// As list.
List<dynamic> _asList(dynamic json) {
  if (json is List) return json;
  if (json is Map && json['data'] is List) return json['data'] as List;
  return const [];
}

/// SCREEN: Business Setup — services offered, work locations, availability.
class BusinessSetupScreen extends StatefulWidget {
  final bool embedded;
  /// 'services' or 'locations' → show only that part (no inner switch). null → both (old behaviour).
  final String? only;
  const BusinessSetupScreen({super.key, this.embedded = false, this.only});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

/// State of [BusinessSetupScreen] — holds the screen data and logic.
class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  late String _tab = widget.only ?? 'services';
  bool _loading = true;
  String? _error;

  List<ServiceCategory> _categories = [];
  List<ServiceSubCategory> _subCategories = [];
  List<LocationType> _locationTypes = [];
  List<dynamic> _myServices = [];
  List<dynamic> _myLocations = [];
  List<dynamic> _mySchedule = [];
  List<dynamic> _myBlocks = [];

  /// Runs once when the screen opens; starts: _load().
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads this screen's data.
  /// Uses 7 APIs (see inline notes).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        // API call: coreService.getAllServiceSubCategories → GET /core/service-sub-category/get_all/
        ServiceLocator.coreService.getAllServiceSubCategories(limit: 100),
        // API call: coreService.getAllLocationTypes → GET /core/location-type/get_all/
        ServiceLocator.coreService.getAllLocationTypes(limit: 50),
        // API call: artistService.getAllServices → GET /artists/services/get_all/
        ServiceLocator.artistService.getAllServices(),
        // API call: artistService.getAllLocations → GET /artists/locations/get_all/
        ServiceLocator.artistService.getAllLocations(),
        // API call: artistService.getAllSchedules → GET /artists/availability/schedule/get_all/
        ServiceLocator.artistService.getAllSchedules(),
        // API call: artistService.getAllBlocks → GET /artists/availability/block/get_all/
        ServiceLocator.artistService.getAllBlocks(),
        // API call: coreService.getAllServiceCategories → GET /core/service-category/get_all/
        ServiceLocator.coreService.getAllServiceCategories(limit: 50),
      ]);
      if (!mounted) return;
      setState(() {
        _subCategories = results[0].data as List<ServiceSubCategory>;
        _locationTypes = results[1].data as List<LocationType>;
        _myServices = _asList(results[2]);
        _myLocations = _asList(results[3]);
        _mySchedule = _asList(results[4]);
        _myBlocks = _asList(results[5]);
        _categories = (results[6].data as List<ServiceCategory>).where((c) => c.isActive).toList();
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

  /// Sub category name.
  String _subCategoryName(int? id) {
    final m = _subCategories.where((s) => s.subCategoryId == id);
    return m.isNotEmpty ? m.first.name : 'Service #$id';
  }

  /// Location type name.
  String _locationTypeName(int? id) {
    final m = _locationTypes.where((l) => l.locationTypeId == id);
    return m.isNotEmpty ? m.first.name : 'Location #$id';
  }

  /// Adds service.
  /// API: artistService.addService → POST /artists/services/add/
  Future<void> _addService() async {
    final available =
    _subCategories.where((s) => !_myServices.any((m) => m['subCategoryId'] == s.subCategoryId)).toList();
    if (available.isEmpty) {
      AppFeedback.showInfo(context, 'You Already Offer Every Listed Service');
      return;
    }
    final cats = _categories.where((c) => available.any((s) => s.categoryId == c.categoryId)).toList();
    int? catId = cats.isNotEmpty ? cats.first.categoryId : null;
    List<ServiceSubCategory> typesOf(int? c) =>
        c == null ? available : available.where((s) => s.categoryId == c).toList();
    int selected = typesOf(catId).first.subCategoryId;
    final priceCtrl = TextEditingController();

    Widget box(Widget child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AiraColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiraColors.hair)),
      child: child,
    );

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AiraColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add A Service', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (cats.isNotEmpty) ...[
                Text('SERVICE', style: AiraText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
                const SizedBox(height: 6),
                box(DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: catId,
                    items: cats.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.name))).toList(),
                    onChanged: (v) => setSheet(() {
                      catId = v;
                      selected = typesOf(v).first.subCategoryId;
                    }),
                  ),
                )),
                const SizedBox(height: 12),
              ],
              Text('TYPE', style: AiraText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.charcoalSoft)),
              const SizedBox(height: 6),
              box(DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: selected,
                  items: typesOf(catId).map((s) => DropdownMenuItem(value: s.subCategoryId, child: Text(s.name))).toList(),
                  onChanged: (v) => setSheet(() {
                    selected = v!;
                  }),
                ),
              )),
              const SizedBox(height: 12),
              box(TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Your Price For This (Optional)'),
              )),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Add Service', expand: true, onTap: () => Navigator.of(ctx).pop(true)),
            ],
          ),
        );
      }),
    );

    if (ok != true) return;
    final rawPrice = priceCtrl.text.trim();
    final price = rawPrice.isEmpty ? null : double.tryParse(rawPrice);
    if (rawPrice.isNotEmpty && (price == null || price < 0)) {
      if (mounted) AppFeedback.showWarning(context, 'Enter A Valid, Non-Negative Price.');
      return;
    }
    try {
      // API call: artistService.addService → POST /artists/services/add/
      await ServiceLocator.artistService.addService(AddService(
        subCategoryId: selected,
        customPrice: price,
      ));
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  /// Removes service.
  /// API: artistService.removeService → DELETE /artists/services/remove/
  Future<void> _removeService(int subCategoryId) async {
    setState(() => _myServices = _myServices.where((m) => m['subCategoryId'] != subCategoryId).toList());
    try {
      // API call: artistService.removeService → DELETE /artists/services/remove/
      await ServiceLocator.artistService.removeService(subCategoryId);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  /// Adds location.
  /// API: artistService.addLocation → POST /artists/locations/add/
  Future<void> _addLocation() async {
    final available =
    _locationTypes.where((l) => !_myLocations.any((m) => m['locationTypeId'] == l.locationTypeId)).toList();
    if (available.isEmpty) {
      AppFeedback.showInfo(context, 'All Location Types Already Added');
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
              Text('Add A Location Type', style: AiraText.serif(fontSize: 18, fontWeight: FontWeight.w600)),
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
              PrimaryButton(label: 'Add Location', expand: true, onTap: () => Navigator.of(ctx).pop(true)),
            ],
          ),
        );
      }),
    );
    if (ok != true) return;
    try {
      // API call: artistService.addLocation → POST /artists/locations/add/
      await ServiceLocator.artistService.addLocation(AddLocation(locationTypeId: selected));
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  /// Removes location.
  /// API: artistService.removeLocation → DELETE /artists/locations/remove/
  Future<void> _removeLocation(int locationTypeId) async {
    setState(() => _myLocations = _myLocations.where((m) => m['locationTypeId'] != locationTypeId).toList());
    try {
      // API call: artistService.removeLocation → DELETE /artists/locations/remove/
      await ServiceLocator.artistService.removeLocation(locationTypeId);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  /// Sets day.
  /// API: artistService.setSchedule → POST /artists/availability/schedule/set/
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
          final picked = await pickSunndariTime(ctx, initial: isStart ? start : end, helpText: isStart ? 'Start Time' : 'End Time');
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
      // API call: artistService.setSchedule → POST /artists/availability/schedule/set/
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

  /// Parses time.
  TimeOfDay _parseTime(dynamic v) {
    try {
      final parts = v.toString().split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  /// Removes day.
  /// API: artistService.removeSchedule → DELETE /artists/availability/schedule/remove/
  Future<void> _removeDay(int dayOfWeek) async {
    setState(() => _mySchedule = _mySchedule.where((s) => s['dayOfWeek'] != dayOfWeek).toList());
    try {
      // API call: artistService.removeSchedule → DELETE /artists/availability/schedule/remove/
      await ServiceLocator.artistService.removeSchedule(dayOfWeek);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
      _load();
    }
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded)
          AiraScreenHeader(title: 'Business Setup', onBack: () => Navigator.of(context).pop()),
        if (widget.only == null)
          AiraSegTabs(
            tabs: const [
              SegTabItem('services', 'Services'),
              SegTabItem('locations', 'Locations'),
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
    );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(child: content),
    );
  }

  /// UI: builds tab.
  Widget _buildTab() {
    switch (_tab) {
      case 'locations':
        return _listSection(
          items: _myLocations,
          onAdd: _addLocation,
          addLabel: 'Add Location',
          rowBuilder: (m) => _row(_locationTypeName(m['locationTypeId']), null, () => _removeLocation(m['locationTypeId'])),
          emptyText: 'No Service Locations Yet — Add Where You Work (Salon / Home Visit / Etc).',
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
                          has ? '${existing.first['startTime']} – ${existing.first['endTime']}' : 'Not Available',
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
          ],
        );
      case 'services':
      default:
      // Services and their packages / prices are one thing — managed in one place.
        return const PackagesScreen(embedded: true);
    }
  }

  /// UI piece: list section.
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

  /// UI piece: row.
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