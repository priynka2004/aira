import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification/app_notification.dart';
import '../models/booking/booking.dart';

/// Live counterpart to [NotificationService] (the REST API in
/// `lib/api/notification_service.dart`). Reads/updates the Firestore
/// `user/<userId>/notifications` collection directly, the same structure
/// the reference implementation's backend writes to — so a notification
/// shows up in the app the instant it's written, with no REST round-trip
/// or manual refresh needed.
///
/// This is additive, not a replacement: [NotificationsScreen] merges this
/// live stream with the existing REST-fetched list, so notifications work
/// whichever path the backend ends up writing through.
///
/// Expected document shape (backend writes these):
///   user/<userId>/notifications/<docId>
///     title: string
///     body: string
///     createdAt: Firestore Timestamp
///     isRead: bool
///     (optional, for tap-routing) type, booking_id, notification_id

class FirestoreNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(int userId) =>
      _firestore.collection('user').doc(userId.toString()).collection('notifications');

  /// Live stream of this user's notifications, newest first.
  Stream<List<AppNotification>> notificationsStream(int userId) {
    return _collection(userId).snapshots().map((snapshot) {
      // Log every raw doc as it arrives — before AppNotification.fromFirestore
      // picks out just the fields it knows about — so nothing the backend
      // writes here is ever silently hidden (e.g. an OTP in an unexpected key).
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

  Future<void> markAsRead(int userId, String docId) async {
    await _collection(userId).doc(docId).update({'isRead': true});
  }

  Future<void> markAllAsRead(int userId) async {
    final snapshot = await _collection(userId).where('isRead', isEqualTo: false).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(int userId, String docId) async {
    await _collection(userId).doc(docId).delete();
  }

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

/// Live counterpart to [BookingService] (the REST API in
/// `lib/api/booking_service.dart`).
///
/// Unlike notifications, this is a **root-level** collection — same as
/// `fcm_tokens` — not nested under `user/<userId>/...`. That's because a
/// booking belongs to two people (customer + artist) at once, so a single
/// flat `bookings` collection avoids writing the same booking twice.
///
/// Firestore Console path:
///   bookings/<bookingId>            <- root collection, doc ID = booking_id
///     customerId: number
///     artistId: number
///     statusId: number
///     packageId: number
///     subCategoryId: number | null
///     locationTypeId: number
///     addressId: number | null
///     bookingDate: string   ("yyyy-MM-dd")
///     startTime: string
///     endTime: string | null
///     totalAmount: number
///     notes: string | null
///     cancelledBy: string | null
///     cancellationReason: string | null
///     expiresAt: string | null
///     createdAt: Firestore Timestamp
///     updatedAt: Firestore Timestamp
class FirestoreBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bookings');

  String? _tsToIso(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate().toIso8601String();
    return v.toString();
  }

  /// Firestore date-only fields can arrive as a `Timestamp` (e.g. if
  /// whoever wrote the doc used a Python `date`/`datetime` object, which
  /// firebase-admin auto-converts) instead of the plain "yyyy-MM-dd"
  /// string the REST API sends. Accept either.
  String? _tsToDateOnly(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }

  /// Same idea for time-only fields ("HH:mm:ss").
  String? _tsToTimeOnly(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }

  Booking _fromDoc(String docId, Map<String, dynamic> data) {
    final merged = <String, dynamic>{
      ...data,
      'booking_id': int.tryParse(docId) ?? data['booking_id'] ?? data['bookingId'],
      // Every date/time-shaped field is normalized the same defensive
      // way — whichever type Firestore actually stored it as (String or
      // Timestamp), Booking.fromJson always receives a plain string.
      'bookingDate': _tsToDateOnly(data['bookingDate'] ?? data['booking_date']),
      'startTime': _tsToTimeOnly(data['startTime'] ?? data['start_time']),
      'endTime': _tsToTimeOnly(data['endTime'] ?? data['end_time']),
      'expiresAt': _tsToIso(data['expiresAt'] ?? data['expires_at']),
      'created_at': _tsToIso(data['createdAt'] ?? data['created_at']),
      'updated_at': _tsToIso(data['updatedAt'] ?? data['updated_at']),
    };
    return Booking.fromJson(merged);
  }

  /// Live stream of a single booking (detail screen).
  Stream<Booking?> bookingStream(int bookingId) {
    return _collection.doc(bookingId.toString()).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      try {
        return _fromDoc(doc.id, doc.data()!);
      } catch (_) {
        // Malformed doc (e.g. a field shape REST never sends) — better to
        // silently skip this update than crash the whole stream and leave
        // the screen with no live updates at all for the rest of the
        // session.
        return null;
      }
    });
  }

  /// Live stream of all bookings where this user is the customer.
  Stream<List<Booking>> customerBookingsStream(int customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(_sorted);
  }

  /// Live stream of all bookings where this user is the artist.
  Stream<List<Booking>> artistBookingsStream(int artistId) {
    return _collection
        .where('artistId', isEqualTo: artistId)
        .snapshots()
        .map(_sorted);
  }

  /// Parses every doc in [snapshot], skipping (not crashing on) any single
  /// doc that fails to parse. Firestore's `bookings` mirror can lag behind
  /// or hold older/partial docs (see the "known gap" notes on this
  /// collection) — one bad doc throwing inside `.map()` used to take down
  /// the *entire* stream (silently, in release builds, with nothing on
  /// screen to show why), wiping out every other correctly-loaded booking
  /// along with it. Skipping just that doc keeps the rest of the list intact.
  List<Booking> _sorted(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = <Booking>[];
    for (final doc in snapshot.docs) {
      try {
        items.add(_fromDoc(doc.id, doc.data()));
      } catch (_) {
        // Skip this one doc; don't let it take the whole snapshot down.
      }
    }
    items.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return items;
  }
}
