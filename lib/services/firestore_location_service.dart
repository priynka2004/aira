import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes the artist's live position straight to Firestore, keyed by
/// booking — same pattern as [FirestoreNotificationService]. This is the
/// piece that lets live-distance work WITHOUT the custom backend's
/// `/ws/booking-tracking/` socket (see [BookingTrackingSocket]'s own
/// TODO note that it isn't live yet): both apps already share one
/// Firebase project (see `firebase_options.dart` + `Firebase.initializeApp`
/// in main.dart), so Firestore itself is the relay — no server code to
/// write or deploy.
///
/// Expected document shape, written here and read by the customer app's
/// counterpart:
///   booking_tracking/<bookingId>
///     lat: double
///     lng: double
///     updatedAt: Firestore Timestamp
///     active: bool   (false once the artist stops sharing, e.g. arrived)
///
/// NOTE: this collection's Firestore security rules need to allow the
/// artist to write (and the customer to read) `booking_tracking/<id>` —
/// a one-time rules change in the Firebase console, not app or server
/// code. Something like:
///   match /booking_tracking/{bookingId} {
///     allow read: if request.auth != null;
///     allow write: if request.auth != null;
///   }
/// (tighten further to only the assigned artist/customer once your auth
/// claims carry booking ownership).
class FirestoreLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(int bookingId) =>
      _firestore.collection('booking_tracking').doc(bookingId.toString());

  Future<void> pushLocation(int bookingId, double lat, double lng) async {
    try {
      await _doc(bookingId).set({
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
        'active': true,
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort — a failed write shouldn't crash the journey screen;
      // the customer just won't see a fresh distance until the next tick.
    }
  }

  Future<void> stopSharing(int bookingId) async {
    try {
      await _doc(bookingId).set({'active': false}, SetOptions(merge: true));
    } catch (_) {
      // Best-effort.
    }
  }
}
