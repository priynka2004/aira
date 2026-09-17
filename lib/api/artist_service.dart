import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/auth/add_block.dart';
import '../models/auth/add_location.dart';
import '../models/auth/set_schedule.dart';
import '../utils/app_session.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../utils/paginated_response.dart';
import '../utils/api_response.dart';
import '../models/artist/artist_profile.dart';
import '../models/artist/artist_profile_update.dart';
import '../models/artist/portfolio.dart';
import '../models/artist/create_portfolio.dart';
import '../models/artist/update_portfolio.dart';
import '../models/artist/package.dart';
import '../models/artist/create_package.dart';
import '../models/artist/update_package.dart';
import '../models/artist/add_service.dart';

class ArtistService {
  final ApiService _apiService;
  ArtistService(this._apiService);

  // ── Profile ──────────────────────────────────────────────────────────────
  Future<ArtistProfile> getProfile({int? artistId}) async {
    final response = await _apiService.get(
      ApiEndpoints.artistsProfileGet,
      queryParameters: artistId != null ? {'artist_id': artistId.toString()} : null,
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, ArtistProfile.fromJson).data;
  }

  Future<void> updateProfile(ArtistProfileUpdate data) async {
    await _apiService.put(ApiEndpoints.artistsProfileUpdate, data: data.toJson());
  }

  // ── Portfolio ────────────────────────────────────────────────────────────
  Future<void> createPortfolio(CreatePortfolio data) async {

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.artistsPortfolioCreate}',
      ),
    );

    request.fields['media_type'] = data.mediaType.name;

    request.fields['sub_category_id'] =
        data.subCategoryId.toString();

    if(data.caption != null){
      request.fields['caption'] = data.caption!;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        data.file.path,
        filename: data.file.name,
      ),
    );

    request.headers.addAll({
      'Authorization':
      'Bearer ${AppSession.instance.accessToken}',
    });

    final response = await request.send();

    final responseBody =
    await response.stream.bytesToString();

    debugPrint("Portfolio Create Response => $responseBody");

    if(response.statusCode != 200 &&
        response.statusCode != 201){

      throw Exception(responseBody);

    }

  }
  Future<Portfolio> getPortfolio(int portfolioId) async {
    final response = await _apiService.get(
      ApiEndpoints.artistsPortfolioGet,
      queryParameters: {'portfolio_id': portfolioId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, Portfolio.fromJson).data;
  }

  Future<PaginatedResponse<Portfolio>> getAllPortfolios({
    int limit = 10, int? pageNum, String? sortBy, String? sortOrder,
    String? searchKey, String? filterKey, String? filterValue,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.artistsPortfolioGetAll,
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
    return PaginatedResponse.fromJson(jsonData['data'], Portfolio.fromJson);
  }

  Future<void> updatePortfolio(UpdatePortfolio data) async {
    await _apiService.put(ApiEndpoints.artistsPortfolioUpdate, data: data.toJson());
  }

  Future<void> deletePortfolio(int portfolioId) async {
    await _apiService.delete(
      ApiEndpoints.artistsPortfolioDelete,
      queryParameters: {'portfolio_id': portfolioId.toString()},
    );
  }

  // ── Packages ─────────────────────────────────────────────────────────────
  Future<void> createPackage(CreatePackage data) async {
    debugPrint("Create Package Request => ${data.toJson()}");

    await _apiService.post(
      ApiEndpoints.artistsPackagesCreate,
      data: data.toJson(),
    );
  }

  Future<Package> getPackage(int packageId) async {
    final response = await _apiService.get(
      ApiEndpoints.artistsPackagesGet,
      queryParameters: {'package_id': packageId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, Package.fromJson).data;
  }

  Future<PaginatedResponse<Package>> getAllPackages({
    int limit = 10, int? pageNum, String? sortBy, String? sortOrder,
    String? filterKey, String? filterValue, String? searchKey,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.artistsPackagesGetAll,
      queryParameters: {
        if (limit != 10) 'limit': limit.toString(),
        if (pageNum != null) 'page_num': pageNum.toString(),
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (filterKey != null) 'filter_key': filterKey,
        if (filterValue != null) 'filter_value': filterValue,
        if (searchKey != null) 'search_key': searchKey,
      },
    );
    final jsonData = jsonDecode(response.body);
    return PaginatedResponse.fromJson(jsonData['data'], Package.fromJson);
  }

  Future<void> updatePackage(UpdatePackage data) async {
    await _apiService.put(ApiEndpoints.artistsPackagesUpdate, data: data.toJson());
  }

  Future<void> deletePackage(int packageId) async {
    await _apiService.delete(
      ApiEndpoints.artistsPackagesDelete,
      queryParameters: {'package_id': packageId.toString()},
    );
  }

  // ── Services ─────────────────────────────────────────────────────────────
  Future<void> addService(AddService data) async {
    await _apiService.post(ApiEndpoints.artistsServicesAdd, data: data.toJson());
  }

  Future<dynamic> getAllServices() async {
    final response = await _apiService.get(ApiEndpoints.artistsServicesGetAll);
    return jsonDecode(response.body);
  }

  Future<void> removeService(int subCategoryId) async {
    await _apiService.delete(
      ApiEndpoints.artistsServicesRemove,
      queryParameters: {'sub_category_id': subCategoryId.toString()},
    );
  }

  // ── Locations ─────────────────────────────────────────────────────────────
  Future<void> addLocation(AddLocation data) async {
    await _apiService.post(ApiEndpoints.artistsLocationsAdd, data: data.toJson());
  }

  Future<dynamic> getAllLocations() async {
    final response = await _apiService.get(ApiEndpoints.artistsLocationsGetAll);
    return jsonDecode(response.body);
  }

  Future<void> removeLocation(int locationTypeId) async {
    await _apiService.delete(
      ApiEndpoints.artistsLocationsRemove,
      queryParameters: {'location_type_id': locationTypeId.toString()},
    );
  }

  // ── Availability – Schedule ───────────────────────────────────────────────
  Future<void> setSchedule(SetSchedule data) async {
    await _apiService.post(ApiEndpoints.artistsAvailabilityScheduleSet, data: data.toJson());
  }

  Future<dynamic> getAllSchedules() async {
    final response = await _apiService.get(ApiEndpoints.artistsAvailabilityScheduleGetAll);
    return jsonDecode(response.body);
  }

  Future<void> removeSchedule(int dayOfWeek) async {
    await _apiService.delete(
      ApiEndpoints.artistsAvailabilityScheduleRemove,
      queryParameters: {'day_of_week': dayOfWeek.toString()},
    );
  }

  // ── Availability – Block ──────────────────────────────────────────────────
  Future<void> addBlock(AddBlock data) async {
    await _apiService.post(ApiEndpoints.artistsAvailabilityBlockAdd, data: data.toJson());
  }

  Future<dynamic> getAllBlocks() async {
    final response = await _apiService.get(ApiEndpoints.artistsAvailabilityBlockGetAll);
    return jsonDecode(response.body);
  }

  Future<void> removeBlock(String blockDate) async {
    await _apiService.delete(
      ApiEndpoints.artistsAvailabilityBlockRemove,
      queryParameters: {'block_date': blockDate},
    );
  }
}
