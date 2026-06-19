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

    // Importante:
    // false = no bloquea esperando a que termine cada palabra.
    await _flutterTts.awaitSpeakCompletion(false);

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

    // Corta la palabra anterior si el usuario pulsa otra rápido.
    await _flutterTts.stop();

    // Pequeña pausa para evitar que algunos dispositivos ignoren el nuevo speak.
    await Future.delayed(const Duration(milliseconds: 40));

    await _flutterTts.speak(cleanText);
  }

  Future<void> speakPhrase(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    await _flutterTts.stop();
    await Future.delayed(const Duration(milliseconds: 40));

    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
