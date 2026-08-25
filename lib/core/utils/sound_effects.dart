import 'package:audioplayers/audioplayers.dart';

/// Plays short local sound effects (e.g. new-order chime / dollar sound) on the current device.
class SoundEffects {
  SoundEffects._();

  static final AudioPlayer _player = AudioPlayer();

  /// Plays the dollar/chime sound effect when a new repairing order or transaction is booked.
  static Future<void> playNewOrderBooked() async {
    try {
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
      await _player.play(AssetSource('mp3/tithuh-level-up-523624.mp3'));
    } catch (_) {
      // Fallback attempt with default audio context if custom configuration fails
      try {
        await _player.play(AssetSource('mp3/tithuh-level-up-523624.mp3'));
      } catch (_) {
        // Non-critical: order already succeeded even if device audio is disabled
      }
    }
  }
}
