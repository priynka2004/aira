// FILE: api/notification_service.dart
// In-app notification APIs: get, list, mark read, mark all read.

import 'dart:convert';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../utils/paginated_response.dart';
import '../utils/api_response.dart';
import '../models/notification/app_notification.dart';

/// Notification Service — API/data layer.
class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// Gets notification.
  /// API: GET /notifications/get/
  Future<AppNotification> getNotification(int notificationId) async {
    final response = await _apiService.get(
      ApiEndpoints.notificationsGet,
      queryParameters: {'notification_id': notificationId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, AppNotification.fromJson).data;
  }

  /// Gets all notifications.
  /// API: GET /notifications/get_all/
  Future<PaginatedResponse<AppNotification>> getAllNotifications({
    int limit = 10,
    int? pageNum,
    String? sortBy,
    String? sortOrder,
    String? searchKey,
    String? filterKey,
    String? filterValue,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.notificationsGetAll,
      queryParameters: {
        if (limit != 10) 'limit': limit.toString(),
        if (pageNum != null) 'page_num': pageNum.toString(),
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (searchKey != null) 'search_key': searchKey,
        if (filterKey != null) 'filter_key': filterKey,
        if (filterValue != null) 'filter_value': filterValue,
      },
    );
    final jsonData = jsonDecode(response.body);
    return PaginatedResponse.fromJson(
      jsonData['data'],
      AppNotification.fromJson,
    );
  }

  /// Marks read.
  /// API: PUT /notifications/mark_read/
  Future<void> markRead(int notificationId) async {
    await _apiService.put(
      ApiEndpoints.notificationsMarkRead,
      data: {'notification_id': notificationId},
    );
  }

  /// Marks all read.
  /// API: PUT /notifications/mark_all_read/
  Future<void> markAllRead() async {
    await _apiService.put(ApiEndpoints.notificationsMarkAllRead);
  }
}
