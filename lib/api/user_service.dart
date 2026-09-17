import 'dart:convert';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../utils/paginated_response.dart';
import '../utils/api_response.dart';
import '../models/user/user_profile.dart';
import '../models/user/user_profile_update.dart';
import '../models/user/customer_address.dart';
import '../models/user/customer_address_create.dart';
import '../models/user/customer_address_update.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  // Profile
  Future<UserProfile> getProfile(int userId) async {
    final response = await _apiService.get(
      ApiEndpoints.usersProfileGet,
      queryParameters: {'user_id': userId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, UserProfile.fromJson).data;
  }

  Future<void> updateProfile(UserProfileUpdate data) async {
    await _apiService.put(
      ApiEndpoints.usersProfileUpdate,
      data: data.toJson(),
    );
  }

  /// Sends this device's current FCM token to the backend through the
  /// *real* profile-update endpoint — this backend has no separate
  /// /users/fcm-token/update/ route (that 404'd; confirmed via debug
  /// logs). GET /users/profile/get/ already returns an `fcmToken` field
  /// on the user object, so PUT /users/profile/update/ with `fcm_token`
  /// in the body is how it's meant to be set. An alternative/backup to
  /// the Firestore `fcm_tokens/<userId>` doc that [PushNotificationService]
  /// also writes — best-effort, never blocks push setup if it fails.
  ///
  /// [platform] isn't sent — the real endpoint only accepts `fcm_token`
  /// alongside the usual profile fields (see [UserProfileUpdate]).
  Future<void> updateFcmToken(String fcmToken, {String? platform}) async {
    await updateProfile(UserProfileUpdate(fcmToken: fcmToken));
  }

  // Address
  Future<void> createAddress(CustomerAddressCreate data) async {
    await _apiService.post(
      ApiEndpoints.usersAddressCreate,
      data: data.toJson(),
    );
  }

  Future<CustomerAddress> getAddress(int addressId) async {
    final response = await _apiService.get(
      ApiEndpoints.usersAddressGet,
      queryParameters: {'address_id': addressId.toString()},
    );
    final jsonData = jsonDecode(response.body);
    return ApiResponse.fromJson(jsonData, CustomerAddress.fromJson).data;
  }

  Future<PaginatedResponse<CustomerAddress>> getAllAddresses({
    int limit = 10,
    int? pageNum,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.usersAddressGetAll,
      queryParameters: {
        if (limit != 10) 'limit': limit.toString(),
        if (pageNum != null) 'page_num': pageNum.toString(),
      },
    );
    final jsonData = jsonDecode(response.body);
    return PaginatedResponse.fromJson(
      jsonData['data'],
      CustomerAddress.fromJson,
    );
  }

  Future<void> updateAddress(CustomerAddressUpdate data) async {
    await _apiService.put(
      ApiEndpoints.usersAddressUpdate,
      data: data.toJson(),
    );
  }

  Future<void> deleteAddress(int addressId) async {
    await _apiService.delete(
      ApiEndpoints.usersAddressDelete,
      queryParameters: {'address_id': addressId.toString()},
    );
  }
}
