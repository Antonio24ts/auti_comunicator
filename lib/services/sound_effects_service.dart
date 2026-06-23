import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class SoundEffectsService {
  static const String _errorSoundAssetPath = 'assets/audio/error_suave.wav';

  final AudioPlayer _errorPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<void> init() async {
    if (_isInitialized || _isInitializing) {
      return;
    }

    _isInitializing = true;

    try {
      await _errorPlayer.setAsset(_errorSoundAssetPath);
      await _errorPlayer.setVolume(0.8);

      _isInitialized = true;
    } catch (error, stackTrace) {
      debugPrint('[SoundEffects] Error cargando sonido: $error');
      debugPrint('$stackTrace');
    } finally {
      _isInitializing = false;
    }
  }

  void playError() {
    if (!_isInitialized) {
      unawaited(_playFallbackError());
      return;
    }

    try {
      unawaited(_restartAndPlayError());
    } catch (error, stackTrace) {
      debugPrint('[SoundEffects] Error reproduciendo sonido: $error');
      debugPrint('$stackTrace');

      unawaited(_playFallbackError());
    }
  }

  Future<void> _restartAndPlayError() async {
    await _errorPlayer.seek(Duration.zero);
    unawaited(_errorPlayer.play());
  }

  Future<void> _playFallbackError() async {
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> dispose() async {
    await _errorPlayer.dispose();
  }
}
