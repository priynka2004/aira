// FILE: services/firestore_location_service.dart
// Writes the artist's live location to Firestore so the customer app can track them.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Location Service — API/data layer.
class FirestoreLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(int bookingId) =>
      _firestore.collection('booking_tracking').doc(bookingId.toString());

  /// Pushes location.
  Future<void> pushLocation(int bookingId, double lat, double lng) async {
    try {
      await _doc(bookingId).set({
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
        'active': true,
      }, SetOptions(merge: true));
    } catch (_) {
    }
  }

  /// Stops sharing.
  Future<void> stopSharing(int bookingId) async {
    try {
      await _doc(bookingId).set({'active': false}, SetOptions(merge: true));
    } catch (_) {
    }
  }
}
