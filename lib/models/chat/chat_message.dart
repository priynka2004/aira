// FILE: models/chat/chat_message.dart  |  MODEL
// One chat message.

/// Model: Chat Message.
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

  /// Builds this object from API JSON.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? json['id'] ?? 0,
      conversationId: json['conversationId'],
      senderId: json['senderId'] ?? 0,
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  /// Returns true if mine.
  bool isMine(int? currentUserId) => currentUserId != null && senderId == currentUserId;
}
