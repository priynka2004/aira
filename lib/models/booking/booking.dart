// FILE: models/booking/booking.dart  |  MODEL
// Booking returned by the backend (+ BookingStatusEnum).

/// Model: Booking.
class Booking {
  final int bookingId;
  final int customerId;
  final int artistId;
  final int? subCategoryId;
  final int packageId;
  final int locationTypeId;
  final int? addressId;
  final String bookingDate;
  final String startTime;
  final String? endTime;
  final int statusId;
  final int? paymentStatusId;
  final double totalAmount;
  final String? notes;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? expiresAt;
  final String? createdAt;
  final String? updatedAt;
  final String? onMyWayAt;
  final String? arrivedAt;
  final String? serviceStartedAt;
  final String? serviceCompletedAt;
  // Added by the API (artist sees commission + net; null on older bookings)
  final double? platformFee;
  final double? netAmount;
  final double travelFee;
  final int travelTimeMinutes;
  final int returnBufferMinutes;
  final List<BookingAddOn> addons;

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
    this.platformFee,
    this.netAmount,
    this.travelFee = 0,
    this.travelTimeMinutes = 0,
    this.returnBufferMinutes = 0,
    this.addons = const [],
  });

  /// Starts date time.
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

  /// Returns true if it has start time passed.
  bool get hasStartTimePassed {
    final start = startDateTime;
    if (start == null) return false;
    return !DateTime.now().isBefore(start.add(const Duration(hours: 2)));
  }

  /// Builds this object from API JSON.
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
      platformFee: json['platformFee'] == null ? null : parseAmount(json['platformFee']),
      netAmount: json['netAmount'] == null ? null : parseAmount(json['netAmount']),
      travelFee: parseAmount(json['travelFee']),
      travelTimeMinutes: parseInt(json['travelMinutesBefore'] ?? json['travelTimeMinutes']),
      returnBufferMinutes: parseInt(json['returnBufferMinutes']),
      addons: ((json['addOns'] ?? json['addons'] as List?) as List? ?? const [])
          .whereType<Map>()
          .map((e) => BookingAddOn.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Enum: Booking Status Enum values.
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

/// Add-on chosen on a booking (snapshot: later edits to the add-on do not change it).
class BookingAddOn {
  final int addOnId;
  final String name;
  final double price;
  final int durationMinutes;

  const BookingAddOn({required this.addOnId, required this.name, required this.price, this.durationMinutes = 0});

  factory BookingAddOn.fromJson(Map<String, dynamic> j) => BookingAddOn(
    addOnId: (j['addOnId'] as num?)?.toInt() ?? 0,
    name: (j['name'] ?? '').toString(),
    price: double.tryParse('${j['price']}') ?? 0,
    durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
  );
}