// lib/helpers/sound_helper.dart
import 'package:audioplayers/audioplayers.dart';

class SoundHelper {
  // static final AudioPlayer _player = AudioPlayer();

  static Future<void> init() async {
    // Sementara di-nonaktifkan
    // try {
    //   await _player.setSourceAsset('assets/sounds/success.mp3');
    // } catch (e) {
    //   print('Error loading success sound: $e');
    // }
  }

  static Future<void> playSuccess() async {
    // Sementara di-nonaktifkan
    // try {
    //   await _player.play(AssetSource('assets/sounds/success.mp3'));
    // } catch (e) {
    //   print('Error playing success sound: $e');
    // }
  }

  static Future<void> playError() async {
    // Sementara di-nonaktifkan
    // try {
    //   await _player.play(AssetSource('assets/sounds/error.mp3'));
    // } catch (e) {
    //   print('Error playing error sound: $e');
    // }
  }

  static Future<void> dispose() async {
    // await _player.dispose();
  }
}
