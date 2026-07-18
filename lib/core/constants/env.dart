/// Runtime configuration via `--dart-define` / `--dart-define-from-file`.
///
/// Secrets must NOT be committed. For release builds use:
///   flutter build appbundle --dart-define-from-file=dart_defines.release.json
///   flutter build ipa --dart-define-from-file=dart_defines.release.json
///
/// See `dart_defines.release.example.json` and native secrets:
///   android/secrets.properties
///   ios/Flutter/Secrets.xcconfig
class Env {
  /// Production API. Override for staging/local:
  /// `--dart-define=API_BASE_URL=https://int.foodeez.in/restaurant/api/v1`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://int.foodeez.in/restaurant/api/v1',
  );

  /// AES key hex for encrypted login payloads. Empty = skip client encryption.
  static const String passwordEncryptionKeyHex = String.fromEnvironment(
    'PASSWORD_KEY',
    defaultValue: '',
  );

  /// Web encrypts passwords; live mobile Partner portal often sends plain text.
  /// Backend accepts both (decrypt, then fall back to plain).
  static const bool encryptPassword = bool.fromEnvironment(
    'ENCRYPT_PASSWORD',
    defaultValue: false,
  );

  /// Google Maps (Dart/Static Maps). Native SDKs use secrets.properties / Secrets.xcconfig.
  /// `--dart-define=GOOGLE_MAPS_API_KEY=...`
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Razorpay **key_id** only — never put key_secret in the app.
  /// `--dart-define=RAZORPAY_KEY_ID=rzp_live_...`
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );
}
