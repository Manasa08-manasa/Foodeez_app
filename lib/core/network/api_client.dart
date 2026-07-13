import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        // Never wipe session on login/auth failures — those 401s mean bad
        // credentials, not an expired token.
        final isAuthCall = path.contains('/auth/login') ||
            path.contains('/auth/partner/login') ||
            path.contains('/auth/password-reset');
        if (status == 401 && !isAuthCall) {
          debugPrint('[Dio] 401 → clearing token ($path)');
          await TokenStorage.clearToken();
        } else if (status == 401) {
          debugPrint('[Dio] 401 on auth call ($path) — not clearing token');
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    final code = e.response?.statusCode;
    String msg = 'Something went wrong';
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      msg = m is List ? m.first.toString() : m.toString();
    } else if (e.type == DioExceptionType.connectionTimeout) {
      msg = 'Connection timed out';
    } else if (e.type == DioExceptionType.connectionError) {
      final host = e.requestOptions.uri.host;
      final detail = e.message ?? e.error?.toString() ?? '';
      msg = 'Cannot reach $host. Check internet connection'
          '${detail.isNotEmpty ? ' ($detail)' : ''}';
    } else if (e.type == DioExceptionType.badCertificate) {
      msg = 'Secure connection failed (SSL). Check device date/time.';
    } else if (code == 404) {
      msg = 'API not found (404). Check API_BASE_URL (${e.requestOptions.uri}).';
    } else if (code != null) {
      msg = 'Request failed ($code)';
    }
    return ApiException(msg, statusCode: code);
  }
}

/// Unwrap common list response shapes used by the restaurant-admin APIs.
List<dynamic> unwrapList(
  dynamic data, {
  List<String> keys = const [
    'data',
    'items',
    'results',
    'orders',
    'documents',
    'branches',
    'categories',
    'menuItems',
    'menu_items',
  ],
}) {
  if (data is List) return data;
  if (data is Map) {
    for (final key in keys) {
      if (data[key] is List) return data[key] as List;
    }
    // Nested: { data: { items: [...] } } / { data: { orders: [...] } }
    final nested = data['data'];
    if (nested is Map) {
      for (final key in keys) {
        if (key == 'data') continue;
        if (nested[key] is List) return nested[key] as List;
      }
    }
  }
  return const [];
}

Map<String, dynamic> unwrapObject(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data['data'] is Map<String, dynamic>) return data['data'] as Map<String, dynamic>;
    if (data['order'] is Map<String, dynamic>) return data['order'] as Map<String, dynamic>;
    return data;
  }
  if (data is Map) return Map<String, dynamic>.from(data);
  return {};
}
