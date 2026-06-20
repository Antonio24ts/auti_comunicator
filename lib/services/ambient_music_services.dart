import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../core/settings/app_settings.dart';

class AmbientMusicService {
  static const String _musicAssetPath = 'assets/audio/musica_relajante.mp3';

  final AudioPlayer _player = AudioPlayer();

  bool _isInitialized = false;
  bool _isEnabled = false;
  bool _pausedForSpeech = false;
  double _volume = 0.12;

  Future<void> init(AppSettings settings) async {
    if (!_isInitialized) {
      await _player.setAsset(_musicAssetPath);
      await _player.setLoopMode(LoopMode.one);

      _isInitialized = true;
    }

    await applySettings(settings);
  }

  Future<void> applySettings(AppSettings settings) async {
    _isEnabled = settings.ambientMusicEnabled;
    _volume = settings.ambientMusicVolume.clamp(0.0, 1.0);

    await _player.setVolume(_volume);

    if (!_isEnabled) {
      _pausedForSpeech = false;
      await _player.pause();
      return;
    }

    if (!_pausedForSpeech && !_player.playing) {
      unawaited(_player.play());
    }
  }

  Future<void> pauseForSpeech() async {
    if (!_isInitialized || !_isEnabled || !_player.playing) {
      return;
    }

    _pausedForSpeech = true;
    await _player.pause();
  }

  Future<void> resumeAfterSpeech() async {
    if (!_isInitialized || !_isEnabled || !_pausedForSpeech) {
      return;
    }

    _pausedForSpeech = false;

    if (!_player.playing) {
      unawaited(_player.play());
    }
  }

  Future<void> stop() async {
    _pausedForSpeech = false;
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
