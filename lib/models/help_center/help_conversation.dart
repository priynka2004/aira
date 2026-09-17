/// Matches the backend's Help Center conversation schema
/// (`GET /help_center/conversation/get/`).
class HelpConversation {
  final int conversationId;
  final int customerId;

  /// `open` (sent, no reply yet), `running` (admin has replied), or
  /// `closed` (terminal — cannot be reopened; sending again starts a new
  /// conversation).
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

  bool get isClosed => status == 'closed';

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
