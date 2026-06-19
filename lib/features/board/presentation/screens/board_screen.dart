import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../widgets/phrase_bar.dart';
import '../widgets/pictogram_card.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final SpeechService _speechService = SpeechService();
  final PictogramRepository _repository = PictogramRepository();

  final List<String> _selectedWords = [];
  final List<String> _categoryHistory = [];

  String _currentCategoryId = PictogramRepository.homeCategoryId;

  @override
  void initState() {
    super.initState();
    _speechService.init();
  }

  int _getCrossAxisCount(double width) {
    return 8;
  }

  void _handlePictogramTap(Pictogram pictogram) {
    if (pictogram.isCategory) {
      _openCategory(pictogram);
      return;
    }

    _addWord(pictogram.text);
  }

  void _openCategory(Pictogram pictogram) {
    final targetCategoryId = pictogram.targetCategoryId;

    if (targetCategoryId == null || targetCategoryId.isEmpty) {
      return;
    }

    setState(() {
      _categoryHistory.add(_currentCategoryId);
      _currentCategoryId = targetCategoryId;
    });
  }

  void _goHome() {
    setState(() {
      _currentCategoryId = PictogramRepository.homeCategoryId;
      _categoryHistory.clear();
    });
  }

  void _goBack() {
    if (_categoryHistory.isEmpty) {
      return;
    }

    setState(() {
      _currentCategoryId = _categoryHistory.removeLast();
    });
  }

  Future<void> _addWord(String word) async {
    setState(() {
      _selectedWords.add(word);
    });

    debugPrint('[BOARD] Palabra pulsada: $word');

    await _speechService.speak(word);
  }

  void _deleteLastWord() {
    if (_selectedWords.isEmpty) {
      return;
    }

    setState(() {
      _selectedWords.removeLast();
    });
  }

  void _clearAllWords() {
    if (_selectedWords.isEmpty) {
      return;
    }

    setState(() {
      _selectedWords.clear();
    });
  }

  Future<void> _speakPhrase() async {
    if (_selectedWords.isEmpty) {
      debugPrint('[BOARD] No hay frase para hablar');
      return;
    }

    final phrase = _selectedWords.join(' ');

    debugPrint('[BOARD] Hablando frase completa: $phrase');

    await _speechService.speak(phrase);
  }

  @override
  Widget build(BuildContext context) {
    final pictograms = _repository.getPictogramsByCategory(_currentCategoryId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PhraseBar(
              words: _selectedWords,
              onHome: _goHome,
              onBack: _goBack,
              onDeleteLast: _deleteLastWord,
              onClearAll: _clearAllWords,
              onSpeakPhrase: _speakPhrase,
              canGoBack: _categoryHistory.isNotEmpty,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _getCrossAxisCount(
                      constraints.maxWidth,
                    );

                    return GridView.builder(
                      itemCount: pictograms.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final pictogram = pictograms[index];

                        return PictogramCard(
                          pictogram: pictogram,
                          onTap: () => _handlePictogramTap(pictogram),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
