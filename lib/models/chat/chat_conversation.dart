/// Matches the backend's `Conversation` schema (GET /chat/conversation/get/).
class ChatConversation {
  final int conversationId;
  final int bookingId;
  final String createdAt;

  /// `false` once the appointment is marked completed — the UI should
  /// disable the message input when this is false.
  final bool isOpen;

  const ChatConversation({
    required this.conversationId,
    required this.bookingId,
    required this.createdAt,
    required this.isOpen,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      conversationId: json['conversationId'] ?? 0,
      bookingId: json['bookingId'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      isOpen: json['isOpen'] ?? true,
    );
  }
}
