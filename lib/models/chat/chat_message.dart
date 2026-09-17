/// Matches the backend's chat message shape.
///
/// REST (`GET /chat/messages/get_all/`, `POST /chat/messages/create/`) sends
/// `messageId`; the WebSocket's `message.created` event nests the same
/// object under `message` with an `id` field instead — [fromJson] accepts
/// both so callers don't need to care which transport a message came from.
class ChatMessage {
  final int messageId;
  final int? conversationId;
  final int senderId;
  final String content;
  final String createdAt;

  const ChatMessage({
    required this.messageId,
    this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? json['id'] ?? 0,
      conversationId: json['conversationId'],
      senderId: json['senderId'] ?? 0,
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  bool isMine(int? currentUserId) => currentUserId != null && senderId == currentUserId;
}
