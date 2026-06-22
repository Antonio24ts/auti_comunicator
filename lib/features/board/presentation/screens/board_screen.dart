import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../widgets/phrase_bar.dart';
import '../widgets/bottom_action_bar.dart';
import '../../domain/phrase_item.dart';
import '../../../../services/ambient_music_services.dart';
import '../widgets/child_name_dialog.dart';
import '../../../calculator/domain/simple_calculator_engine.dart';
import '../../../calculator/presentation/widgets/calculator_panel.dart';
import '../../../timer/presentation/widgets/visual_timer_panel.dart';
import '../../../games/presentation/widgets/games_menu_panel.dart';
import '../../../games/presentation/widgets/listen_and_touch_game_panel.dart';

import '../widgets/zone_panel.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../widgets/settings_sheet.dart';

enum BoardZone { main, center, right }

enum _TimerFinishedAction { stop, repeat }

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final SpeechService _speechService = SpeechService();
  final PictogramRepository _repository = PictogramRepository();
  final AppSettingsService _settingsService = AppSettingsService();
  final AmbientMusicService _ambientMusicService = AmbientMusicService();

  bool _hasShownStartupNameDialog = false;

  late final Future<void> _loadInitialDataFuture;

  AppSettings _settings = AppSettings.defaults();

  final List<PhraseItem> _phraseItems = [];

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

  String _calculatorExpression = '';
  String _calculatorResult = '';
  String? _fullBoardCategoryId;
  final List<String> _fullBoardHistory = [];

  static const int _defaultTimerSeconds = 60;

  Timer? _visualTimer;
  int _selectedTimerSeconds = _defaultTimerSeconds;
  int _remainingTimerSeconds = _defaultTimerSeconds;
  bool _isTimerRunning = false;
  bool _isTimerPaused = false;

  BoardZone _lastActiveZone = BoardZone.main;

  @override
  void initState() {
    super.initState();

    _loadInitialDataFuture = _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showChildNameDialogOnStartup());
    });
  }

  void _selectTimerDuration(int seconds) {
    if (_isTimerRunning) {
      return;
    }

    setState(() {
      _selectedTimerSeconds = seconds;
      _remainingTimerSeconds = seconds;
      _isTimerPaused = false;
    });
  }

  void _openListenAndTouchGame() {
    setState(() {
      if (_fullBoardCategoryId != null) {
        _fullBoardHistory.add(_fullBoardCategoryId!);
      }

      _fullBoardCategoryId = 'juego_escucha_toca';
    });
  }

  void _addOneMinuteToTimer() {
    if (_isTimerRunning) {
      return;
    }

    const oneMinute = 60;
    const maxTimerSeconds = 60 * 60;

    setState(() {
      final newSelectedSeconds = _selectedTimerSeconds + oneMinute;

      _selectedTimerSeconds = newSelectedSeconds.clamp(
        oneMinute,
        maxTimerSeconds,
      );

      _remainingTimerSeconds = _selectedTimerSeconds;
      _isTimerPaused = false;
    });
  }

  void _startTimer() {
    if (_remainingTimerSeconds <= 0) {
      setState(() {
        _remainingTimerSeconds = _selectedTimerSeconds;
      });
    }

    _visualTimer?.cancel();

    unawaited(WakelockPlus.enable());

    setState(() {
      _isTimerRunning = true;
      _isTimerPaused = false;
    });

    _visualTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      if (_remainingTimerSeconds <= 1) {
        _finishTimer();
        return;
      }

      setState(() {
        _remainingTimerSeconds--;
      });
    });
  }

  void _pauseTimer() {
    _visualTimer?.cancel();

    unawaited(WakelockPlus.disable());

    setState(() {
      _isTimerRunning = false;
      _isTimerPaused = true;
    });
  }

  void _resetTimer() {
    _visualTimer?.cancel();

    unawaited(WakelockPlus.disable());

    setState(() {
      _remainingTimerSeconds = _selectedTimerSeconds;
      _isTimerRunning = false;
      _isTimerPaused = false;
    });
  }

  void _finishTimer() {
    _visualTimer?.cancel();

    unawaited(WakelockPlus.disable());

    setState(() {
      _remainingTimerSeconds = 0;
      _isTimerRunning = false;
      _isTimerPaused = false;
    });

    unawaited(_speechService.speakPhrase('Tiempo terminado'));

    unawaited(_showTimerFinishedDialog());
  }

  Future<void> _showTimerFinishedDialog() async {
    if (!mounted) {
      return;
    }

    final result = await showDialog<_TimerFinishedAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tiempo terminado'),
          content: const Text(
            'El temporizador ha terminado.',
            style: TextStyle(fontSize: 18, height: 1.25),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_TimerFinishedAction.stop);
              },
              icon: const Icon(Icons.stop),
              label: const Text('Parar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_TimerFinishedAction.repeat);
              },
              icon: const Icon(Icons.replay),
              label: const Text('Repetir tiempo'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == _TimerFinishedAction.repeat) {
      setState(() {
        _remainingTimerSeconds = _selectedTimerSeconds;
      });

      _startTimer();
      return;
    }

    _resetTimer();
  }

  void _handleCalculatorKey(String key) {
    String? resultToSpeak;

    setState(() {
      if (key == 'C') {
        _calculatorExpression = '';
        _calculatorResult = '';
        return;
      }

      if (key == '⌫') {
        if (_calculatorExpression.isNotEmpty) {
          _calculatorExpression = _calculatorExpression.substring(
            0,
            _calculatorExpression.length - 1,
          );
        }

        _calculatorResult = '';
        return;
      }

      if (key == '=') {
        _calculateResult();

        if (_calculatorResult.trim().isNotEmpty) {
          resultToSpeak = _calculatorResult;
        }

        return;
      }

      if (_isCalculatorDigit(key)) {
        _appendCalculatorDigit(key);
        return;
      }

      if (_isCalculatorOperator(key)) {
        _appendCalculatorOperator(key);
        return;
      }
    });

    if (resultToSpeak != null) {
      unawaited(
        _speechService.speakPhrase(
          resultToSpeak == 'Error' ||
                  resultToSpeak!.toLowerCase().contains('no se puede')
              ? resultToSpeak!
              : '$resultToSpeak',
        ),
      );
    }
  }

  void _appendCalculatorDigit(String digit) {
    if (_calculatorExpression.length >= 18) {
      return;
    }

    if (_calculatorResult.isNotEmpty) {
      _calculatorExpression = '';
      _calculatorResult = '';
    }

    _calculatorExpression += digit;
  }

  void _appendCalculatorOperator(String operator) {
    if (_calculatorExpression.isEmpty) {
      return;
    }

    if (_calculatorResult.isNotEmpty) {
      _calculatorExpression = _calculatorResult;
      _calculatorResult = '';
    }

    final lastCharacter =
        _calculatorExpression[_calculatorExpression.length - 1];

    if (_isCalculatorOperator(lastCharacter)) {
      _calculatorExpression = _calculatorExpression.substring(
        0,
        _calculatorExpression.length - 1,
      );

      _calculatorExpression += operator;
      return;
    }

    if (_calculatorExpression.length >= 18) {
      return;
    }

    _calculatorExpression += operator;
  }

  void _calculateResult() {
    if (_calculatorExpression.isEmpty) {
      return;
    }

    final lastCharacter =
        _calculatorExpression[_calculatorExpression.length - 1];

    if (_isCalculatorOperator(lastCharacter)) {
      _calculatorResult = 'Error';
      return;
    }

    try {
      _calculatorResult = SimpleCalculatorEngine.evaluate(
        _calculatorExpression,
      );
    } on FormatException catch (error) {
      _calculatorResult = error.message;
    } catch (_) {
      _calculatorResult = 'Error';
    }
  }

  bool _isCalculatorDigit(String value) {
    return RegExp(r'^[0-9]$').hasMatch(value);
  }

  bool _isCalculatorOperator(String value) {
    return value == '+' || value == '-' || value == '×' || value == '÷';
  }

  Future<void> _showChildNameDialogOnStartup() async {
    await _loadInitialDataFuture;

    if (!mounted || _hasShownStartupNameDialog) {
      return;
    }

    _hasShownStartupNameDialog = true;

    await _openChildNameDialog();
  }

  Future<void> _openChildNameDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChildNameDialog(
          initialName: _settings.childName,
          canCancel: false,
        );
      },
    );

    if (!mounted) {
      return;
    }

    final name = result?.trim();

    if (name == null || name.isEmpty) {
      return;
    }

    final newSettings = _settings.copyWith(childName: name);

    await _applySettings(newSettings);
  }

  @override
  void dispose() {
    _visualTimer?.cancel();
    unawaited(WakelockPlus.disable());
    unawaited(_speechService.stop());
    unawaited(_ambientMusicService.dispose());
    super.dispose();
  }

  double _getChildAspectRatio() {
    switch (_settings.cardSize) {
      case CardSize.small:
        return 1.50;
      case CardSize.medium:
        return 1.25;
      case CardSize.large:
        return 1.05;
    }
  }

  double _getFullBoardChildAspectRatio(String categoryId) {
    if (categoryId == 'alfabeto') {
      return 1.55;
    }

    switch (_settings.cardSize) {
      case CardSize.small:
        return 1.65;
      case CardSize.medium:
        return 1.45;
      case CardSize.large:
        return 1.25;
    }
  }

  Future<void> _loadInitialData() async {
    await _repository.load();

    final loadedSettings = await _settingsService.load();

    _settings = loadedSettings;

    await _ambientMusicService.init(_settings);

    await _speechService.init(
      speechRate: _settings.speechRate,
      onSpeechStart: () {
        unawaited(_ambientMusicService.pauseForSpeech());
      },
      onSpeechEnd: () {
        unawaited(_ambientMusicService.resumeAfterSpeech());
      },
    );
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
    await _ambientMusicService.applySettings(newSettings);
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

    _addPictogramToPhrase(pictogram);
  }

  void _addLetter(String letter) {
    final letterToAdd = letter.trim().toLowerCase();

    if (letterToAdd.isEmpty) {
      return;
    }

    setState(() {
      if (_phraseItems.isEmpty || !_phraseItems.last.isTypedText) {
        _phraseItems.add(PhraseItem(text: letterToAdd, isTypedText: true));
        return;
      }

      final lastIndex = _phraseItems.length - 1;
      final lastItem = _phraseItems[lastIndex];

      _phraseItems[lastIndex] = lastItem.copyWith(
        text: '${lastItem.text}$letterToAdd',
      );
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
    if (_phraseItems.isEmpty) {
      return;
    }

    setState(() {
      if (_phraseItems.last.isTypedText &&
          _phraseItems.last.text.trim().isNotEmpty) {
        _phraseItems.add(const PhraseItem(text: '', isTypedText: true));
      }
    });
  }

  void _deleteLastLetter() {
    if (_phraseItems.isEmpty) {
      return;
    }

    final lastIndex = _phraseItems.length - 1;
    final lastItem = _phraseItems[lastIndex];

    if (!lastItem.isTypedText) {
      return;
    }

    setState(() {
      final currentText = lastItem.text;

      if (currentText.isEmpty) {
        _phraseItems.removeAt(lastIndex);
        return;
      }

      final newText = currentText.substring(0, currentText.length - 1);

      if (newText.isEmpty) {
        _phraseItems.removeAt(lastIndex);
        return;
      }

      _phraseItems[lastIndex] = lastItem.copyWith(text: newText);
    });
  }

  String _getPhraseText() {
    return _phraseItems
        .map((item) => item.text.trim())
        .where((text) => text.isNotEmpty)
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

        if (targetCategoryId == 'calculadora') {
          _calculatorExpression = '';
          _calculatorResult = '';
        }

        if (targetCategoryId == 'temporizador') {
          _visualTimer?.cancel();
          _selectedTimerSeconds = _defaultTimerSeconds;
          _remainingTimerSeconds = _defaultTimerSeconds;
          _isTimerRunning = false;
          _isTimerPaused = false;
        }
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
    _visualTimer?.cancel();
    unawaited(WakelockPlus.disable());

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

      _isTimerRunning = false;
      _isTimerPaused = false;
      _remainingTimerSeconds = _selectedTimerSeconds;

      _lastActiveZone = BoardZone.main;
    });
  }

  void _goBack() {
    if (_fullBoardCategoryId != null) {
      final wasTimerOpen = _fullBoardCategoryId == 'temporizador';

      if (wasTimerOpen) {
        _visualTimer?.cancel();
        unawaited(WakelockPlus.disable());
      }

      setState(() {
        if (_fullBoardHistory.isNotEmpty) {
          _fullBoardCategoryId = _fullBoardHistory.removeLast();
        } else {
          _fullBoardCategoryId = null;
        }

        if (wasTimerOpen) {
          _isTimerRunning = false;
          _isTimerPaused = false;
          _remainingTimerSeconds = _selectedTimerSeconds;
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

  void _addPictogramToPhrase(Pictogram pictogram) {
    final cleanText = pictogram.text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    setState(() {
      _phraseItems.add(
        PhraseItem(text: cleanText, imagePath: pictogram.imagePath),
      );
    });

    if (_settings.speakOnCardTap) {
      unawaited(_speechService.speakWord(cleanText));
    }
  }

  void _deleteLastWord() {
    if (_phraseItems.isEmpty) {
      return;
    }

    setState(() {
      _phraseItems.removeLast();
    });
  }

  void _deletePhraseItemAt(int index) {
    if (index < 0 || index >= _phraseItems.length) {
      return;
    }

    setState(() {
      _phraseItems.removeAt(index);
    });
  }

  void _clearAllWords() {
    if (_phraseItems.isEmpty) {
      return;
    }

    setState(() {
      _phraseItems.clear();
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

    if (categoryId == 'calculadora') {
      return CalculatorPanel(
        expression: _calculatorExpression,
        result: _calculatorResult,
        onKeyPressed: _handleCalculatorKey,
      );
    }

    if (categoryId == 'temporizador') {
      return VisualTimerPanel(
        selectedSeconds: _selectedTimerSeconds,
        remainingSeconds: _remainingTimerSeconds,
        isRunning: _isTimerRunning,
        isPaused: _isTimerPaused,
        onDurationSelected: _selectTimerDuration,
        onStart: _startTimer,
        onPause: _pauseTimer,
        onReset: _resetTimer,
        onAddMinute: _addOneMinuteToTimer,
      );
    }

    if (categoryId == 'juegos') {
      return GamesMenuPanel(onOpenListenAndTouch: _openListenAndTouchGame);
    }

    if (categoryId == 'juego_escucha_toca') {
      return ListenAndTouchGamePanel(
        repository: _repository,
        speechService: _speechService,
        cardSize: _settings.cardSize,
      );
    }

    final pictograms = _repository.getPictogramsByCategory(categoryId);

    return ZonePanel(
      pictograms: pictograms,
      crossAxisCount: 8,
      childAspectRatio: _getFullBoardChildAspectRatio(categoryId),
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
                items: _phraseItems,
                onHome: _goHome,
                onBack: _goBack,
                onDeleteLast: _deleteLastWord,
                onClearAll: _clearAllWords,
                onSpeakPhrase: _speakPhrase,
                onDeleteItemAt: _deletePhraseItemAt,
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
              BottomActionBar(
                onSettingsLongPressCompleted: _openSettings,
                childName: _settings.childName,
              ),
            ],
          );
        },
      ),
    );
  }
}
