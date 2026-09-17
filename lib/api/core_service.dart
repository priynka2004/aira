import 'dart:convert';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../utils/paginated_response.dart';
import '../utils/api_response.dart';
import '../models/core/status_item.dart';
import '../models/core/location_type.dart';
import '../models/core/service_category.dart';
import '../models/core/service_sub_category.dart';

class CoreService {
  final ApiService _apiService;

  CoreService(this._apiService);

  Future<List<StatusItem>> getApprovalStatuses() async {
    final response = await _apiService.get(
      ApiEndpoints.coreApprovalStatusGetAll,
    );
    final jsonData = jsonDecode(response.body);
    return _parseStatusList(jsonData);
  }

  Future<List<StatusItem>> getBookingStatuses() async {
    final response = await _apiService.get(
      ApiEndpoints.coreBookingStatusGetAll,
    );
    final jsonData = jsonDecode(response.body);
    return _parseStatusList(jsonData);
  }

  Future<List<StatusItem>> getPaymentStatuses() async {
    final response = await _apiService.get(
      ApiEndpoints.corePaymentStatusGetAll,
    );
    final jsonData = jsonDecode(response.body);
    return _parseStatusList(jsonData);
  }

  /// Shared, defensive parsing for the three status-list endpoints above.
  /// Accepts `data`/`results`/`items`, or a bare top-level list, and never
  /// throws on an unexpected shape — an empty list is far safer than
  /// taking down the whole dashboard load (see StatusItem.fromJson doc).
  List<StatusItem> _parseStatusList(dynamic jsonData) {
    List rawList;
    if (jsonData is List) {
      rawList = jsonData;
    } else if (jsonData is Map) {
      rawList = (jsonData['data'] ?? jsonData['results'] ?? jsonData['items']) as List? ?? const [];
    } else {
      rawList = const [];
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => StatusItem.fromJson(e))
        .toList();
  }

  Future<LocationType> getLocationType(int locationTypeId) async {
    final response = await _apiService.get(
      ApiEndpoints.coreLocationTypeGet,
      queryParameters: {'location_type_id': locationTypeId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, LocationType.fromJson).data;
  }

  Future<PaginatedResponse<LocationType>> getAllLocationTypes({
    int limit = 10,
    int? pageNum,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.coreLocationTypeGetAll,
      queryParameters: {
        if (limit != 10) 'limit': limit.toString(),
        if (pageNum != null) 'page_num': pageNum.toString(),
      },
    );
    final jsonData = jsonDecode(response.body);
    return PaginatedResponse.fromJson(
      jsonData['data'],
      LocationType.fromJson,
    );
  }

  Future<ServiceCategory> getServiceCategory(int categoryId) async {
    final response = await _apiService.get(
      ApiEndpoints.coreServiceCategoryGet,
      queryParameters: {'category_id': categoryId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, ServiceCategory.fromJson).data;
  }

  Future<PaginatedResponse<ServiceCategory>> getAllServiceCategories({
    int limit = 10,
    int? pageNum,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.coreServiceCategoryGetAll,
      queryParameters: {
        if (limit != 10) 'limit': limit.toString(),
        if (pageNum != null) 'page_num': pageNum.toString(),
      },
    );
    final jsonData = jsonDecode(response.body);
    return PaginatedResponse.fromJson(
      jsonData['data'],
      ServiceCategory.fromJson,
    );
  }

  Future<ServiceSubCategory> getServiceSubCategory(int subCategoryId) async {
    final response = await _apiService.get(
      ApiEndpoints.coreServiceSubCategoryGet,
      queryParameters: {'sub_category_id': subCategoryId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, ServiceSubCategory.fromJson).data;
  }

  Future<PaginatedResponse<ServiceSubCategory>> getAllServiceSubCategories({
    int limit = 10,
    int? pageNum,
    int? categoryId,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.coreServiceSubCategoryGetAll,
      queryParameters: {
        if (limit != 10) 'limit': limit.toString(),
        if (pageNum != null) 'page_num': pageNum.toString(),
        if (categoryId != null) 'filter_key': 'categoryId',
        if (categoryId != null) 'filter_value': categoryId.toString(),
      },
    );
    final jsonData = jsonDecode(response.body);
    return PaginatedResponse.fromJson(
      jsonData['data'],
      ServiceSubCategory.fromJson,
    );
  }
}
