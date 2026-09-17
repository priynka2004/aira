import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the `Notification` schema returned by
/// GET /notifications/get/ and GET /notifications/get_all/, and also for
/// items read live from the Firestore `user/<userId>/notifications`
/// collection (see [AppNotification.fromFirestore]) — the app shows both
/// sources merged in one list.
///
/// Named `AppNotification` (not `Notification`) to avoid clashing with
/// Flutter's own `Notification` widget class.
class AppNotification {
  final int notificationId;
  final int userId;
  final int? bookingId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String deliveryStatus;
  final String? fcmMessageId;
  final String? failureReason;
  final DateTime? sentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Set only for items that came from the live Firestore
  // `user/<userId>/notifications` stream instead of the REST API. Used to
  // route read/delete actions to the right backing store — see
  // NotificationsScreen. Null for REST-sourced items.
  final String? firestoreDocId;

  AppNotification({
    required this.notificationId,
    required this.userId,
    this.bookingId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.deliveryStatus,
    this.fcmMessageId,
    this.failureReason,
    this.sentAt,
    required this.createdAt,
    required this.updatedAt,
    this.firestoreDocId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // The backend isn't 100% consistent about camelCase vs snake_case
    // across endpoints/pushes (see Booking/ChatMessage models for the
    // same pattern), so every field is read dynamically from whichever
    // key is actually present instead of only trusting one spelling and
    // silently falling back to a static default (0 / '' / false).
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (json[k] != null) return json[k];
      }
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return AppNotification(
      notificationId:
          parseInt(pick(['notificationId', 'notification_id', 'id'])) ?? 0,
      userId: parseInt(pick(['userId', 'user_id'])) ?? 0,
      bookingId: parseInt(pick(['bookingId', 'booking_id'])),
      type: pick(['type', 'notificationType', 'notification_type'])
              ?.toString() ??
          'general',
      title: pick(['title'])?.toString() ?? '',
      message: pick(['message', 'body'])?.toString() ?? '',
      isRead: parseBool(pick(['isRead', 'is_read'])),
      deliveryStatus:
          pick(['deliveryStatus', 'delivery_status'])?.toString() ?? '',
      fcmMessageId:
          pick(['fcmMessageId', 'fcm_message_id'])?.toString(),
      failureReason:
          pick(['failureReason', 'failure_reason'])?.toString(),
      sentAt: parseDate(pick(['sentAt', 'sent_at'])),
      createdAt:
          parseDate(pick(['createdAt', 'created_at'])) ?? DateTime.now(),
      updatedAt:
          parseDate(pick(['updatedAt', 'updated_at'])) ?? DateTime.now(),
    );
  }

  /// Builds an item from a Firestore `user/<userId>/notifications/<docId>`
  /// document, matching the field names the reference app's backend
  /// writes (`title`, `body`, `createdAt`, `isRead`) — plus whatever
  /// extra fields (`type`, `booking_id`, `notification_id`) the backend
  /// chooses to also include for richer tap-routing. [docId] is the
  /// Firestore document id, kept in [firestoreDocId] so read/delete
  /// actions know to hit Firestore instead of the REST API.
  factory AppNotification.fromFirestore(String docId, Map<String, dynamic> data) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (data[k] != null) return data[k];
      }
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime parseCreatedAt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotification(
      notificationId: parseInt(pick(['notification_id', 'notificationId', 'id'])) ?? 0,
      userId: parseInt(pick(['user_id', 'userId'])) ?? 0,
      bookingId: parseInt(pick(['booking_id', 'bookingId'])),
      type: pick(['type'])?.toString() ?? 'general',
      title: pick(['title'])?.toString() ?? 'No Title',
      message: pick(['body', 'message'])?.toString() ?? '',
      isRead: data['isRead'] == true || data['is_read'] == true,
      deliveryStatus: pick(['deliveryStatus', 'delivery_status'])?.toString() ?? '',
      fcmMessageId: pick(['fcmMessageId', 'fcm_message_id'])?.toString(),
      failureReason: pick(['failureReason', 'failure_reason'])?.toString(),
      sentAt: null,
      createdAt: parseCreatedAt(pick(['createdAt', 'created_at'])),
      updatedAt: parseCreatedAt(pick(['createdAt', 'created_at'])),
      firestoreDocId: docId,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        notificationId: notificationId,
        userId: userId,
        bookingId: bookingId,
        type: type,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        deliveryStatus: deliveryStatus,
        fcmMessageId: fcmMessageId,
        failureReason: failureReason,
        sentAt: sentAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        firestoreDocId: firestoreDocId,
      );
}
