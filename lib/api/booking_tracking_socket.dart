import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_endpoints.dart';

/// Artist-side socket that streams live GPS updates while a journey is in
/// progress, so the customer app can show the artist moving on a map.
///
/// TODO(backend): `wss://.../ws/booking-tracking/{bookingId}/?token={jwt}`
/// mirrors the existing chat socket's URL shape
/// (`wss://.../ws/chat/{bookingId}/?token=`) — matches [ChatSocket] in
/// `chat_socket.dart`, which *is* live, so the same infra should be able
/// to host this. If the endpoint doesn't exist yet, [connect] fails
/// silently and [sendLocation] becomes a no-op; the rest of the journey
/// flow (PIN verification, stage transitions) does not depend on this
/// socket succeeding.
class BookingTrackingSocket {
  WebSocketChannel? _channel;
  final _doneController = StreamController<void>.broadcast();

  Stream<void> get onDone => _doneController.stream;
  bool get isConnected => _channel != null;

  void connect(int bookingId, String token) {
    close();
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}'
        '/ws/booking-tracking/$bookingId/',
      ).replace(queryParameters: {'token': token});
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (_) {
          // Artist side doesn't need to read anything back — it's purely
          // a broadcaster. Kept here so a dropped connection still fires
          // [onDone] below.
        },
        onDone: () {
          _channel = null;
          _doneController.add(null);
        },
        onError: (_) {
          _channel = null;
          _doneController.add(null);
        },
        cancelOnError: true,
      );
    } catch (_) {
      // TODO(backend): socket endpoint not live yet — [isConnected] stays
      // false and [sendLocation] is a safe no-op below.
      _channel = null;
    }
  }

  /// Sends one location fixed point. Call this periodically (e.g. every
  /// 5–10s via `Geolocator.getPositionStream`) for as long as the journey
  /// is `journeyStarted` or `arrived`.
  void sendLocation(double lat, double lng) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode({'type': 'location.update', 'lat': lat, 'lng': lng}));
    } catch (_) {
      // Best-effort — a dropped send just means one skipped tick.
    }
  }

  void close() {
    _channel?.sink.close();
    _channel = null;
  }
}
