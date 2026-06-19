import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../widgets/phrase_bar.dart';
import '../widgets/bottom_action_bar.dart';

import '../widgets/zone_panel.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../widgets/settings_sheet.dart';

enum BoardZone { main, center, right }

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

  final Map<BoardZone, String> _currentCategoryByZone = {
    BoardZone.main: PictogramRepository.homeMainCategoryId,
    BoardZone.center: PictogramRepository.homeCenterCategoryId,
    BoardZone.right: PictogramRepository.homeRightCategoryId,
  };

  final Map<BoardZone, List<String>> _categoryHistoryByZone = {
    BoardZone.main: [],
    BoardZone.center: [],
    BoardZone.right: [],
  };

  String? _fullBoardCategoryId;
  final List<String> _fullBoardHistory = [];

  BoardZone _lastActiveZone = BoardZone.main;

  @override
  void initState() {
    super.initState();

    _loadInitialDataFuture = _loadInitialData();
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

  List<Pictogram> _getPictogramsForZone(BoardZone zone) {
    final categoryId = _currentCategoryByZone[zone];

    if (categoryId == null) {
      return [];
    }

    return _repository.getPictogramsByCategory(categoryId);
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

  void _handlePictogramTap(Pictogram pictogram, BoardZone zone) {
    if (pictogram.isCategory) {
      _openCategory(pictogram, zone);
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

  void _openCategory(Pictogram pictogram, BoardZone zone) {
    final targetCategoryId = pictogram.targetCategoryId;

    if (targetCategoryId == null || targetCategoryId.isEmpty) {
      return;
    }

    if (pictogram.categoryOpenMode == CategoryOpenMode.fullBoard) {
      setState(() {
        if (_fullBoardCategoryId != null) {
          _fullBoardHistory.add(_fullBoardCategoryId!);
        }

        _fullBoardCategoryId = targetCategoryId;
        _lastActiveZone = zone;
      });

      return;
    }

    final currentCategoryId = _currentCategoryByZone[zone];

    if (currentCategoryId == null) {
      return;
    }

    setState(() {
      _categoryHistoryByZone[zone]?.add(currentCategoryId);
      _currentCategoryByZone[zone] = targetCategoryId;
      _lastActiveZone = zone;
    });
  }

  void _goHome() {
    setState(() {
      _currentCategoryByZone[BoardZone.main] =
          PictogramRepository.homeMainCategoryId;
      _currentCategoryByZone[BoardZone.center] =
          PictogramRepository.homeCenterCategoryId;
      _currentCategoryByZone[BoardZone.right] =
          PictogramRepository.homeRightCategoryId;

      _categoryHistoryByZone[BoardZone.main]?.clear();
      _categoryHistoryByZone[BoardZone.center]?.clear();
      _categoryHistoryByZone[BoardZone.right]?.clear();

      _fullBoardCategoryId = null;
      _fullBoardHistory.clear();

      _lastActiveZone = BoardZone.main;
    });
  }

  void _goBack() {
    if (_fullBoardCategoryId != null) {
      setState(() {
        if (_fullBoardHistory.isNotEmpty) {
          _fullBoardCategoryId = _fullBoardHistory.removeLast();
        } else {
          _fullBoardCategoryId = null;
        }
      });

      return;
    }

    final zone = _getZoneToGoBack();

    if (zone == null) {
      return;
    }

    final history = _categoryHistoryByZone[zone];

    if (history == null || history.isEmpty) {
      return;
    }

    setState(() {
      _currentCategoryByZone[zone] = history.removeLast();
      _lastActiveZone = zone;
    });
  }

  BoardZone? _getZoneToGoBack() {
    final lastHistory = _categoryHistoryByZone[_lastActiveZone];

    if (lastHistory != null && lastHistory.isNotEmpty) {
      return _lastActiveZone;
    }

    for (final entry in _categoryHistoryByZone.entries) {
      if (entry.value.isNotEmpty) {
        return entry.key;
      }
    }

    return null;
  }

  bool _canGoBack() {
    if (_fullBoardCategoryId != null) {
      return true;
    }

    return _categoryHistoryByZone.values.any((history) => history.isNotEmpty);
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

  Widget _buildZoneLayout() {
    final aspectRatio = _getChildAspectRatio();

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ZonePanel(
            pictograms: _getPictogramsForZone(BoardZone.main),
            crossAxisCount: 5,
            childAspectRatio: aspectRatio,
            cardSize: _settings.cardSize,
            onPictogramTap: (pictogram) {
              _handlePictogramTap(pictogram, BoardZone.main);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: ZonePanel(
            pictograms: _getPictogramsForZone(BoardZone.center),
            crossAxisCount: 1,
            childAspectRatio: aspectRatio,
            cardSize: _settings.cardSize,
            onPictogramTap: (pictogram) {
              _handlePictogramTap(pictogram, BoardZone.center);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ZonePanel(
            pictograms: _getPictogramsForZone(BoardZone.right),
            crossAxisCount: 2,
            childAspectRatio: aspectRatio,
            cardSize: _settings.cardSize,
            onPictogramTap: (pictogram) {
              _handlePictogramTap(pictogram, BoardZone.right);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullBoardLayout() {
    final categoryId = _fullBoardCategoryId;

    if (categoryId == null) {
      return const SizedBox.shrink();
    }

    final pictograms = _repository.getPictogramsByCategory(categoryId);

    final isAlphabet = categoryId == 'alfabeto';

    return ZonePanel(
      pictograms: pictograms,
      crossAxisCount: 8,
      childAspectRatio: isAlphabet ? 1.45 : _getChildAspectRatio(),
      cardSize: _settings.cardSize,
      onPictogramTap: (pictogram) {
        _handlePictogramTap(pictogram, _lastActiveZone);
      },
    );
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

          return Column(
            children: [
              PhraseBar(
                words: _selectedWords,
                onHome: _goHome,
                onBack: _goBack,
                onDeleteLast: _deleteLastWord,
                onClearAll: _clearAllWords,
                onSpeakPhrase: _speakPhrase,
                canGoBack: _canGoBack(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: _fullBoardCategoryId == null
                      ? _buildZoneLayout()
                      : _buildFullBoardLayout(),
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
