import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}