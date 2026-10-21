// FILE: screens/my_clients_screen.dart
// SCREEN: My Clients — customers served so far, with repeat-client filter (built from bookings).
//
// APIs used:
//   GET /artists/clients/get_all/       (customers with a confirmed / started / completed booking)

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';
import '../widgets/common.dart';

/// Client.
class _Client {
  final int id;
  String name;
  int completed = 0;
  String? lastDate;
  String? note;
  _Client(this.id, this.name);
}

/// SCREEN: My Clients — customers served so far, with repeat-client filter (built from bookings).
class MyClientsScreen extends StatefulWidget {
  const MyClientsScreen({super.key});

  @override
  State<MyClientsScreen> createState() => _MyClientsScreenState();
}

/// State of [MyClientsScreen] — holds the screen data and logic.
class _MyClientsScreenState extends State<MyClientsScreen> {
  bool _loading = true;
  String? _error;
  bool _repeatOnly = false;
  final _search = TextEditingController();
  List<_Client> _clients = [];

  /// Runs once when the screen opens; starts: _load().
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Loads this screen's data.
  /// Uses 3 APIs (see inline notes).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // API call: artistBusiness.getClients → GET /artists/clients/get_all/
      final list = await ServiceLocator.artistBusiness.getClients(limit: 200, sortBy: 'lastBookingDate', sortOrder: 'desc');
      final clients = list.map((c) {
        final x = _Client(c.customerId, c.name.isEmpty ? 'Customer' : c.name);
        x.completed = c.bookingCount;
        x.lastDate = c.lastBookingAt;
        x.note = c.note;
        return x;
      }).toList();
      if (!mounted) return;
      setState(() {
        _clients = clients;
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

  /// Edit the private note for a client (blank deletes it).
  /// API: artistBusiness.setClientNote → PUT /artists/clients/note/set/
  Future<void> _editNote(_Client c) async {
    final ctrl = TextEditingController(text: c.note ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note About ${c.name}'),
        content: TextField(controller: ctrl, maxLines: 4, maxLength: 1000, decoration: const InputDecoration(hintText: 'Only You Can See This')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (text == null) return;
    try {
      await ServiceLocator.artistBusiness.setClientNote(customerId: c.id, note: text);
      if (mounted) setState(() => c.note = text.isEmpty ? null : text);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    }
  }

  List<_Client> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _clients.where((c) {
      if (_repeatOnly && c.completed < 2) return false;
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  /// Repeat count.
  int get _repeatCount => _clients.where((c) => c.completed >= 2).length;

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SunndariBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SunndariAppBar(onBack: () => Navigator.of(context).pop()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: SunndariPageHeading(
                        title: 'My Clients',
                        subtitle: 'View Past Services, Booking History And Notes In One Place.',
                      ),
                    ),
                    _tag('Growth Tools'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _searchBox(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(child: _countCard(Icons.groups_2_outlined, _clients.length, 'clients')),
                    const SizedBox(width: 10),
                    Expanded(child: _countCard(Icons.favorite_border_rounded, _repeatCount, 'Repeat Clients')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AiraPill(
                        label: 'All Clients',
                        active: !_repeatOnly,
                        onTap: () => setState(() => _repeatOnly = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AiraPill(
                        label: 'Repeat Clients',
                        active: _repeatOnly,
                        onTap: () => setState(() => _repeatOnly = true),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  /// UI piece: body.
  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AiraColors.rose));
    }
    if (_error != null) return AiraErrorState(message: _error!, onRetry: _load);
    final list = _visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (list.isEmpty)
          _emptyCard()
        else
          for (final c in list) _clientRow(c),
        const SizedBox(height: 4),
        AiraCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const SunndariIconBubble(icon: Icons.lock_outline_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Use Client Details Only For Authorised Booking And Service Purposes.',
                  style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// UI piece: tag.
  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AiraColors.blush,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AiraColors.pinkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up_rounded, size: 13, color: AiraColors.rose),
            const SizedBox(width: 4),
            Text(text, style: AiraText.sans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AiraColors.roseDeep)),
          ],
        ),
      );

  /// UI: searches box.
  Widget _searchBox() => Container(
        decoration: BoxDecoration(
          color: AiraColors.pinkFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AiraColors.pinkBorder, width: 1.1),
        ),
        child: TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          cursorColor: AiraColors.roseDeep,
          style: AiraText.sans(fontSize: 14.5),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AiraColors.rose, size: 22),
            hintText: 'Search Clients',
            hintStyle: AiraText.sans(fontSize: 14, color: AiraColors.charcoalSoft.withOpacity(0.7)),
          ),
        ),
      );

  /// UI piece: count card.
  Widget _countCard(IconData icon, int n, String label) => AiraCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SunndariIconBubble(icon: icon, size: 40),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$n', style: AiraText.serif(fontSize: 22)),
                Text(label, style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft)),
              ],
            ),
          ],
        ),
      );

  /// UI piece: empty card.
  Widget _emptyCard() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AiraCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AiraColors.blush, shape: BoxShape.circle),
                child: const Icon(Icons.person_add_alt_1_rounded, size: 36, color: AiraColors.rose),
              ),
              const SizedBox(height: 16),
              Text(
                _clients.isEmpty ? 'Your Client History Starts With Your First Completed Booking.' : 'No Clients Match.',
                textAlign: TextAlign.center,
                style: AiraText.serif(fontSize: 18, height: 1.25),
              ),
              const SizedBox(height: 8),
              Text(
                'View Past Services, Booking History And Notes In One Place.',
                textAlign: TextAlign.center,
                style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft, height: 1.4),
              ),
            ],
          ),
        ),
      );

  /// UI piece: client row.
  Widget _clientRow(_Client c) {
    final initial = c.name.trim().isEmpty ? '?' : c.name.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AiraCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: AiraGradients.avatarOrb, shape: BoxShape.circle),
              child: Text(initial, style: AiraText.sans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                  const SizedBox(height: 2),
                  Text(
                    '${c.completed} ${c.completed == 1 ? 'booking' : 'bookings'}'
                    '${c.lastDate != null ? ' · last ${c.lastDate}' : ''}',
                    style: AiraText.sans(fontSize: 12, color: AiraColors.charcoalSoft),
                  ),
                  if ((c.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(c.note!, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: AiraText.sans(fontSize: 12, color: AiraColors.charcoal, height: 1.3)),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Private Note',
              onPressed: () => _editNote(c),
              icon: Icon((c.note ?? '').isEmpty ? Icons.edit_note_rounded : Icons.sticky_note_2_outlined,
                  size: 22, color: AiraColors.rose),
            ),
            if (c.completed >= 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AiraColors.blush, borderRadius: BorderRadius.circular(999)),
                child: Text('Repeat', style: AiraText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.rose)),
              ),
          ],
        ),
      ),
    );
  }
}
