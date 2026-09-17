class ApiResponse<T> {
  final T data;

  ApiResponse({required this.data});

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJson,
      ) =>
      ApiResponse(data: fromJson(json['data']));
}
