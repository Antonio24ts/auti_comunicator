import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> init() async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }
}
