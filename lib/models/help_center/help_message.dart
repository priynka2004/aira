enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
}

/// Matches the backend's Help Center message shape
/// (`GET /help_center/messages/get_all/`, `POST /help_center/messages/create/`).
class HelpMessage {
  final int messageId;
  final int? conversationId;
  final int senderId;
  final String content;
  final String createdAt;
  final MessageStatus status;

  const HelpMessage({
    required this.messageId,
    this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  factory HelpMessage.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    MessageStatus parseStatus(dynamic value) {
      final status = value?.toString().toLowerCase();
      switch (status) {
        case 'sending':
        case 'pending':
          return MessageStatus.sending;
        case 'sent':
          return MessageStatus.sent;
        case 'delivered':
        case 'delivery':
          return MessageStatus.delivered;
        case 'seen':
        case 'read':
          return MessageStatus.seen;
        default:
          return MessageStatus.sent;
      }
    }

    return HelpMessage(
      messageId: parseInt(json['messageId'] ?? json['message_id'] ?? json['id']),
      conversationId: json['conversationId'] ?? json['conversation_id'],
      senderId: parseInt(json['senderId'] ?? json['sender_id']),
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
      status: parseStatus(json['status'] ?? json['messageStatus'] ?? json['message_status']),
    );
  }

  bool isMine(int? currentUserId) => currentUserId != null && senderId == currentUserId;
}
