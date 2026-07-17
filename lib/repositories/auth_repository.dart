import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/env.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/crypto_utils.dart';
import '../core/utils/jwt_utils.dart';
import '../models/api/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthUser> login(String email, String password) async {
    // Prefer plain text (Partner mobile default). If ENCRYPT_PASSWORD=true,
    // try encrypted first, then fall back to plain on 401 — backend accepts both.
    if (Env.encryptPassword) {
      try {
        return await _loginRequest(email, CryptoUtils.encryptPassword(password));
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          debugPrint('[Auth] encrypted login 401 → retrying plain password');
          return _loginRequest(email, password);
        }
        rethrow;
      }
    }
    return _loginRequest(email, password);
  }

  Future<AuthUser> _loginRequest(String email, String passwordPayload) async {
    try {
      debugPrint('[Auth] POST ${ApiEndpoints.login} email=$email encrypt=${passwordPayload.contains(':')}');
      final res = await _dio.post(ApiEndpoints.login, data: {
        'email': email.trim(),
        'password': passwordPayload,
      });

      final token = res.data['accessToken'] as String?;
      if (token == null || token.isEmpty) {
        throw ApiException('Login failed: no access token returned');
      }

      final payload = JwtUtils.decode(token) ?? {};
      final userMap = res.data['user'] is Map
          ? Map<String, dynamic>.from(res.data['user'] as Map)
          : <String, dynamic>{};
      final role = (payload['role'] ?? userMap['role'] ?? '').toString();

      debugPrint('[Auth] login ok role=$role restaurantId=${payload['restaurantId']}');

      if (role.isNotEmpty && !AppConstants.restaurantRoles.contains(role)) {
        throw ApiException(
          'Access denied. This app is only for restaurant partners (got: $role).',
          statusCode: 403,
        );
      }

      await TokenStorage.saveToken(token);

      return AuthUser(
        token: token,
        role: role.isEmpty ? AppConstants.roleRestaurantAdmin : role,
        email: (userMap['email'] ?? payload['email'] ?? email).toString(),
        displayName: (userMap['displayName'] ??
                payload['displayName'] ??
                payload['name'] ??
                email)
            .toString(),
        restaurantId: (payload['restaurantId'] ?? userMap['restaurantId'])?.toString(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserProfile> getMe() async {
    try {
      final res = await _dio.get(ApiEndpoints.me);
      return UserProfile.fromJson(unwrapObject(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post(ApiEndpoints.passwordReset, data: {'email': email.trim()});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
  }

  Future<AuthUser?> getStoredUser() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return null;
    if (JwtUtils.isExpired(token)) {
      await TokenStorage.clearToken();
      return null;
    }
    final payload = JwtUtils.decode(token);
    if (payload == null) return null;
    final role = (payload['role'] ?? '').toString();
    if (role.isNotEmpty && !AppConstants.restaurantRoles.contains(role)) {
      await TokenStorage.clearToken();
      return null;
    }
    return AuthUser(
      token: token,
      role: role.isEmpty ? AppConstants.roleRestaurantAdmin : role,
      email: (payload['email'] ?? '').toString(),
      displayName: (payload['displayName'] ?? payload['name'] ?? payload['email'] ?? '').toString(),
      restaurantId: payload['restaurantId']?.toString(),
    );
  }
}
