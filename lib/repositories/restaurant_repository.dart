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
    try {
      await _dio.post(ApiEndpoints.restaurantUsers(restaurantId), data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
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
