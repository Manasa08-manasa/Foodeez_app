/// Runtime configuration via `--dart-define` (optional).
///
/// Plain `flutter run` uses these defaults — no flags required.
///
/// Live restaurant-admin API:
///   https://int.foodeez.in/restaurant/api/v1
///   e.g. POST …/auth/login
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
}
