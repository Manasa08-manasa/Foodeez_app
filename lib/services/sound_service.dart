import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the new-order / notification chime.
///
/// [AssetSource] is relative to Flutter's assets folder (prefix `assets/` is
/// applied by audioplayers), so paths must not start with `assets/`.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static const _asset = 'images/universfield-school-bell-199584.mp3';
  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    _ready = true;
  }

  /// Start (or restart) the chime — loops until [stop] is called.
  static Future<void> playNewOrderSound() async {
    try {
      await _ensureReady();
      await _player.stop();
      await _player.play(AssetSource(_asset));
    } catch (e, st) {
      debugPrint('[Sound] play failed: $e\n$st');
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[Sound] stop failed: $e');
    }
  }
}
