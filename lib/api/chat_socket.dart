import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat/chat_message.dart';
import 'api_endpoints.dart';

/// Events the server can push down the chat WebSocket. See the API docs:
/// `message.created`, `conversation.closed`, `message.rejected`, `error`.
sealed class ChatSocketEvent {
  const ChatSocketEvent();
}

class ChatMessageCreated extends ChatSocketEvent {
  final ChatMessage message;
  const ChatMessageCreated(this.message);
}

class ChatConversationClosed extends ChatSocketEvent {
  final String reason;
  const ChatConversationClosed(this.reason);
}

class ChatMessageRejected extends ChatSocketEvent {
  final String reason;
  const ChatMessageRejected(this.reason);
}

class ChatSocketErrorEvent extends ChatSocketEvent {
  final String reason;
  const ChatSocketErrorEvent(this.reason);
}

/// One connection per active chat screen: `wss://.../ws/chat/{bookingId}/?token={jwt}`.
///
/// Auth and booking participation are re-checked by the server on every
/// connect, so on a dropped connection the caller can just call [connect]
/// again with the same bookingId/token.
class ChatSocket {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _controller = StreamController<ChatSocketEvent>.broadcast();

  /// Fires once the underlying socket closes (network drop, server reject,
  /// or [close] being called) so the UI can show a "reconnecting" state or
  /// attempt [connect] again.
  final _doneController = StreamController<void>.broadcast();

  Stream<ChatSocketEvent> get events => _controller.stream;
  Stream<void> get onDone => _doneController.stream;

  bool get isConnected => _channel != null;

  void connect(int bookingId, String token) {
    close();
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}'
      '/ws/chat/$bookingId/',
    ).replace(queryParameters: {'token': token});

    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onData,
        onError: (e) {
          if (kDebugMode) debugPrint('[ChatSocket] error: $e');
          _controller.add(ChatSocketErrorEvent(e.toString()));
          _doneController.add(null);
        },
        onDone: () {
          if (kDebugMode) debugPrint('[ChatSocket] closed');
          _doneController.add(null);
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[ChatSocket] connect failed: $e');
      _controller.add(ChatSocketErrorEvent(e.toString()));
      _doneController.add(null);
    }
  }

  void _onData(dynamic raw) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[ChatSocket] malformed payload: $raw');
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
        if (kDebugMode) debugPrint('[ChatSocket] unhandled event: ${json['type']}');
    }
  }

  /// Sends `{ "type": "message.send", "content": ... }`. REST
  /// (`ChatService.sendMessage`) remains available as a fallback if the
  /// socket isn't connected.
  void send(String content) {
    _channel?.sink.add(jsonEncode({'type': 'message.send', 'content': content}));
  }

  void close() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    close();
    _controller.close();
    _doneController.close();
  }
}
