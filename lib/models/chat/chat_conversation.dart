// FILE: models/chat/chat_conversation.dart  |  MODEL
// Chat conversation of a booking.

/// Model: Chat Conversation.
class ChatConversation {
  final int conversationId;
  final int bookingId;
  final String createdAt;
  final bool isOpen;

  const ChatConversation({
    required this.conversationId,
    required this.bookingId,
    required this.createdAt,
    required this.isOpen,
  });

  /// Builds this object from API JSON.
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      conversationId: json['conversationId'] ?? 0,
      bookingId: json['bookingId'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      isOpen: json['isOpen'] ?? true,
    );
  }
}
