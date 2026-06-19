import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../widgets/phrase_bar.dart';
import '../widgets/pictogram_card.dart';
import '../widgets/bottom_action_bar.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../widgets/settings_sheet.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final SpeechService _speechService = SpeechService();
  final PictogramRepository _repository = PictogramRepository();
  final AppSettingsService _settingsService = AppSettingsService();

  late final Future<void> _loadInitialDataFuture;

  AppSettings _settings = AppSettings.defaults();

  final List<String> _selectedWords = [];
  final List<String> _categoryHistory = [];

  String _currentCategoryId = PictogramRepository.homeCategoryId;

  @override
  void initState() {
    super.initState();

    _loadInitialDataFuture = _loadInitialData();
  }

  int _getCrossAxisCount(double width) {
    return 8;
  }

  double _getChildAspectRatio() {
    switch (_settings.cardSize) {
      case CardSize.small:
        return 1.55;
      case CardSize.medium:
        return 1.25;
      case CardSize.large:
        return 1.05;
    }
  }

  Future<void> _loadInitialData() async {
    await _repository.load();

    final loadedSettings = await _settingsService.load();

    _settings = loadedSettings;

    await _speechService.init(speechRate: _settings.speechRate);
  }

  Future<void> _applySettings(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });

    await _settingsService.save(newSettings);

    await _speechService.setSpeechRate(newSettings.speechRate);
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SettingsSheet(
          settings: _settings,
          onSettingsChanged: (newSettings) {
            unawaited(_applySettings(newSettings));
          },
          onTestVoice: () {
            unawaited(_speechService.speakPhrase('Esto es una prueba de voz'));
          },
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
    final letterToAdd = letter.trim().toLowerCase();

    if (letterToAdd.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedWords.isEmpty) {
        _selectedWords.add(letterToAdd);
        return;
      }

      final lastIndex = _selectedWords.length - 1;
      _selectedWords[lastIndex] = '${_selectedWords[lastIndex]}$letterToAdd';
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

    if (_settings.speakOnCardTap) {
      unawaited(_speechService.speakWord(word));
    }
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
    return Scaffold(
      body: FutureBuilder<void>(
        future: _loadInitialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error cargando pictogramas:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.red),
                ),
              ),
            );
          }

          final pictograms = _repository.getPictogramsByCategory(
            _currentCategoryId,
          );

          return Column(
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
                          childAspectRatio: _getChildAspectRatio(),
                        ),
                        itemBuilder: (context, index) {
                          final pictogram = pictograms[index];

                          return PictogramCard(
                            pictogram: pictogram,
                            onTap: () => _handlePictogramTap(pictogram),
                            cardSize: _settings.cardSize,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              BottomActionBar(onSettingsTap: _openSettings),
            ],
          );
        },
      ),
    );
  }
}
