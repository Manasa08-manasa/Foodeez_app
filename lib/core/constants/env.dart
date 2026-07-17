/// Runtime configuration via `--dart-define` (optional).
///
/// Default (production):
///   https://int.foodeez.in/restaurant/api/v1
///
/// Local dev:
///   `--dart-define=API_BASE_URL=http://localhost:3001/api/v1`
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://int.foodeez.in/restaurant/api/v1',
  );

  static const String passwordEncryptionKeyHex = String.fromEnvironment(
    'PASSWORD_KEY',
    defaultValue: '4f3e2a1b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f',
  );

  /// Web encrypts passwords; live mobile Partner portal sends plain text.
  /// Backend accepts both (decrypt, then fall back to plain).
  /// Default false so valid credentials work without a matching AES key.
  static const bool encryptPassword = bool.fromEnvironment(
    'ENCRYPT_PASSWORD',
    defaultValue: false,
  );

  /// Google Maps SDK / Static Maps / Places — override with:
  /// `--dart-define=GOOGLE_MAPS_API_KEY=...`
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDW9niCHIcWO0h096PG7ES8MMw8o9cliAU',
  );

  /// Razorpay **key_id** only — safe for client apps. Never put key_secret here.
  /// Server create-order may also return keyId; this is the fallback.
  /// Override: `--dart-define=RAZORPAY_KEY_ID=rzp_live_...`
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_live_T5p40dPxB7KUEL',
  );
}
