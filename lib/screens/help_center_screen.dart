// FILE: screens/help_center_screen.dart
// SCREEN: Help Center — support chat with the Sunndari team (polling, no socket).
//
// APIs used:
//   GET /help_center/conversation/get/
//   GET /help_center/messages/get_all/
//   POST /help_center/messages/create/

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/help_center/help_message.dart';
import '../utils/app_session.dart';
import '../utils/service_locator.dart';
import '../api/help_center_notifier.dart';
import 'support_tickets_screen.dart';

/// SCREEN: Help Center — support chat with the Sunndari team (polling, no socket).
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

/// State of [HelpCenterScreen] — holds the screen data and logic.
class _HelpCenterScreenState extends State<HelpCenterScreen> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 8);

  late final _helpCenterService = ServiceLocator.helpCenterService;

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();

  bool _loading = true;
  String? _error;
  String? _banner;

  int? _conversationId;
  String? _status;
  final List<HelpMessage> _messages = [];
  Timer? _pollTimer;

  int _tempIdCounter = -1;
  Timer? _retryTimer;

  /// My user id.
  int? get _myUserId => AppSession.instance.userId;

  /// Runs once when the screen opens; starts: _load().
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HelpCenterNotifier.instance.setSuppressed(true);
    _load();
  }

  /// Frees controllers / listeners when the screen closes.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HelpCenterNotifier.instance.setSuppressed(false);
    _pollTimer?.cancel();
    _retryTimer?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  /// Reacts to app going to background / foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      HelpCenterNotifier.instance.setSuppressed(true);
      if (_conversationId != null) {
        _poll();
        _ensurePolling();
      }
      _retryPending();
    } else {
      HelpCenterNotifier.instance.setSuppressed(false);
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Loads this screen's data.
  /// Uses 2 APIs (see inline notes).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // API call: helpCenterService.getConversation → GET /help_center/conversation/get/
      final conversation = await _helpCenterService.getConversation();
      if (conversation != null) {
        // API call: helpCenterService.getMessages → GET /help_center/messages/get_all/
        final history = await _helpCenterService.getMessages(
          conversation.conversationId,
          pageNum: 1,
          limit: 50,
          sortOrder: 'asc',
        );
        if (!mounted) return;
        setState(() {
          _conversationId = conversation.conversationId;
          _status = conversation.status;
          _messages
            ..clear()
            ..addAll(history.data);
          _loading = false;
        });
        _scrollToBottom();
        _ensurePolling();
      } else {
        if (!mounted) return;
        setState(() {
          _conversationId = null;
          _status = null;
          _messages.clear();
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('[HelpCenterScreen] failed to load conversation: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't Load Help Center. Please Try Again.";
        _loading = false;
      });
    }
  }

  /// Ensures polling.
  void _ensurePolling() {
    _pollTimer ??= Timer.periodic(_pollInterval, (_) => _poll());
  }

  /// Checks for new data.
  /// Uses 2 APIs (see inline notes).
  Future<void> _poll() async {
    final conversationId = _conversationId;
    if (conversationId == null || !mounted) return;

    try {
      // API call: helpCenterService.getConversation → GET /help_center/conversation/get/
      final conversation = await _helpCenterService.getConversation();
      // API call: helpCenterService.getMessages → GET /help_center/messages/get_all/
      final history = await _helpCenterService.getMessages(
        conversationId,
        pageNum: 1,
        limit: 50,
        sortOrder: 'asc',
      );
      if (!mounted) return;

      setState(() {
        _status = conversation != null && conversation.conversationId == conversationId
            ? conversation.status
            : 'closed';

        for (final m in history.data) {
          final index = _messages.indexWhere((existing) => existing.messageId == m.messageId);
          if (index == -1) {
            _messages.add(m);
          } else {
            _messages[index] = m;
          }
        }
      });
      _scrollToBottom();
    } catch (_) {
    }
  }

  /// Scrolls to bottom.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// Returns true if network error.
  bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('clientexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection failed') ||
        s.contains('connection closed') ||
        s.contains('timeoutexception') ||
        s.contains('timed out');
  }

  /// Sends the message.
  Future<void> _send() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;

    _inputController.clear();

    final optimistic = HelpMessage(
      messageId: _tempIdCounter--,
      conversationId: _conversationId,
      senderId: _myUserId ?? 0,
      content: content,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      status: MessageStatus.sending,
    );

    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    await _attemptSend(optimistic);
  }

  /// Attempts send.
  /// API: helpCenterService.sendMessage → POST /help_center/messages/create/
  Future<void> _attemptSend(HelpMessage optimistic) async {
    try {
      // API call: helpCenterService.sendMessage → POST /help_center/messages/create/
      final sent = await _helpCenterService.sendMessage(optimistic.content);
      if (!mounted) return;
      setState(() {
        if (sent.conversationId != null && sent.conversationId != _conversationId) {
          _conversationId = sent.conversationId;
          _status = 'open';
        }
        final idx = _messages.indexWhere((m) => m.messageId == optimistic.messageId);
        if (idx != -1) {
          _messages[idx] = sent;
        } else if (!_messages.any((m) => m.messageId == sent.messageId)) {
          _messages.add(sent);
        }
      });
      _scrollToBottom();
      _ensurePolling();
    } catch (e) {
      if (kDebugMode) print('[HelpCenterScreen] send failed: $e');
      if (_isNetworkError(e)) {
        _ensureRetrying();
        return;
      }
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.messageId == optimistic.messageId);
        _banner = "That Message Couldn't Be Sent. Please Try Again.";
      });
    }
  }

  /// Ensures retrying.
  void _ensureRetrying() {
    _retryTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => _retryPending());
  }

  /// Retries pending.
  Future<void> _retryPending() async {
    final pending = _messages.where((m) => m.status == MessageStatus.sending && m.messageId < 0).toList();

    if (pending.isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }

    for (final m in pending) {
      await _attemptSend(m);
    }
  }

  /// Formats time.
  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '';
    }
  }

  /// UI piece: bubble.
  Widget _bubble(HelpMessage message) {
    final mine = message.isMine(_myUserId);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: mine ? AiraColors.rose : AiraColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: AiraColors.hair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: AiraText.sans(fontSize: 13.5, color: mine ? Colors.white : AiraColors.charcoal),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: AiraText.sans(fontSize: 10.5, color: mine ? Colors.white70 : AiraColors.charcoalSoft),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  _messageTicks(message),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Seen by admin.
  bool _seenByAdmin(HelpMessage message) {
    if (message.messageId < 0) return false;
    final myId = _myUserId;
    DateTime myTime;
    try {
      myTime = DateTime.parse(message.createdAt);
    } catch (_) {
      return false;
    }
    for (final m in _messages) {
      if (m.senderId == myId || m.messageId < 0) continue;
      try {
        if (!DateTime.parse(m.createdAt).isBefore(myTime)) return true;
      } catch (e) {
        if (kDebugMode) debugPrint('[HelpCenter] failed to parse createdAt "${m.createdAt}": $e');
      }
    }
    return false;
  }

  /// UI piece: message ticks.
  Widget _messageTicks(HelpMessage message) {
    if (message.messageId < 0) {
      return const Icon(Icons.check_rounded, size: 14, color: Colors.white70);
    }
    if (_seenByAdmin(message)) {
      return const Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF34D399));
    }
    return const Icon(Icons.done_all_rounded, size: 15, color: Colors.white70);
  }

  /// Status label.
  String get _statusLabel {
    switch (_status) {
      case 'open':
        return 'Sent · Waiting For Reply';
      case 'running':
        return 'Support Replied';
      case 'closed':
        return 'Resolved — Send A Message To Start A New One';
      default:
        return '';
    }
  }

  /// Status color.
  Color get _statusColor {
    switch (_status) {
      case 'open':
        return AiraColors.warn;
      case 'running':
        return AiraColors.success;
      case 'closed':
        return AiraColors.charcoalSoft;
      default:
        return AiraColors.charcoalSoft;
    }
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            AiraScreenHeader(title: 'Help Centre', onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportTicketsScreen())),
                  icon: const Icon(Icons.confirmation_number_outlined, size: 18, color: AiraColors.rose),
                  label: Text('My Support Tickets',
                      style: AiraText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.rose)),
                ),
              ),
            ),
            if (_status != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AiraColors.card, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusLabel,
                        style: AiraText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            if (_banner != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AiraColors.errorBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_banner!, style: AiraText.sans(fontSize: 12.5, color: AiraColors.errorText)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _banner = null),
                      child: const Icon(Icons.close, size: 16, color: AiraColors.errorText),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose))
                  : _error != null
                      ? AiraErrorState(message: _error!, onRetry: _load)
                      : _messages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Need A Hand? Send Us A Message And Our Team Will Get Back To You Here.',
                                  textAlign: TextAlign.center,
                                  style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                              itemCount: _messages.length,
                              itemBuilder: (context, i) => _bubble(_messages[i]),
                            ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AiraColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AiraColors.hair),
                        ),
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: AiraText.sans(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Type A Message…',
                            hintStyle: AiraText.sans(fontSize: 13.5, color: AiraColors.charcoalSoft),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AiraColors.rose,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _send,
                        child: const Padding(
                          padding: EdgeInsets.all(13),
                          child: Icon(Icons.send_rounded, size: 17, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
