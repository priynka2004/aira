// FILE: services/firestore_notification_service.dart
// Firestore listeners: live notifications and live booking updates (streams) + mark-as-read.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification/app_notification.dart';
import '../models/booking/booking.dart';

/// Firestore Notification Service — API/data layer.
class FirestoreNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(int userId) =>
      _firestore.collection('user').doc(userId.toString()).collection('notifications');

  /// Notifications stream.
  Stream<List<AppNotification>> notificationsStream(int userId) {
    return _collection(userId).snapshots().map((snapshot) {
      if (kDebugMode) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            debugPrint('[FirestoreNotifications] new doc ${change.doc.id}: ${change.doc.data()}');
          }
        }
      }
      final items = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  /// Marks as read.
  Future<void> markAsRead(int userId, String docId) async {
    await _collection(userId).doc(docId).update({'isRead': true});
  }

  /// Marks all as read.
  Future<void> markAllAsRead(int userId) async {
    final snapshot = await _collection(userId).where('isRead', isEqualTo: false).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Deletes notification.
  Future<void> deleteNotification(int userId, String docId) async {
    await _collection(userId).doc(docId).delete();
  }

  /// Clears all.
  Future<void> clearAll(int userId) async {
    final snapshot = await _collection(userId).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// Firestore Booking Service — API/data layer.
class FirestoreBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bookings');

  /// Timestamp to iso.
  String? _tsToIso(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate().toIso8601String();
    return v.toString();
  }

  /// Timestamp to date only.
  String? _tsToDateOnly(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }

  /// Timestamp to time only.
  String? _tsToTimeOnly(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }

  /// Creates from doc.
  Booking _fromDoc(String docId, Map<String, dynamic> data) {
    final merged = <String, dynamic>{
      ...data,
      'booking_id': int.tryParse(docId) ?? data['booking_id'] ?? data['bookingId'],
      'bookingDate': _tsToDateOnly(data['bookingDate'] ?? data['booking_date']),
      'startTime': _tsToTimeOnly(data['startTime'] ?? data['start_time']),
      'endTime': _tsToTimeOnly(data['endTime'] ?? data['end_time']),
      'expiresAt': _tsToIso(data['expiresAt'] ?? data['expires_at']),
      'created_at': _tsToIso(data['createdAt'] ?? data['created_at']),
      'updated_at': _tsToIso(data['updatedAt'] ?? data['updated_at']),
    };
    return Booking.fromJson(merged);
  }

  /// Booking stream.
  Stream<Booking?> bookingStream(int bookingId) {
    return _collection.doc(bookingId.toString()).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      try {
        return _fromDoc(doc.id, doc.data()!);
      } catch (_) {
        return null;
      }
    });
  }

  /// Customer bookings stream.
  Stream<List<Booking>> customerBookingsStream(int customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(_sorted);
  }

  /// Artist bookings stream.
  Stream<List<Booking>> artistBookingsStream(int artistId) {
    return _collection
        .where('artistId', isEqualTo: artistId)
        .snapshots()
        .map(_sorted);
  }

  List<Booking> _sorted(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = <Booking>[];
    for (final doc in snapshot.docs) {
      try {
        items.add(_fromDoc(doc.id, doc.data()));
      } catch (_) {
      }
    }
    items.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return items;
  }
}
