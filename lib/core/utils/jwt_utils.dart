import 'dart:convert';

class JwtUtils {
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool isExpired(String token) {
    final payload = decode(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
    return DateTime.now().isAfter(expiry);
  }

  static String? getRole(String token) => decode(token)?['role']?.toString();
  static String? getEmail(String token) => decode(token)?['email']?.toString();
  static String? getDisplayName(String token) =>
      (decode(token)?['displayName'] ?? decode(token)?['name'])?.toString();
  static String? getRestaurantId(String token) => decode(token)?['restaurantId']?.toString();
}
