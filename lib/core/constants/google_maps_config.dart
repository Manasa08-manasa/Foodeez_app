import '../constants/env.dart';

/// Helpers that need the Google Maps API key from Dart (Static Maps, Places, etc.).
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static String get apiKey => Env.googleMapsApiKey;

  /// Static Maps image URL for a lat/lng pin (useful for list thumbnails).
  static String staticMapUrl({
    required double lat,
    required double lng,
    int width = 600,
    int height = 300,
    int zoom = 15,
  }) {
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=color:red%7C$lat,$lng'
        '&key=$apiKey';
  }
}
