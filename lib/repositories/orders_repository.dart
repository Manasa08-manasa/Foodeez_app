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
    String? dateFrom,
    String? dateTo,
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
          if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
        },
      );
      return unwrapList(res.data).whereType<Map>().map((e) => ApiOrder.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Orders screen — GET /partner/orders (PLACED, ACCEPTED, PREPARING).
  Future<List<ApiOrder>> getPartnerActiveOrders() => getLiveOrders();

  /// Home live orders — GET /restaurant/orders?page=1&limit=20&status=PLACED,CONFIRMED,PREPARING,READY_FOR_PICKUP
  Future<List<ApiOrder>> getHomeLiveOrders() {
    return getRestaurantOrders(
      page: AppConstants.homeLiveOrdersPage,
      limit: AppConstants.homeLiveOrdersLimit,
      status: AppConstants.homeLiveOrderStatuses,
    );
  }

  Future<List<ApiOrder>> getOngoingOrders() {
    return getRestaurantOrders(
      page: AppConstants.ordersPage,
      limit: AppConstants.ordersLimit,
      status: AppConstants.ongoingOrderStatuses,
    );
  }

  Future<List<ApiOrder>> getReadyOrders() {
    return getRestaurantOrders(
      page: AppConstants.ordersPage,
      limit: AppConstants.ordersLimit,
      status: AppConstants.readyOrderStatuses,
    );
  }

  /// Completed orders — today only (for the Completed tab).
  Future<List<ApiOrder>> getCompletedOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getRestaurantOrders(
      page: AppConstants.ordersPage,
      limit: AppConstants.historyOrdersLimit,
      status: AppConstants.completedOrderStatuses,
      dateFrom: startOfDay.toIso8601String(),
    );
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
