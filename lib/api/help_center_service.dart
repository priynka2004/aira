// FILE: api/help_center_service.dart
// Help Center (support chat) APIs: conversation, messages list, send message.

import 'dart:convert';
import '../models/help_center/help_conversation.dart';
import '../models/help_center/help_message.dart';
import '../utils/paginated_response.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

/// Help Center Service — API/data layer.
class HelpCenterService {
  final ApiService _apiService;
  HelpCenterService(this._apiService);

  Map<String, dynamic> _unwrap(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
  }

  /// Gets conversation.
  /// API: GET /help_center/artist/conversation/get/
  /// Returns null when the artist has no chat yet (a brand-new artist has none,
  /// so this is NOT an error — the screen shows the empty chat state).
  Future<HelpConversation?> getConversation() async {
    try {
      final response = await _apiService.get(ApiEndpoints.helpCenterConversationGet);
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final data = _unwrap(response.body);
      final hasId = data['conversationId'] ?? data['conversation_id'] ?? data['id'];
      if (hasId == null) return null;
      final conversation = HelpConversation.fromJson(data);
      return conversation.conversationId == 0 ? null : conversation;
    } catch (e) {
      if (_isNoConversation(e)) return null;
      rethrow;
    }
  }

  /// True when the server only says "no chat exists yet" (any wording / 404).
  bool _isNoConversation(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('not found') ||
        s.contains('no conversation') ||
        s.contains('does not exist') ||
        s.contains('no active') ||
        s.contains('error 404');
  }

  /// Gets messages.
  /// API: GET /help_center/messages/get_all/
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

  /// Sends message.
  /// API: POST /help_center/messages/create/
  Future<HelpMessage> sendMessage(String content) async {
    final response = await _apiService.post(
      ApiEndpoints.helpCenterMessagesCreate,
      data: {'content': content},
    );
    return HelpMessage.fromJson(_unwrap(response.body));
  }
}
