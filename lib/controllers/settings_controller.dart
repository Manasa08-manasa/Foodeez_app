import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the restaurant's toggle settings (auto-accept, busy mode, etc).
class SettingsController extends ChangeNotifier {
  final Map<String, bool> settings = {
    'autoAccept': false,
    'busyMode': false,
    'veg': false,
    'petpooja': true,
    'kotPrinter': true,
  };

  void toggleSetting(String key) {
    settings[key] = !(settings[key] ?? false);
    notifyListeners();
  }
}

final settingsControllerProvider =
    ChangeNotifierProvider<SettingsController>((ref) => SettingsController());
