import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';

class AppNotification {
  final String id;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id']?.toString() ?? '',
        title: (json['title'] ?? json['message'] ?? '').toString(),
        body: json['body']?.toString(),
        isRead: json['isRead'] == true || json['read'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(dioProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get(ApiEndpoints.notificationsUnread);
      final data = unwrapObject(res.data);
      return (data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<AppNotification>> list({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get(ApiEndpoints.notifications, queryParameters: {'page': page, 'limit': limit});
      return unwrapList(res.data, keys: const ['items', 'data', 'notifications', 'results'])
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch(ApiEndpoints.notificationRead(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch(ApiEndpoints.notificationsReadAll);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
