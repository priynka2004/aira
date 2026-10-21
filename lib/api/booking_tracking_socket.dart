// FILE: api/booking_tracking_socket.dart
// WebSocket that sends the artist's live location while travelling to a booking.

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/api_logger.dart';
import 'api_endpoints.dart';

/// Booking Tracking Socket.
class BookingTrackingSocket {
  WebSocketChannel? _channel;
  final _doneController = StreamController<void>.broadcast();

  /// Callback when done happens.
  Stream<void> get onDone => _doneController.stream;
  /// Returns true if connected.
  bool get isConnected => _channel != null;

  /// Opens the connection.
  void connect(int bookingId, String token) {
    close();
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}'
        '/ws/booking-tracking/$bookingId/',
      ).replace(queryParameters: {'token': token});
      ApiLog.ws('tracking', 'connecting', 'booking=$bookingId');
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      var finished = false;
      void finish() {
        if (finished) return;
        finished = true;
        if (identical(_channel, channel)) _channel = null;
        _doneController.add(null);
      }

      channel.stream.listen(
        (data) {
          ApiLog.ws('tracking', '← recv', data);
        },
        onDone: () {
          ApiLog.ws('tracking', 'closed', 'code=${channel.closeCode} reason=${channel.closeReason}');
          finish();
        },
        onError: (e) {
          ApiLog.ws('tracking', 'error', e);
          finish();
        },
        cancelOnError: true,
      );
    } catch (e) {
      ApiLog.ws('tracking', 'connect failed', e);
      _channel = null;
    }
  }

  /// Sends location.
  void sendLocation(double lat, double lng) {
    final channel = _channel;
    if (channel == null) return;
    try {
      final payload = jsonEncode({'type': 'location.update', 'lat': lat, 'lng': lng});
      ApiLog.ws('tracking', '→ send', payload);
      channel.sink.add(payload);
    } catch (e) {
      ApiLog.ws('tracking', 'send failed', e);
    }
  }

  /// Closes the connection.
  void close() {
    _channel?.sink.close();
    _channel = null;
  }
}
