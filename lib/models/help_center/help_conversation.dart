// FILE: models/help_center/help_conversation.dart  |  MODEL
// Help Center conversation.

/// Model: Help Conversation.
class HelpConversation {
  final int conversationId;
  final int customerId;

  final String status;
  final String createdAt;
  final String? closedAt;

  const HelpConversation({
    required this.conversationId,
    required this.customerId,
    required this.status,
    required this.createdAt,
    this.closedAt,
  });

  /// Returns true if closed.
  bool get isClosed => status == 'closed';

  /// Builds this object from API JSON.
  factory HelpConversation.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return HelpConversation(
      conversationId: parseInt(json['conversationId'] ?? json['conversation_id']),
      customerId: parseInt(json['customerId'] ?? json['customer_id']),
      status: json['status']?.toString() ?? 'open',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
      closedAt: json['closedAt']?.toString() ?? json['closed_at']?.toString(),
    );
  }
}
