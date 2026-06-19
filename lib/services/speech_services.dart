import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  int _speakRequestId = 0;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.50);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    // No queremos bloquear la app esperando a que termine cada palabra.
    await _flutterTts.awaitSpeakCompletion(false);

    _isInitialized = true;
  }

  Future<void> speakWord(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    final currentRequestId = ++_speakRequestId;

    await _flutterTts.stop();

    // Evita que una pulsación antigua hable después de una nueva.
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
      await init();
    }

    final currentRequestId = ++_speakRequestId;

    await _flutterTts.stop();

    // Para frases completas sí dejamos un micro-respiro al motor.
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
