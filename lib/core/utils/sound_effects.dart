import 'package:audioplayers/audioplayers.dart';

/// Plays short local sound effects (e.g. new-order chime) on the current device.
class SoundEffects {
  SoundEffects._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playNewOrderBooked() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('mp3/tithuh-level-up-523624.mp3'));
    } catch (_) {
      // Non-critical: booking already succeeded even if the sound fails to play.
    }
  }
}
