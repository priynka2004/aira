// FILE: models/notification/app_notification.dart  |  MODEL
// In-app notification (from API or Firestore).

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model: App Notification.
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

  /// Builds this object from API JSON.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
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
      type: pick(['type', 'notificationType', 'notification_type'])?.toString() ?? 'general',
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

  /// Returns a copy with some fields changed.
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
