import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../widgets/phrase_bar.dart';
import '../widgets/pictogram_card.dart';
import '../widgets/bottom_action_bar.dart';

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
    unawaited(_speechService.init());
  }

  int _getCrossAxisCount(double width) {
    return 8;
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajustes',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aquí añadiremos opciones de la app más adelante.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _handlePictogramTap(Pictogram pictogram) {
    if (pictogram.isCategory) {
      _openCategory(pictogram);
      return;
    }

    if (pictogram.isLetter) {
      _addLetter(pictogram.value ?? pictogram.text.toLowerCase());
      return;
    }

    if (pictogram.isKeyboardAction) {
      _handleKeyboardAction(pictogram);
      return;
    }

    _addWord(pictogram.text);
  }

  void _addLetter(String letter) {
    if (letter.trim().isEmpty) {
      return;
    }

    setState(() {
      if (_selectedWords.isEmpty) {
        _selectedWords.add(letter);
        return;
      }

      final lastIndex = _selectedWords.length - 1;
      _selectedWords[lastIndex] = '${_selectedWords[lastIndex]}$letter';
    });
  }

  void _handleKeyboardAction(Pictogram pictogram) {
    switch (pictogram.keyboardAction) {
      case KeyboardAction.space:
        _addSpace();
        break;
      case KeyboardAction.deleteLetter:
        _deleteLastLetter();
        break;
      case null:
        break;
    }
  }

  void _addSpace() {
    setState(() {
      if (_selectedWords.isEmpty) {
        return;
      }

      if (_selectedWords.last.trim().isEmpty) {
        return;
      }

      _selectedWords.add('');
    });
  }

  void _deleteLastLetter() {
    if (_selectedWords.isEmpty) {
      return;
    }

    setState(() {
      final lastIndex = _selectedWords.length - 1;
      final lastWord = _selectedWords[lastIndex];

      if (lastWord.isEmpty) {
        _selectedWords.removeLast();
        return;
      }

      if (lastWord.length == 1) {
        _selectedWords.removeLast();
        return;
      }

      _selectedWords[lastIndex] = lastWord.substring(0, lastWord.length - 1);
    });
  }

  String _getPhraseText() {
    return _selectedWords
        .where((word) => word.trim().isNotEmpty)
        .join(' ')
        .trim();
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

  void _addWord(String word) {
    setState(() {
      _selectedWords.add(word);
    });

    _speechService.speakWord(word);
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
    final phrase = _getPhraseText();

    if (phrase.isEmpty) {
      return;
    }

    await _speechService.speakPhrase(phrase);
  }

  @override
  Widget build(BuildContext context) {
    final pictograms = _repository.getPictogramsByCategory(_currentCategoryId);

    return Scaffold(
      body: Column(
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
                      childAspectRatio: 1.45,
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
          BottomActionBar(onSettingsTap: _openSettings),
        ],
      ),
    );
  }
}
