# Foodeez Partner — release / store signing notes
#
# Bundle IDs
#   Android: com.foodeez.foodeez_partner
#   iOS:     com.foodeez.foodeezPartner
#
# Upload keystore (gitignored)
#   android/app/upload-keystore.jks
#   android/key.properties
#   Alias: upload
#   SHA-1 (restrict Maps API key to this + package name):
#     C8:2C:F6:05:36:42:A6:61:EC:75:7F:22:A2:BB:AD:52:8D:A5:13:BD
#
# Google Maps lockdown (Cloud Console → Credentials → your key → Application restrictions)
#   Android apps: com.foodeez.foodeez_partner + SHA-1 above
#   iOS apps:     com.foodeez.foodeezPartner
#   Also enable: Maps SDK for Android, Maps SDK for iOS (and Static Maps if used)
#
# Native Maps key files (gitignored; copy from *.example)
#   android/secrets.properties
#   ios/Flutter/Secrets.xcconfig
#
# Dart secrets for release
#   cp dart_defines.release.example.json dart_defines.release.json
#   # edit values, then:
#   flutter build appbundle --dart-define-from-file=dart_defines.release.json
#   flutter build ipa --dart-define-from-file=dart_defines.release.json
#
# Never commit: key.properties, *.jks, secrets.properties, Secrets.xcconfig, dart_defines.release.json
