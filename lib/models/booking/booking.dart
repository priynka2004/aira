/// Matches the backend's `Booking` schema
/// (GET /artists/bookings/get/, get_all/, PUT update_status/).
class Booking {
  final int bookingId;
  final int customerId;
  final int artistId;
  final int? subCategoryId;
  final int packageId;
  final int locationTypeId;
  final int? addressId;
  final String bookingDate; // yyyy-MM-dd
  final String startTime;
  final String? endTime;
  final int statusId;
  // Nullable/best-effort: the backend does not yet return this on
  // Booking (only `/core/payment-status/get_all/` exists as a lookup
  // table today — see the Booking Screen backend requirements doc).
  // Parsed defensively so the app picks it up automatically the day
  // the backend adds it, without another app release.
  final int? paymentStatusId;
  final double totalAmount;
  final String? notes;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? expiresAt;
  final String? createdAt;
  final String? updatedAt;

  // ── Booking-lifecycle sub-stage timestamps ──────────────────────────
  // While statusId still resolves to "confirmed", these are what tell
  // Upcoming / On My Way / Arrived apart (see the Booking Lifecycle Field
  // Guide's "Deriving the sub-stage client-side" callout): check
  // arrivedAt first, then onMyWayAt. Both null → Upcoming. onMyWayAt set
  // → On My Way. arrivedAt set → Arrived.
  final String? onMyWayAt;
  final String? arrivedAt;
  final String? serviceStartedAt;
  final String? serviceCompletedAt;

  Booking({
    required this.bookingId,
    required this.customerId,
    required this.artistId,
    this.subCategoryId,
    required this.packageId,
    required this.locationTypeId,
    this.addressId,
    required this.bookingDate,
    required this.startTime,
    this.endTime,
    required this.statusId,
    this.paymentStatusId,
    required this.totalAmount,
    this.notes,
    this.cancelledBy,
    this.cancellationReason,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.onMyWayAt,
    this.arrivedAt,
    this.serviceStartedAt,
    this.serviceCompletedAt,
  });

  /// Parses [bookingDate] + [startTime] into a local `DateTime`, mirroring
  /// [BookingSlot.startDateTime]. Null if either piece is missing/unparseable.
  DateTime? get startDateTime {
    if (bookingDate.isEmpty || startTime.isEmpty) return null;
    try {
      final dateParts = bookingDate.split('-').map(int.parse).toList();
      final timeParts = startTime.split(':').map(int.parse).toList();
      return DateTime(
        dateParts[0], dateParts[1], dateParts[2],
        timeParts[0], timeParts.length > 1 ? timeParts[1] : 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// True once this booking's scheduled start time — plus the same 2-hour
  /// grace window the Customer app uses (see
  /// `BookingStatusUtil.derive` in the Customer app's `booking_status.dart`)
  /// — has actually arrived (or passed). Used to decide the on-my-way
  /// deadline: [JourneyStage] treats "still upcoming, grace window over,
  /// never marked on the way" as [JourneyStage.missed]. Kept in sync with
  /// the Customer app's 2h grace so both apps agree on when a booking
  /// flips to "Missed" for the same booking at the same wall-clock time.
  bool get hasStartTimePassed {
    final start = startDateTime;
    if (start == null) return false;
    return !DateTime.now().isBefore(start.add(const Duration(hours: 2)));
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    // Second line of defense: whatever gets handed in here becomes a
    // plain string (or null), regardless of caller. REST always sends
    // strings already; this only matters for callers like
    // FirestoreBookingService that may hand through a raw Firestore
    // Timestamp — that call site already normalizes these, but a field
    // should never be able to crash parsing just because some other
    // future caller forgot to.
    String? asString(dynamic v) => v?.toString();

    return Booking(
      bookingId: parseInt(json['bookingId'] ?? json['booking_id']),
      customerId: parseInt(json['customerId'] ?? json['customer_id']),
      artistId: parseInt(json['artistId'] ?? json['artist_id']),
      subCategoryId: json['subCategoryId'] ?? json['sub_category_id'],
      packageId: parseInt(json['packageId'] ?? json['package_id']),
      locationTypeId: parseInt(json['locationTypeId'] ?? json['location_type_id']),
      addressId: json['addressId'] ?? json['address_id'],
      bookingDate: asString(json['bookingDate'] ?? json['booking_date']) ?? '',
      startTime: asString(json['startTime'] ?? json['start_time']) ?? '',
      endTime: asString(json['endTime'] ?? json['end_time']),
      statusId: parseInt(json['statusId'] ?? json['status_id']),
      paymentStatusId: (json['paymentStatusId'] ?? json['payment_status_id']) == null
          ? null
          : parseInt(json['paymentStatusId'] ?? json['payment_status_id']),
      totalAmount: parseAmount(json['totalAmount'] ?? json['total_amount']),
      notes: asString(json['notes']),
      cancelledBy: asString(json['cancelledBy'] ?? json['cancelled_by']),
      cancellationReason:
          asString(json['cancellationReason'] ?? json['cancellation_reason']),
      expiresAt: asString(json['expiresAt'] ?? json['expires_at']),
      createdAt: asString(json['createdAt'] ?? json['created_at']),
      updatedAt: asString(json['updatedAt'] ?? json['updated_at']),
      onMyWayAt: asString(json['onMyWayAt'] ?? json['on_my_way_at']),
      arrivedAt: asString(json['arrivedAt'] ?? json['arrived_at']),
      serviceStartedAt: asString(json['serviceStartedAt'] ?? json['service_started_at']),
      serviceCompletedAt: asString(json['serviceCompletedAt'] ?? json['service_completed_at']),
    );
  }
}

/// The backend's booking-status enum used by /artists/bookings/update_status/.
enum BookingStatusEnum {
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String toJson() {
    switch (this) {
      case BookingStatusEnum.confirmed:
        return 'confirmed';
      case BookingStatusEnum.inProgress:
        return 'in_progress';
      case BookingStatusEnum.completed:
        return 'completed';
      case BookingStatusEnum.cancelled:
        return 'cancelled';
      case BookingStatusEnum.noShow:
        return 'no_show';
    }
  }
}
