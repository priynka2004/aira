import 'dart:convert';
import '../models/booking/booking.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _apiService;
  BookingService(this._apiService);

  Map<String, dynamic> _unwrap(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
  }

  List<Booking> _parseBookingList(dynamic json) {
    final raw = json is Map ? (json['data'] ?? json) : json;
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['data'] as List? ?? []) : []);
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /artists/bookings/get/?booking_id=
  Future<Booking> getBooking(int bookingId) async {
    final response = await _apiService.get(
      ApiEndpoints.artistBookingsGet,
      queryParameters: {'booking_id': bookingId.toString()},
    );
    return Booking.fromJson(_unwrap(response.body));
  }

  /// GET /artists/bookings/get_all/
  Future<List<Booking>> getAllBookings({
    String? filterKey,
    String? filterValue,
    int pageNum = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.artistBookingsGetAll,
      queryParameters: {
        'page_num': pageNum.toString(),
        'limit': limit.toString(),
      },
    );

    final bookings = _parseBookingList(jsonDecode(response.body));

    return bookings;
  }

  /// PUT /artists/bookings/update_status/
  Future<Booking> updateBookingStatus(
    int bookingId,
    BookingStatusEnum status, {
    String? reason,
  }) async {
    final response = await _apiService.put(
      ApiEndpoints.artistBookingsUpdateStatus,
      data: {
        'booking_id': bookingId,
        'status': status.toJson(),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return Booking.fromJson(_unwrap(response.body));
  }
}
