// FILE: utils/paginated_response.dart
// Generic wrapper for paginated list responses.

/// Paginated Response.
class PaginatedResponse<T> {
  final List<T> data;
  final int presentPage;
  final int totalPage;

  PaginatedResponse({
    required this.data,
    required this.presentPage,
    required this.totalPage,
  });

  /// Builds this object from API JSON.
  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawList = (json['data'] ?? json['results'] ?? json['items']) as List? ?? const [];
    return PaginatedResponse(
      data: rawList.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      presentPage: parseInt(json['presentPage'] ?? json['present_page'] ?? json['page_num'] ?? json['pageNum']),
      totalPage: parseInt(json['totalPage'] ?? json['total_page'] ?? json['total_pages'] ?? json['totalPages']),
    );
  }
}
