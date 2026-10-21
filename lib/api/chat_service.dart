// FILE: api/chat_service.dart
// Booking chat APIs: get conversation, load messages (REST), send message (REST), open chat socket.

import 'dart:convert';
import '../models/chat/chat_conversation.dart';
import '../models/chat/chat_message.dart';
import '../utils/app_session.dart';
import '../utils/paginated_response.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import 'chat_socket.dart';

/// Chat Service — API/data layer.
class ChatService {
  final ApiService _apiService;
  ChatService(this._apiService);

  Map<String, dynamic> _unwrap(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
  }

  /// Gets conversation.
  /// API: GET /chat/conversation/get/
  Future<ChatConversation> getConversation(int bookingId) async {
    final response = await _apiService.get(
      ApiEndpoints.chatConversationGet,
      queryParameters: {'booking_id': bookingId.toString()},
    );
    return ChatConversation.fromJson(_unwrap(response.body));
  }

  /// Gets messages.
  /// API: GET /chat/messages/get_all/
  Future<PaginatedResponse<ChatMessage>> getMessages(
    int bookingId, {
    int pageNum = 1,
    int limit = 20,
    String sortOrder = 'asc',
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.chatMessagesGetAll,
      queryParameters: {
        'booking_id': bookingId.toString(),
        'page_num': pageNum.toString(),
        'limit': limit.toString(),
        'sort_order': sortOrder,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return PaginatedResponse.fromJson(data, (e) => ChatMessage.fromJson(e));
  }

  /// Sends message.
  /// API: POST /chat/messages/create/
  Future<ChatMessage> sendMessage(int bookingId, String content) async {
    final response = await _apiService.post(
      ApiEndpoints.chatMessagesCreate,
      data: {'booking_id': bookingId, 'content': content},
    );
    return ChatMessage.fromJson(_unwrap(response.body));
  }

  /// Opens socket.
  ChatSocket openSocket(int bookingId) {
    final socket = ChatSocket();
    final token = AppSession.instance.accessToken ?? '';
    socket.connect(bookingId, token);
    return socket;
  }
}
