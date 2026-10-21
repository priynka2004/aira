// FILE: utils/api_response.dart
// Generic wrapper for API responses: { data, message }.

/// Api Response.
class ApiResponse<T> {
  final T data;

  ApiResponse({required this.data});

  /// Builds this object from API JSON.
  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJson,
      ) =>
      ApiResponse(data: fromJson(json['data']));
}
