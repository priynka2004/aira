import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_feedback.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../models/chat/chat_message.dart';
import '../api/chat_socket.dart';
import '../utils/app_session.dart';
import '../utils/service_locator.dart';

/// Live chat for a single booking. Loads history over REST
/// (`GET /chat/messages/get_all/`), then opens the WebSocket
/// (`wss://.../ws/chat/{bookingId}/`) for real-time messages, falling back
/// to REST sends (`POST /chat/messages/create/`) if the socket drops.
class ChatScreen extends StatefulWidget {
  final int bookingId;
  final String title;

  const ChatScreen({super.key, required this.bookingId, this.title = 'Chat'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _isOpen = true;
  bool _sending = false;
  String? _banner;

  final List<ChatMessage> _messages = [];
  ChatSocket? _socket;
  StreamSubscription<ChatSocketEvent>? _eventsSub;
  StreamSubscription<void>? _doneSub;
  Timer? _reconnectTimer;

  int? get _myUserId => AppSession.instance.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _eventsSub?.cancel();
    _doneSub?.cancel();
    _socket?.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversation = await ServiceLocator.chatService.getConversation(widget.bookingId);
      final history = await ServiceLocator.chatService.getMessages(
        widget.bookingId,
        pageNum: 1,
        limit: 50,
        sortOrder: 'asc',
      );
      if (!mounted) return;
      setState(() {
        _isOpen = conversation.isOpen;
        _messages
          ..clear()
          ..addAll(history.data);
        _loading = false;
      });
      _scrollToBottom();
      if (_isOpen) _connectSocket();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _connectSocket() {
    _eventsSub?.cancel();
    _doneSub?.cancel();
    _socket?.dispose();

    final socket = ServiceLocator.chatService.openSocket(widget.bookingId);
    _socket = socket;
    _eventsSub = socket.events.listen(_onSocketEvent);
    _doneSub = socket.onDone.listen((_) => _scheduleReconnect());
  }

  void _scheduleReconnect() {
    if (!mounted || !_isOpen) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isOpen) _connectSocket();
    });
  }

  void _onSocketEvent(ChatSocketEvent event) {
    if (!mounted) return;
    switch (event) {
      case ChatMessageCreated(:final message):
        setState(() {
          if (!_messages.any((m) => m.messageId == message.messageId)) {
            _messages.add(message);
          }
        });
        _scrollToBottom();
      case ChatConversationClosed():
        setState(() {
          _isOpen = false;
          _banner = 'This conversation is closed — the appointment is complete.';
        });
        _reconnectTimer?.cancel();
      case ChatMessageRejected(:final reason):
        setState(() => _banner = reason == 'conversation_closed'
            ? 'That message couldn\'t be sent — the conversation is closed.'
            : 'That message couldn\'t be sent. Please try again.');
      case ChatSocketErrorEvent():
        // Silent — the reconnect loop (via onDone) handles transient drops.
        break;
    }
  }

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

  Future<void> _send() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || !_isOpen || _sending) return;

    _inputController.clear();
    setState(() => _sending = true);

    try {
      if (_socket?.isConnected ?? false) {
        // Server echoes the send back as a message.created event, so we
        // don't append optimistically here — it'll arrive momentarily.
        _socket!.send(content);
      } else {
        final sent = await ServiceLocator.chatService.sendMessage(widget.bookingId, content);
        if (!mounted) return;
        setState(() {
          if (!_messages.any((m) => m.messageId == sent.messageId)) {
            _messages.add(sent);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _banner = AppFeedback.friendlyMessage(e));
      _inputController.text = content;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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

  Widget _bubble(ChatMessage message) {
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
              style: AiraText.sans(
                fontSize: 13.5,
                color: mine ? Colors.white : AiraColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: AiraText.sans(
                fontSize: 10.5,
                color: mine ? Colors.white70 : AiraColors.charcoalSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            AiraScreenHeader(title: widget.title, onBack: () => Navigator.of(context).pop()),
            if (_banner != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AiraColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                ),
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
                              child: Text(
                                'No messages yet — say hello!',
                                style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft),
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
                child: !_isOpen
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AiraColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AiraColors.hair),
                        ),
                        child: Center(
                          child: Text(
                            'This conversation is closed',
                            style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft),
                          ),
                        ),
                      )
                    : Row(
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
                                  hintText: 'Type a message…',
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
                              onTap: _sending ? null : _send,
                              child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: _sending
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded, size: 17, color: Colors.white),
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
