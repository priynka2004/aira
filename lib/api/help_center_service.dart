import 'dart:convert';
import '../models/help_center/help_conversation.dart';
import '../models/help_center/help_message.dart';
import '../utils/paginated_response.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

/// Help Center — support chat with the Sunndari team, authenticated with
/// the same JWT issued by `/auth/`. There is no separate Help Center login
/// and no WebSocket for this feature; [HelpCenterScreen] polls
/// [getMessages] to pick up new replies and status changes.
class HelpCenterService {
  final ApiService _apiService;
  HelpCenterService(this._apiService);

  Map<String, dynamic> _unwrap(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
  }

  /// GET /help_center/conversation/get/ — the caller's most recent
  /// conversation that isn't closed. A 400 here just means nothing is
  /// open yet (the expected first-visit response), so it's surfaced as
  /// `null` instead of throwing.
  Future<HelpConversation?> getConversation() async {
    try {
      final response = await _apiService.get(ApiEndpoints.helpCenterConversationGet);
      return HelpConversation.fromJson(_unwrap(response.body));
    } catch (e) {
      if (e.toString().toLowerCase().contains('conversation not found')) return null;
      rethrow;
    }
  }

  /// GET /help_center/messages/get_all/ — paginated, oldest-first message
  /// history for a conversation the caller owns.
  Future<PaginatedResponse<HelpMessage>> getMessages(
    int conversationId, {
    int pageNum = 1,
    int limit = 20,
    String sortOrder = 'asc',
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.helpCenterMessagesGetAll,
      queryParameters: {
        'conversation_id': conversationId.toString(),
        'page_num': pageNum.toString(),
        'limit': limit.toString(),
        'sort_order': sortOrder,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return PaginatedResponse.fromJson(data, (e) => HelpMessage.fromJson(e));
  }

  /// POST /help_center/messages/create/ — sends a message as the caller.
  /// If the customer has no open conversation, one is created
  /// automatically — this is the only way a new conversation starts.
  Future<HelpMessage> sendMessage(String content) async {
    final response = await _apiService.post(
      ApiEndpoints.helpCenterMessagesCreate,
      data: {'content': content},
    );
    return HelpMessage.fromJson(_unwrap(response.body));
  }
}
