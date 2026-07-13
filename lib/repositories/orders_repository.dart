import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/api/order_models.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.read(dioProvider));
});

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  Future<List<ApiOrder>> getLiveOrders() async {
    try {
      final res = await _dio.get(ApiEndpoints.partnerOrders);
      return unwrapList(res.data).whereType<Map>().map((e) => ApiOrder.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ApiOrder>> getRestaurantOrders({
    String? status,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.restaurantOrders,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return unwrapList(res.data).whereType<Map>().map((e) => ApiOrder.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiOrder> getOrder(String orderId) async {
    try {
      final res = await _dio.get(ApiEndpoints.restaurantOrder(orderId));
      return ApiOrder.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiOrder> acceptOrder(String orderId, int prepTimeMinutes) async {
    try {
      final res = await _dio.patch(
        ApiEndpoints.partnerOrderAccept(orderId),
        data: {'prep_time_minutes': prepTimeMinutes},
      );
      return ApiOrder.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> rejectOrder(String orderId, {String? reason}) async {
    try {
      await _dio.patch(
        ApiEndpoints.partnerOrderReject(orderId),
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiOrder> markReady(String orderId) async {
    try {
      final res = await _dio.patch(ApiEndpoints.partnerOrderReady(orderId), data: {});
      return ApiOrder.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiOrder> updateStatus(String orderId, String status, {String? note}) async {
    try {
      final res = await _dio.patch(
        ApiEndpoints.restaurantOrderStatus(orderId),
        data: {'status': status, if (note != null) 'note': note},
      );
      return ApiOrder.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<SettlementSummaryDto> getSettlementToday() async {
    try {
      final res = await _dio.get(ApiEndpoints.settlementToday);
      return SettlementSummaryDto.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<SettlementOrderDto>> getSettlementTodayOrders() async {
    try {
      final res = await _dio.get(ApiEndpoints.settlementTodayOrders);
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => SettlementOrderDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
