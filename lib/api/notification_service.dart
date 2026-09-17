import 'dart:convert';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../utils/paginated_response.dart';
import '../utils/api_response.dart';
import '../models/notification/app_notification.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// GET /notifications/get/?notification_id=
  Future<AppNotification> getNotification(int notificationId) async {
    final response = await _apiService.get(
      ApiEndpoints.notificationsGet,
      queryParameters: {'notification_id': notificationId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, AppNotification.fromJson).data;
  }

  /// GET /notifications/get_all/
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

  /// PUT /notifications/mark_read/  { notification_id }
  Future<void> markRead(int notificationId) async {
    await _apiService.put(
      ApiEndpoints.notificationsMarkRead,
      data: {'notification_id': notificationId},
    );
  }

  /// PUT /notifications/mark_all_read/
  Future<void> markAllRead() async {
    await _apiService.put(ApiEndpoints.notificationsMarkAllRead);
  }
}
