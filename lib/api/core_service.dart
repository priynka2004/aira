// FILE: api/core_service.dart
// Core/master-data APIs: approval / booking / payment statuses, location types, service categories + sub-categories.

import 'dart:convert';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../utils/paginated_response.dart';
import '../utils/api_response.dart';
import '../models/core/status_item.dart';
import '../models/core/location_type.dart';
import '../models/core/service_category.dart';
import '../models/core/service_sub_category.dart';

/// Core Service — API/data layer.
class CoreService {
  final ApiService _apiService;

  CoreService(this._apiService);

  /// Gets approval statuses.
  /// API: GET /core/approval-status/get_all/
  Future<List<StatusItem>> getApprovalStatuses() async {
    final response = await _apiService.get(
      ApiEndpoints.coreApprovalStatusGetAll,
    );
    final jsonData = jsonDecode(response.body);
    return _parseStatusList(jsonData);
  }

  /// Gets booking statuses.
  /// API: GET /core/booking-status/get_all/
  Future<List<StatusItem>> getBookingStatuses() async {
    final response = await _apiService.get(
      ApiEndpoints.coreBookingStatusGetAll,
    );
    final jsonData = jsonDecode(response.body);
    return _parseStatusList(jsonData);
  }

  /// Gets payment statuses.
  /// API: GET /core/payment-status/get_all/
  Future<List<StatusItem>> getPaymentStatuses() async {
    final response = await _apiService.get(
      ApiEndpoints.corePaymentStatusGetAll,
    );
    final jsonData = jsonDecode(response.body);
    return _parseStatusList(jsonData);
  }

  /// Parses status list.
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

  /// Gets location type.
  /// API: GET /core/location-type/get/
  Future<LocationType> getLocationType(int locationTypeId) async {
    final response = await _apiService.get(
      ApiEndpoints.coreLocationTypeGet,
      queryParameters: {'location_type_id': locationTypeId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, LocationType.fromJson).data;
  }

  /// Gets all location types.
  /// API: GET /core/location-type/get_all/
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

  /// Gets service category.
  /// API: GET /core/service-category/get/
  Future<ServiceCategory> getServiceCategory(int categoryId) async {
    final response = await _apiService.get(
      ApiEndpoints.coreServiceCategoryGet,
      queryParameters: {'category_id': categoryId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, ServiceCategory.fromJson).data;
  }

  /// Gets all service categories.
  /// API: GET /core/service-category/get_all/
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

  /// Gets service sub category.
  /// API: GET /core/service-sub-category/get/
  Future<ServiceSubCategory> getServiceSubCategory(int subCategoryId) async {
    final response = await _apiService.get(
      ApiEndpoints.coreServiceSubCategoryGet,
      queryParameters: {'sub_category_id': subCategoryId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, ServiceSubCategory.fromJson).data;
  }

  /// Gets all service sub categories.
  /// API: GET /core/service-sub-category/get_all/
  Future<PaginatedResponse<ServiceSubCategory>> getAllServiceSubCategories({
    int limit = 10,
    int? pageNum,
    int? categoryId,
    String? categoryName, // e.g. 'Makeup Type' → ?filter_key=categoryName&filter_value=Makeup Type
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.coreServiceSubCategoryGetAll,
      queryParameters: {
        if (limit != 10) 'limit': limit.toString(),
        if (pageNum != null) 'page_num': pageNum.toString(),
        if (categoryId != null) 'filter_key': 'categoryId',
        if (categoryId != null) 'filter_value': categoryId.toString(),
        if (categoryId == null && categoryName != null) 'filter_key': 'categoryName',
        if (categoryId == null && categoryName != null) 'filter_value': categoryName,
      },
    );
    final jsonData = jsonDecode(response.body);
    return PaginatedResponse.fromJson(
      jsonData['data'],
      ServiceSubCategory.fromJson,
    );
  }
}