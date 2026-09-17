import 'dart:convert';
import '../models/chat/chat_conversation.dart';
import '../models/chat/chat_message.dart';
import '../utils/app_session.dart';
import '../utils/paginated_response.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import 'chat_socket.dart';

class ChatService {
  final ApiService _apiService;
  ChatService(this._apiService);

  Map<String, dynamic> _unwrap(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
  }

  /// GET /chat/conversation/get/?booking_id= — returns the conversation,
  /// creating it on first access. Only the booking's customer or artist
  /// can call this; throws (via ApiService) with a 400 if the booking
  /// isn't confirmed/in_progress yet, or the caller isn't a participant.
  Future<ChatConversation> getConversation(int bookingId) async {
    final response = await _apiService.get(
      ApiEndpoints.chatConversationGet,
      queryParameters: {'booking_id': bookingId.toString()},
    );
    return ChatConversation.fromJson(_unwrap(response.body));
  }

  /// GET /chat/messages/get_all/?booking_id=&page_num=&limit=&sort_order=
  /// Stays readable after the appointment is completed.
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

  /// POST /chat/messages/create/ — REST fallback; prefer the WebSocket
  /// (see [openSocket]) for live chat. Throws on empty content, a
  /// completed appointment, or a non-participant caller.
  Future<ChatMessage> sendMessage(int bookingId, String content) async {
    final response = await _apiService.post(
      ApiEndpoints.chatMessagesCreate,
      data: {'booking_id': bookingId, 'content': content},
    );
    return ChatMessage.fromJson(_unwrap(response.body));
  }

  /// Opens (or reopens) the live chat socket for [bookingId] using the
  /// current session's access token. Callers own the returned [ChatSocket]
  /// and should call `.dispose()` when the chat screen closes.
  ChatSocket openSocket(int bookingId) {
    final socket = ChatSocket();
    final token = AppSession.instance.accessToken ?? '';
    socket.connect(bookingId, token);
    return socket;
  }
}
