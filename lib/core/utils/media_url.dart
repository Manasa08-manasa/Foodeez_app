import '../constants/env.dart';

/// Resolves relative media paths the same way restaurant-admin `resolveMediaUrl` does.
String? resolveMediaUrl(String? mediaPath) {
  if (mediaPath == null || mediaPath.isEmpty) return null;
  if (RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(mediaPath) || mediaPath.startsWith('//')) {
    return mediaPath;
  }
  final origin = Env.apiBaseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  final path = mediaPath.startsWith('/') ? mediaPath : '/$mediaPath';
  return '$origin$path';
}
