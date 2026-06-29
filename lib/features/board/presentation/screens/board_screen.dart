import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../widgets/pictogram_card.dart';
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
import '../../../games/presentation/widgets/memory_match_game_panel.dart';
import '../../../games/domain/game_progress.dart';
import '../../../games/domain/game_progress_services.dart';
import '../../../../services/sound_effects_service.dart';
import '../../../games/presentation/widgets/sentence_builder_game_panel.dart';
import '../../../games/presentation/widgets/animal_sound_game_panel.dart';
import '../../../favorites/data/favorite_pictograms_service.dart';
import '../../../favorites/presentation/widgets/favorites_panel.dart';
import '../../../recent_phrases/data/recent_phrases_service.dart';
import '../../../recent_phrases/domain/recent_phrase.dart';
import '../../../recent_phrases/presentation/widgets/recent_phrases_panel.dart';
import '../../../visual_agenda/presentation/widgets/visual_agenda_panel.dart';
import '../../../games/presentation/widgets/syllable_word_game_panel.dart';
import '../../../calm/presentation/widgets/calm_panel.dart';

import '../widgets/zone_panel.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../widgets/settings_sheet.dart';

enum BoardZone { main, center, right }

class _MobilePictogramEntry {
  final Pictogram pictogram;
  final BoardZone zone;

