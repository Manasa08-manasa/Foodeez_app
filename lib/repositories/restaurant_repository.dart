import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/api/menu_models.dart';
import '../models/api/restaurant_models.dart';
import '../models/api/user_models.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.read(dioProvider));
});

List<Map<String, dynamic>> buildInvitePayloadVariants(Map<String, dynamic> data) {
  final displayName = (data['displayName'] ?? data['name'] ?? '').toString().trim();
  final email = (data['email'] ?? data['emailAddress'] ?? '').toString().trim();
  final role = (data['role'] ?? '').toString().trim();
  final roleVariants = <String>{
    role,
    if (role.startsWith('restaurant_')) role.replaceFirst('restaurant_', ''),
    if (role == 'restaurant_owner') 'owner',
    if (role == 'restaurant_manager') 'manager',
    if (role == 'restaurant_staff') 'staff',
    if (role == 'sales_operator') 'sales',
    if (role == 'sales') 'sales_operator',
  }.where((value) => value.isNotEmpty).toList();

  if (roleVariants.isEmpty) {
    roleVariants.add(role);
  }

  return roleVariants
      .map(
        (roleVariant) => {
          'name': displayName,
          'displayName': displayName,
          'email': email,
          'role': roleVariant,
        },
      )
      .toList();
}

class RestaurantRepository {
  RestaurantRepository(this._dio);

  final Dio _dio;

  Future<ApiRestaurant> getRestaurant(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.restaurant(id));
      return ApiRestaurant.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiRestaurant> updateRestaurant(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch(ApiEndpoints.restaurant(id), data: data);
      return ApiRestaurant.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ApiBranch>> getBranches(String restaurantId) async {
    try {
      final res = await _dio.get(ApiEndpoints.branches(restaurantId));
      return unwrapList(res.data, keys: const ['branches', 'data', 'items', 'results'])
          .whereType<Map>()
          .map((e) => ApiBranch.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiBranch> getBranch(String restaurantId, String branchId) async {
    try {
      final res = await _dio.get(ApiEndpoints.branch(restaurantId, branchId));
      return ApiBranch.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiBranch> createBranch(String restaurantId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(ApiEndpoints.branches(restaurantId), data: data);
      return ApiBranch.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiBranch> updateBranch(
    String restaurantId,
    String branchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.patch(ApiEndpoints.branch(restaurantId, branchId), data: data);
      return ApiBranch.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiBranch> toggleOnline(String restaurantId, String branchId, bool isOnline) {
    return updateBranch(restaurantId, branchId, {'isOnline': isOnline});
  }

  Future<List<ApiMenuCategory>> getCategories(String branchId) async {
    try {
      final res = await _dio.get(ApiEndpoints.menuCategories(branchId));
      return unwrapList(res.data, keys: const ['categories', 'data', 'items', 'results'])
          .whereType<Map>()
          .map((e) => ApiMenuCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiMenuCategory> createCategory(String branchId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(ApiEndpoints.menuCategories(branchId), data: data);
      return ApiMenuCategory.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ApiMenuItem>> getMenuItems(String branchId) async {
    try {
      final res = await _dio.get(ApiEndpoints.menuItems(branchId));
      return unwrapList(
        res.data,
        keys: const ['menuItems', 'items', 'data', 'results'],
      )
          .whereType<Map>()
          .map((e) => ApiMenuItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiMenuItem> createMenuItem(String branchId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(ApiEndpoints.menuItems(branchId), data: data);
      return ApiMenuItem.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiMenuItem> updateMenuItem(String itemId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch(ApiEndpoints.menuItem(itemId), data: data);
      return ApiMenuItem.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ApiRestaurantUser>> getRestaurantUsers(String restaurantId) async {
    try {
      final res = await _dio.get(ApiEndpoints.restaurantUsers(restaurantId));
      return unwrapList(res.data, keys: const ['users', 'data', 'items', 'results'])
          .whereType<Map>()
          .map((e) => ApiRestaurantUser.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> inviteRestaurantUser(String restaurantId, Map<String, dynamic> data) async {
    final payloads = buildInvitePayloadVariants(data);
    Object? lastError;

    for (final payload in payloads) {
      try {
        await _dio.post(ApiEndpoints.restaurantUsers(restaurantId), data: payload);
        return;
      } on DioException catch (e) {
        lastError = e;
      }
    }

    if (lastError is DioException) {
      throw ApiException.fromDioError(lastError);
    }

    throw ApiException('Unable to invite user. Check the email and role.');
  }

  Future<List<ApiCoupon>> getCoupons(String restaurantId) async {
    try {
      final res = await _dio.get(ApiEndpoints.coupons(restaurantId));
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => ApiCoupon.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiCoupon> createCoupon(String restaurantId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(ApiEndpoints.coupons(restaurantId), data: data);
      return ApiCoupon.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ApiDocument>> getDocuments(String restaurantId) async {
    try {
      final res = await _dio.get(ApiEndpoints.restaurantDocuments(restaurantId));
      return unwrapList(res.data, keys: const ['documents', 'data', 'items', 'results'])
          .whereType<Map>()
          .map((e) => ApiDocument.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Customer-submitted reviews for a restaurant (main API, restaurant JWT).
  Future<List<Map<String, dynamic>>> getRestaurantReviews(
    String restaurantId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.restaurantReviews(restaurantId),
        queryParameters: {'page': page, 'limit': limit},
      );
      return unwrapList(res.data, keys: const ['reviews', 'data', 'items', 'results'])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
