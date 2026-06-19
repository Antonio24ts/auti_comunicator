import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  int _speakRequestId = 0;
  double _speechRate = 0.55;

  Future<void> init({double speechRate = 0.55}) async {
    if (_isInitialized) {
      await setSpeechRate(speechRate);
      return;
    }

    _speechRate = speechRate;

    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    await _flutterTts.awaitSpeakCompletion(false);

    _isInitialized = true;
  }

  Future<void> setSpeechRate(double speechRate) async {
    _speechRate = speechRate;

    if (!_isInitialized) {
      return;
    }

    await _flutterTts.setSpeechRate(_speechRate);
  }

  Future<void> speakWord(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    if (!_isInitialized) {
      await init(speechRate: _speechRate);
    }

    final currentRequestId = ++_speakRequestId;

    await _flutterTts.stop();

    if (currentRequestId != _speakRequestId) {
      return;
    }

    await _flutterTts.speak(cleanText);
  }

  Future<void> speakPhrase(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    if (!_isInitialized) {
      await init(speechRate: _speechRate);
    }

    final currentRequestId = ++_speakRequestId;

    await _flutterTts.stop();
    await Future.delayed(const Duration(milliseconds: 20));

    if (currentRequestId != _speakRequestId) {
      return;
    }

    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    _speakRequestId++;
    await _flutterTts.stop();
  }
}