  const _MobilePictogramEntry({required this.pictogram, required this.zone});
}

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

  final GameProgressService _gameProgressService = GameProgressService();
  final SoundEffectsService _soundEffectsService = SoundEffectsService();

  final FavoritePictogramsService _favoritePictogramsService =
      FavoritePictogramsService();

  List<String> _favoritePictogramIds = [];

  final RecentPhrasesService _recentPhrasesService = RecentPhrasesService();

  List<RecentPhrase> _recentPhrases = [];
  String? _editingRecentPhraseId;

  GameProgress _listenAndTouchProgress = GameProgress.empty(
    GameIds.listenAndTouch,
  );

  GameProgress _memoryMatchProgress = GameProgress.empty(GameIds.memoryMatch);

  GameProgress _sentenceBuilderProgress = GameProgress.empty(
    GameIds.sentenceBuilder,
  );

  GameProgress _animalSoundsProgress = GameProgress.empty(GameIds.animalSounds);

  GameProgress _syllableWordsProgress = GameProgress.empty(
    GameIds.syllableWords,
  );

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

    unawaited(_soundEffectsService.init());

    _loadInitialDataFuture = _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showChildNameDialogOnStartup());
    });
  }

  @override
  void dispose() {
    unawaited(_soundEffectsService.dispose());
    _visualTimer?.cancel();
    unawaited(WakelockPlus.disable());
    unawaited(_speechService.stop());
    unawaited(_ambientMusicService.dispose());
    super.dispose();
  }

  void _addCalmPhraseToPhraseBar({
    required String text,
    required String imagePath,
  }) {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    setState(() {
      _phraseItems.add(PhraseItem(text: cleanText, imagePath: imagePath));
    });
  }

  Future<void> _loadInitialData() async {
    await _repository.load();

    final loadedSettings = await _settingsService.load();

    _settings = loadedSettings;

    await _reloadFavoritesForCurrentChild();
    await _reloadRecentPhrasesForCurrentChild();

    _listenAndTouchProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.listenAndTouch,
    );

    _memoryMatchProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.memoryMatch,
    );

    _sentenceBuilderProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.sentenceBuilder,
    );

    _animalSoundsProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.animalSounds,
    );

    _syllableWordsProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.syllableWords,
    );

    await _ambientMusicService.init(_settings);

    await _speechService.init(
      speechRate: _settings.speechRate,
      onSpeechStart: () {
        unawaited(_ambientMusicService.pauseForSpeech());
      },
      onSpeechEnd: () {
        unawaited(_ambientMusicService.resumeAfterSpeech(_settings));
      },
    );
  }

  Future<void> _reloadFavoritesForCurrentChild() async {
    final favoriteIds = await _favoritePictogramsService.loadFavoriteIds(
      childName: _settings.childName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _favoritePictogramIds = favoriteIds;
    });
  }

  List<Pictogram> _getFavoritePictograms() {
    return _favoritePictogramIds
        .map((id) => _repository.getPictogramById(id))
        .whereType<Pictogram>()
        .toList();
  }

  Future<void> _addFavoritePictogram(Pictogram pictogram) async {
    if (!pictogram.isWord && !pictogram.isLetter) {
      _showFavoriteMessage('Solo puedes añadir pictogramas a favoritos.');
      return;
    }

    final favoriteIds = await _favoritePictogramsService.loadFavoriteIds(
      childName: _settings.childName,
    );

    if (favoriteIds.contains(pictogram.id)) {
      _showFavoriteMessage('${pictogram.text} ya está en Favoritos');
      return;
    }

    await _favoritePictogramsService.addFavorite(
      childName: _settings.childName,
      pictogramId: pictogram.id,
    );

    await _reloadFavoritesForCurrentChild();

    if (!mounted) {
      return;
    }

    final childName = _settings.childName.trim();

    _showFavoriteMessage(
      childName.isEmpty
          ? '${pictogram.text} añadido a Favoritos'
          : '${pictogram.text} añadido a Favoritos de $childName',
    );
  }

  Future<void> _removeFavoritePictogram(Pictogram pictogram) async {
    await _favoritePictogramsService.removeFavorite(
      childName: _settings.childName,
      pictogramId: pictogram.id,
    );

    await _reloadFavoritesForCurrentChild();

    if (!mounted) {
      return;
    }

    _showFavoriteMessage('${pictogram.text} eliminado de Favoritos');
  }

  void _handleFavoritePictogramTap(Pictogram pictogram) {
    _handlePictogramTap(pictogram, _lastActiveZone);
  }

  void _showFavoriteMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1300),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openSyllableWordsGame() {
    setState(() {
      if (_fullBoardCategoryId != null) {
        _fullBoardHistory.add(_fullBoardCategoryId!);
      }

      _fullBoardCategoryId = 'juego_ordenar_silabas';
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

  void _openMemoryMatchGame() {
    setState(() {
      if (_fullBoardCategoryId != null) {
        _fullBoardHistory.add(_fullBoardCategoryId!);
      }

      _fullBoardCategoryId = 'juego_emparejar';
    });
  }

  void _openSentenceBuilderGame() {
    setState(() {
      if (_fullBoardCategoryId != null) {
        _fullBoardHistory.add(_fullBoardCategoryId!);
      }

      _fullBoardCategoryId = 'juego_construye_frase';
    });
  }

  void _openAnimalSoundsGame() {
    setState(() {
      if (_fullBoardCategoryId != null) {
        _fullBoardHistory.add(_fullBoardCategoryId!);
      }

      _fullBoardCategoryId = 'juego_sonidos_animales';
    });
  }

  void _backToGamesMenu() {
    setState(() {
      _fullBoardCategoryId = 'juegos';

      _fullBoardHistory.removeWhere(
        (categoryId) =>
            categoryId == 'juego_emparejar' ||
            categoryId == 'juego_escucha_toca' ||
            categoryId == 'juego_construye_frase' ||
            categoryId == 'juego_sonidos_animales' ||
            categoryId == 'juego_ordenar_silabas',
      );
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

  List<Pictogram> _getPictogramsForZone(BoardZone zone) {
    final categoryId = _currentCategoryByZone[zone];

    if (categoryId == null) {
      return [];
    }

    return _repository.getPictogramsByCategory(categoryId);
  }

  Future<void> _applySettings(AppSettings newSettings) async {
    final oldChildName = _settings.childName.trim();
    final newChildName = newSettings.childName.trim();
    final hasChangedChildName = oldChildName != newChildName;

    setState(() {
      _settings = newSettings;
    });

    await _settingsService.save(newSettings);

    await _speechService.setSpeechRate(newSettings.speechRate);
    await _ambientMusicService.applySettings(newSettings);

    if (hasChangedChildName) {
      await _reloadGameProgressForCurrentChild();
      await _reloadFavoritesForCurrentChild();
      await _reloadRecentPhrasesForCurrentChild();

      _editingRecentPhraseId = null;
    }
  }

  Future<void> _reloadRecentPhrasesForCurrentChild() async {
    final recentPhrases = await _recentPhrasesService.loadRecentPhrases(
      childName: _settings.childName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _recentPhrases = recentPhrases;
    });
  }

  Future<void> _saveCurrentPhraseAsRecent() async {
    if (_phraseItems.isEmpty) {
      return;
    }

    await _recentPhrasesService.addRecentPhrase(
      childName: _settings.childName,
      items: _phraseItems,
    );

    await _reloadRecentPhrasesForCurrentChild();
  }

  Future<void> _speakRecentPhrase(RecentPhrase recentPhrase) async {
    final phraseText = recentPhrase.text.trim();

    if (phraseText.isEmpty) {
      return;
    }

    await _speechService.speakPhrase(phraseText);
  }

  void _loadRecentPhraseForEditing(RecentPhrase recentPhrase) {
    setState(() {
      _phraseItems
        ..clear()
        ..addAll(
          recentPhrase.items.map(
            (item) => PhraseItem(
              text: item.text,
              imagePath: item.imagePath,
              isTypedText: item.isTypedText,
            ),
          ),
        );

      _editingRecentPhraseId = recentPhrase.id;
    });

    _showRecentPhraseMessage('Frase cargada arriba para editar');
  }

  Future<void> _removeEditingRecentPhraseAfterClear() async {
    final recentPhraseId = _editingRecentPhraseId;

    if (recentPhraseId == null) {
      return;
    }

    _editingRecentPhraseId = null;

    await _recentPhrasesService.removeRecentPhrase(
      childName: _settings.childName,
      recentPhraseId: recentPhraseId,
    );

    await _reloadRecentPhrasesForCurrentChild();

    if (!mounted) {
      return;
    }

    _showRecentPhraseMessage('Frase eliminada de recientes');
  }

  void _showRecentPhraseMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1300),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _reloadGameProgressForCurrentChild() async {
    final listenProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.listenAndTouch,
    );

    final memoryProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.memoryMatch,
    );

    final sentenceBuilderProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.sentenceBuilder,
    );

    final animalSoundsProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.animalSounds,
    );

    final syllableWordsProgress = await _gameProgressService.load(
      childName: _settings.childName,
      gameId: GameIds.syllableWords,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _listenAndTouchProgress = listenProgress;
      _memoryMatchProgress = memoryProgress;
      _sentenceBuilderProgress = sentenceBuilderProgress;
      _animalSoundsProgress = animalSoundsProgress;
      _syllableWordsProgress = syllableWordsProgress;
    });
  }

  Future<void> _recordGameProgress(GameProgressUpdate update) async {
    final newProgress = await _gameProgressService.record(
      childName: _settings.childName,
      update: update,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      if (update.gameId == GameIds.listenAndTouch) {
        _listenAndTouchProgress = newProgress;
        return;
      }

      if (update.gameId == GameIds.memoryMatch) {
        _memoryMatchProgress = newProgress;
        return;
      }

      if (update.gameId == GameIds.sentenceBuilder) {
        _sentenceBuilderProgress = newProgress;
        return;
      }

      if (update.gameId == GameIds.animalSounds) {
        _animalSoundsProgress = newProgress;
        return;
      }

      if (update.gameId == GameIds.syllableWords) {
        _syllableWordsProgress = newProgress;
        return;
      }
    });
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

    _editingRecentPhraseId = null;

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

    final targetZone = _getTargetZoneForCategory(
      targetCategoryId: targetCategoryId,
      currentZone: zone,
    );

    final currentCategoryId = _currentCategoryByZone[targetZone];

    if (currentCategoryId == null) {
      return;
    }

    if (currentCategoryId == targetCategoryId) {
      setState(() {
        _lastActiveZone = targetZone;
      });

      return;
    }

    setState(() {
      _categoryHistoryByZone[targetZone]?.add(currentCategoryId);
      _currentCategoryByZone[targetZone] = targetCategoryId;
      _lastActiveZone = targetZone;
    });
  }

  BoardZone _getTargetZoneForCategory({
    required String targetCategoryId,
    required BoardZone currentZone,
  }) {
    if (targetCategoryId == 'conectores') {
      return BoardZone.main;
    }

    return currentZone;
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

    _editingRecentPhraseId = null;

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

    final shouldRemoveEditingRecentPhrase = _editingRecentPhraseId != null;

    setState(() {
      _phraseItems.clear();
    });

    if (shouldRemoveEditingRecentPhrase) {
      unawaited(_removeEditingRecentPhraseAfterClear());
    }
  }

  Future<void> _speakPhrase() async {
    final phrase = _getPhraseText();

    if (phrase.isEmpty) {
      return;
    }

    await _saveCurrentPhraseAsRecent();

    _editingRecentPhraseId = null;

    await _speechService.speakPhrase(phrase);
  }

  bool _isMobilePortrait(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return mediaQuery.orientation == Orientation.portrait &&
        size.shortestSide < 600;
  }

  CardSize _getResponsiveCardSize() {
    if (_isMobilePortrait(context)) {
      return CardSize.small;
    }

    return _settings.cardSize;
  }

  Widget _buildZoneLayout() {
    if (_isMobilePortrait(context)) {
      return _buildMobileZoneLayout();
    }

    return _buildTabletZoneLayout();
  }

  Widget _buildTabletZoneLayout() {
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
            onPictogramLongPress: _addFavoritePictogram,
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
            onPictogramLongPress: _addFavoritePictogram,
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
            onPictogramLongPress: _addFavoritePictogram,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileZoneLayout() {
    final entries = _getMobileHomeEntries();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];

        return PictogramCard(
          pictogram: entry.pictogram,
          cardSize: _getResponsiveCardSize(),
          onTap: () {
            _handlePictogramTap(entry.pictogram, entry.zone);
          },
          onLongPress: () {
            unawaited(_addFavoritePictogram(entry.pictogram));
          },
        );
      },
    );
  }

  List<_MobilePictogramEntry> _getMobileHomeEntries() {
    final mainPictograms = _getPictogramsForZone(BoardZone.main);
    final centerPictograms = _getPictogramsForZone(BoardZone.center);
    final rightPictograms = _getPictogramsForZone(BoardZone.right);

    return [
      for (final pictogram in mainPictograms)
        _MobilePictogramEntry(pictogram: pictogram, zone: BoardZone.main),
      for (final pictogram in centerPictograms)
        _MobilePictogramEntry(pictogram: pictogram, zone: BoardZone.center),
      for (final pictogram in rightPictograms)
        _MobilePictogramEntry(pictogram: pictogram, zone: BoardZone.right),
    ];
  }

  Widget _buildFullBoardLayout() {
    final categoryId = _fullBoardCategoryId;

    if (categoryId == null) {
      return const SizedBox.shrink();
    }

    if (categoryId == 'calma') {
      return CalmPanel(
        speechService: _speechService,
        onAddToPhrase: _addCalmPhraseToPhraseBar,
      );
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
      return GamesMenuPanel(
        onOpenListenAndTouch: _openListenAndTouchGame,
        onOpenMemoryMatch: _openMemoryMatchGame,
        onOpenSentenceBuilder: _openSentenceBuilderGame,
        onOpenAnimalSounds: _openAnimalSoundsGame,
        listenAndTouchProgress: _listenAndTouchProgress,
        memoryMatchProgress: _memoryMatchProgress,
        sentenceBuilderProgress: _sentenceBuilderProgress,
        animalSoundsProgress: _animalSoundsProgress,
        onOpenSyllableWords: _openSyllableWordsGame,
        syllableWordsProgress: _syllableWordsProgress,
      );
    }

    if (categoryId == 'juego_escucha_toca') {
      return ListenAndTouchGamePanel(
        repository: _repository,
        speechService: _speechService,
        soundEffectsService: _soundEffectsService,
        cardSize: _getResponsiveCardSize(),
        onProgressChanged: _recordGameProgress,
      );
    }

    if (categoryId == 'juego_emparejar') {
      return MemoryMatchGamePanel(
        repository: _repository,
        speechService: _speechService,
        soundEffectsService: _soundEffectsService,
        cardSize: _getResponsiveCardSize(),
        onBackToGames: _backToGamesMenu,
        onProgressChanged: _recordGameProgress,
      );
    }

    if (categoryId == 'juego_construye_frase') {
      return SentenceBuilderGamePanel(
        repository: _repository,
        speechService: _speechService,
        soundEffectsService: _soundEffectsService,
        onBackToGames: _backToGamesMenu,
        onProgressChanged: _recordGameProgress,
      );
    }

    if (categoryId == 'juego_sonidos_animales') {
      return AnimalSoundGamePanel(
        repository: _repository,
        speechService: _speechService,
        soundEffectsService: _soundEffectsService,
        onBackToGames: _backToGamesMenu,
        onProgressChanged: _recordGameProgress,
      );
    }

    if (categoryId == 'juego_ordenar_silabas') {
      return SyllableWordGamePanel(
        repository: _repository,
        speechService: _speechService,
        soundEffectsService: _soundEffectsService,
        onBackToGames: _backToGamesMenu,
        onProgressChanged: _recordGameProgress,
      );
    }

    if (categoryId == 'favoritos') {
      return FavoritesPanel(
        childName: _settings.childName,
        favorites: _getFavoritePictograms(),
        onPictogramTap: _handleFavoritePictogramTap,
        onRemoveFavorite: _removeFavoritePictogram,
      );
    }

    if (categoryId == 'frases_recientes') {
      return RecentPhrasesPanel(
        childName: _settings.childName,
        recentPhrases: _recentPhrases,
        onSpeakRecentPhrase: (recentPhrase) {
          unawaited(_speakRecentPhrase(recentPhrase));
        },
        onLoadRecentPhrase: _loadRecentPhraseForEditing,
      );
    }

    if (categoryId == 'agenda_visual') {
      return VisualAgendaPanel(
        childName: _settings.childName,
        repository: _repository,
        speechService: _speechService,
      );
    }

    final pictograms = _repository.getPictogramsByCategory(categoryId);

    return ZonePanel(
      pictograms: pictograms,
      crossAxisCount: _getFullBoardCrossAxisCount(categoryId),
      childAspectRatio: _getResponsiveFullBoardChildAspectRatio(categoryId),
      cardSize: _getResponsiveCardSize(),
      onPictogramTap: (pictogram) {
        _handlePictogramTap(pictogram, _lastActiveZone);
      },
      onPictogramLongPress: _addFavoritePictogram,
    );
  }

  int _getFullBoardCrossAxisCount(String categoryId) {
    if (!_isMobilePortrait(context)) {
      return 8;
    }

    if (categoryId == 'alfabeto') {
      return 4;
    }

    return 2;
  }

  double _getResponsiveFullBoardChildAspectRatio(String categoryId) {
    if (!_isMobilePortrait(context)) {
      return _getFullBoardChildAspectRatio(categoryId);
    }

    if (categoryId == 'alfabeto') {
      return 1.05;
    }

    return 0.95;
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
                  padding: EdgeInsets.all(_isMobilePortrait(context) ? 6 : 8),
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
