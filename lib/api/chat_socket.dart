// FILE: api/chat_socket.dart
// WebSocket client for real-time booking chat + the event types it emits.

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat/chat_message.dart';
import '../utils/api_logger.dart';
import 'api_endpoints.dart';

/// Chat Socket Event.
sealed class ChatSocketEvent {
  const ChatSocketEvent();
}

/// Chat Message Created.
class ChatMessageCreated extends ChatSocketEvent {
  final ChatMessage message;
  const ChatMessageCreated(this.message);
}

/// Chat Conversation Closed.
class ChatConversationClosed extends ChatSocketEvent {
  final String reason;
  const ChatConversationClosed(this.reason);
}

/// Chat Message Rejected.
class ChatMessageRejected extends ChatSocketEvent {
  final String reason;
  const ChatMessageRejected(this.reason);
}

/// Chat Socket Error Event.
class ChatSocketErrorEvent extends ChatSocketEvent {
  final String reason;
  const ChatSocketErrorEvent(this.reason);
}

/// Chat Socket.
class ChatSocket {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _controller = StreamController<ChatSocketEvent>.broadcast();

  final _doneController = StreamController<void>.broadcast();

  Stream<ChatSocketEvent> get events => _controller.stream;
  /// Callback when done happens.
  Stream<void> get onDone => _doneController.stream;

  /// Returns true if connected.
  bool get isConnected => _channel != null;

  /// Opens the connection.
  void connect(int bookingId, String token) {
    close();
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}'
      '/ws/chat/$bookingId/',
    ).replace(queryParameters: {'token': token});

    try {
      ApiLog.ws('chat', 'connecting', 'booking=$bookingId');
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      var finished = false;
      void finish() {
        if (finished) return;
        finished = true;
        if (identical(_channel, channel)) _channel = null;
        _doneController.add(null);
      }

      _sub = channel.stream.listen(
        _onData,
        onError: (e) {
          ApiLog.ws('chat', 'error', e);
          _controller.add(ChatSocketErrorEvent(e.toString()));
          finish();
        },
        onDone: () {
          ApiLog.ws('chat', 'closed', 'code=${channel.closeCode} reason=${channel.closeReason}');
          finish();
        },
      );
    } catch (e) {
      ApiLog.ws('chat', 'connect failed', e);
      _channel = null;
      _controller.add(ChatSocketErrorEvent(e.toString()));
      _doneController.add(null);
    }
  }

  /// Callback when data happens.
  void _onData(dynamic raw) {
    ApiLog.ws('chat', '← recv', raw);
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      ApiLog.ws('chat', 'malformed payload', raw);
      return;
    }

    switch (json['type']) {
      case 'message.created':
        final msg = json['message'];
        if (msg is Map<String, dynamic>) {
          _controller.add(ChatMessageCreated(ChatMessage.fromJson(msg)));
        }
        break;
      case 'conversation.closed':
        _controller.add(ChatConversationClosed(json['reason']?.toString() ?? 'appointment_completed'));
        break;
      case 'message.rejected':
        _controller.add(ChatMessageRejected(json['reason']?.toString() ?? 'rejected'));
        break;
      case 'error':
        _controller.add(ChatSocketErrorEvent(json['reason']?.toString() ?? 'unknown error'));
        break;
      default:
        ApiLog.ws('chat', 'unhandled event', json['type']);
    }
  }

  /// Sends the message.
  void send(String content) {
    final payload = jsonEncode({'type': 'message.send', 'content': content});
    if (_channel == null) {
      ApiLog.ws('chat', 'send skipped (not connected)', payload);
      return;
    }
    ApiLog.ws('chat', '→ send', payload);
    _channel!.sink.add(payload);
  }

  /// Closes the connection.
  void close() {
    if (_channel != null) ApiLog.ws('chat', 'closing');
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Frees controllers / listeners when the screen closes.
  void dispose() {
    close();
    _controller.close();
    _doneController.close();
  }
}
