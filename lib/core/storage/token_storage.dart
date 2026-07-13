import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  static bool get _isTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// In-memory fallback used under `flutter test` where secure storage plugins
  /// are unavailable / hang.
  static String? _memoryToken;

  static Future<void> saveToken(String token) async {
    if (_isTest) {
      _memoryToken = token;
      return;
    }
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (e) {
      debugPrint('[TokenStorage] saveToken failed: $e');
      _memoryToken = token;
    }
  }

  static Future<String?> getToken() async {
    if (_isTest) return _memoryToken;
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (e) {
      debugPrint('[TokenStorage] getToken failed: $e');
      return _memoryToken;
    }
  }

  static Future<void> clearToken() async {
    _memoryToken = null;
    if (_isTest) return;
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (e) {
      debugPrint('[TokenStorage] clearToken failed: $e');
    }
  }

  static Future<void> clear() async {
    _memoryToken = null;
    if (_isTest) return;
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[TokenStorage] clear failed: $e');
    }
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
