import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/sound_effects_service.dart';
import '../../../../services/speech_services.dart';
import '../../domain/game_progress.dart';
import '../../domain/syllable_word_challenge.dart';
import '../../domain/syllable_word_challenges.dart';

class SyllableWordGamePanel extends StatefulWidget {
  final PictogramRepository repository;
  final SpeechService speechService;
  final SoundEffectsService soundEffectsService;
  final GameProgressChanged onProgressChanged;
  final VoidCallback onBackToGames;

  const SyllableWordGamePanel({
    super.key,
    required this.repository,
    required this.speechService,
    required this.soundEffectsService,
    required this.onProgressChanged,
    required this.onBackToGames,
  });

  @override
  State<SyllableWordGamePanel> createState() => _SyllableWordGamePanelState();
}

class _SyllableWordGamePanelState extends State<SyllableWordGamePanel> {
  static const Duration _wrongFlashDuration = Duration(milliseconds: 420);
  static const Duration _nextRoundDelay = Duration(milliseconds: 850);

  late final Random _random = Random(DateTime.now().microsecondsSinceEpoch);

  int _level = 1;
  int _completedWordsInLevel = 0;
  int _streak = 0;

  bool _isChangingRound = false;

  String? _wrongOptionId;
  String? _correctOptionId;

  SyllableWordChallenge? _currentChallenge;
  Pictogram? _currentPictogram;

  List<SyllableWordChallenge> _levelChallenges = [];
  List<_SyllableOption> _options = [];
  List<_SyllableOption> _selectedOptions = [];

  final Set<String> _usedChallengeIdsInCurrentLevel = {};

  @override
  void initState() {
    super.initState();
    _startLevel(level: 1, speakWord: true);
  }

  void _startLevel({required int level, required bool speakWord}) {
    final cleanLevel = level.clamp(1, SyllableWordChallenges.maxLevel).toInt();

    final validChallenges = _getValidChallengesForLevel(cleanLevel)
      ..shuffle(_random);

    if (validChallenges.isEmpty) {
      final fallbackChallenges = _getAllValidChallenges()..shuffle(_random);

      if (fallbackChallenges.isEmpty) {
        setState(() {
          _level = cleanLevel;
          _levelChallenges = [];
          _currentChallenge = null;
          _currentPictogram = null;
          _options = [];
          _selectedOptions = [];
        });

        return;
      }

      setState(() {
        _level = cleanLevel;
        _levelChallenges = fallbackChallenges;
        _usedChallengeIdsInCurrentLevel.clear();
        _completedWordsInLevel = 0;
      });

      _startNextRound(speakWord: speakWord);
      return;
    }

    setState(() {
      _level = cleanLevel;
      _levelChallenges = validChallenges;
      _usedChallengeIdsInCurrentLevel.clear();
      _completedWordsInLevel = 0;
    });

    _startNextRound(speakWord: speakWord);
  }

  List<SyllableWordChallenge> _getValidChallengesForLevel(int level) {
    return SyllableWordChallenges.getByLevel(level).where((challenge) {
      return widget.repository.getPictogramById(challenge.pictogramId) != null;
    }).toList();
  }

  List<SyllableWordChallenge> _getAllValidChallenges() {
    return SyllableWordChallenges.all.where((challenge) {
      return widget.repository.getPictogramById(challenge.pictogramId) != null;
    }).toList();
  }

  void _startNextRound({required bool speakWord}) {
    if (_levelChallenges.isEmpty) {
      return;
    }

    final availableChallenges =
        _levelChallenges
            .where(
              (challenge) =>
                  !_usedChallengeIdsInCurrentLevel.contains(challenge.id),
            )
            .toList()
          ..shuffle(_random);

    final candidates = availableChallenges.isEmpty
        ? (List<SyllableWordChallenge>.from(_levelChallenges)..shuffle(_random))
        : availableChallenges;

    final challenge = candidates.first;
    final pictogram = widget.repository.getPictogramById(challenge.pictogramId);

    if (pictogram == null) {
      return;
    }

    _usedChallengeIdsInCurrentLevel.add(challenge.id);

    final options = _buildOptions(challenge);

    setState(() {
      _currentChallenge = challenge;
      _currentPictogram = pictogram;
      _options = options;
      _selectedOptions = [];
      _wrongOptionId = null;
      _correctOptionId = null;
      _isChangingRound = false;
    });

    if (speakWord) {
      unawaited(_speakCurrentWordWithDelay());
    }
  }

  List<_SyllableOption> _buildOptions(SyllableWordChallenge challenge) {
    final targetOptions = <_SyllableOption>[
      for (int index = 0; index < challenge.targetSyllables.length; index++)
        _SyllableOption(
          id: '${challenge.id}_target_$index',
          text: challenge.targetSyllables[index],
          isDistractor: false,
        ),
    ];

    final distractorOptions = <_SyllableOption>[
      for (int index = 0; index < challenge.distractorSyllables.length; index++)
        _SyllableOption(
          id: '${challenge.id}_distractor_$index',
          text: challenge.distractorSyllables[index],
          isDistractor: true,
        ),
    ];

    return [...targetOptions, ...distractorOptions]..shuffle(_random);
  }

  Future<void> _speakCurrentWordWithDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) {
      return;
    }

    await _speakCurrentWord();
  }

  Future<void> _speakCurrentWord() async {
    final challenge = _currentChallenge;

    if (challenge == null) {
      return;
    }

    await widget.speechService.speakPhrase(challenge.word);
  }

  Future<void> _speakSyllable(String syllable) async {
    final cleanSyllable = syllable.trim().toLowerCase();

    if (cleanSyllable.isEmpty) {
      return;
    }

    await widget.speechService.speakPhrase(cleanSyllable);
  }

  Future<void> _handleSyllableTap(_SyllableOption option) async {
    if (_isChangingRound) {
      return;
    }

    if (_selectedOptions.any((selected) => selected.id == option.id)) {
      return;
    }

    final challenge = _currentChallenge;

    if (challenge == null) {
      return;
    }

    final expectedIndex = _selectedOptions.length;

    if (expectedIndex >= challenge.targetSyllables.length) {
      return;
    }

    final expectedSyllable = challenge.targetSyllables[expectedIndex];

    if (option.isDistractor || option.text != expectedSyllable) {
      _handleWrongSyllable(option);
      return;
    }

    await _handleCorrectSyllable(option, challenge);
  }

  void _handleWrongSyllable(_SyllableOption option) {
    widget.soundEffectsService.playError();

    setState(() {
      _wrongOptionId = option.id;
      _streak = 0;
    });

    unawaited(
      Future<void>.delayed(_wrongFlashDuration, () {
        if (!mounted) {
          return;
        }

        if (_wrongOptionId == option.id) {
          setState(() {
            _wrongOptionId = null;
          });
        }
      }),
    );
  }

  Future<void> _handleCorrectSyllable(
    _SyllableOption option,
    SyllableWordChallenge challenge,
  ) async {
    setState(() {
      _selectedOptions.add(option);
      _correctOptionId = option.id;
    });

    await _speakSyllable(option.text);

    if (!mounted) {
      return;
    }

    setState(() {
      if (_correctOptionId == option.id) {
        _correctOptionId = null;
      }
    });

    final isWordCompleted =
        _selectedOptions.length == challenge.targetSyllables.length;

    if (!isWordCompleted) {
      return;
    }

    await _handleCompletedWord(challenge);
  }

  Future<void> _speakCompletedWord(SyllableWordChallenge challenge) async {
    await widget.speechService.speakPhrase(challenge.word);

    await Future<void>.delayed(_getCompletedWordSpeechDelay(challenge.word));
  }

  Duration _getCompletedWordSpeechDelay(String word) {
    final cleanWord = word.trim();

    if (cleanWord.length <= 5) {
      return const Duration(milliseconds: 1100);
    }

    if (cleanWord.length <= 8) {
      return const Duration(milliseconds: 1400);
    }

    return const Duration(milliseconds: 1700);
  }

  Future<void> _handleCompletedWord(SyllableWordChallenge challenge) async {
    setState(() {
      _isChangingRound = true;
      _streak++;
    });

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) {
      return;
    }

    await _speakCompletedWord(challenge);

    final nextCompletedWordsInLevel = _completedWordsInLevel + 1;

    final shouldLevelUp =
        nextCompletedWordsInLevel >=
        SyllableWordChallenges.completedWordsToLevelUp;

    final nextLevel = shouldLevelUp
        ? (_level + 1).clamp(1, SyllableWordChallenges.maxLevel).toInt()
        : _level;

    await widget.onProgressChanged(
      GameProgressUpdate(
        gameId: GameIds.syllableWords,
        level: nextLevel,
        streak: _streak,
        correctAnswersToAdd: 1,
      ),
    );

    if (!mounted) {
      return;
    }

    if (shouldLevelUp && _level < SyllableWordChallenges.maxLevel) {
      setState(() {
        _completedWordsInLevel = 0;
      });

      await widget.speechService.speakPhrase('Subes de nivel');
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      if (!mounted) {
        return;
      }

      _startLevel(level: nextLevel, speakWord: true);

      return;
    }

    setState(() {
      _completedWordsInLevel = nextCompletedWordsInLevel;
    });

    await Future<void>.delayed(_nextRoundDelay);

    if (!mounted) {
      return;
    }

    _startNextRound(speakWord: true);
  }

  void _resetCurrentWord() {
    if (_selectedOptions.isEmpty) {
      return;
    }

    setState(() {
      _selectedOptions = [];
      _wrongOptionId = null;
      _correctOptionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _currentChallenge;
    final pictogram = _currentPictogram;

    if (challenge == null || pictogram == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            'No hay palabras disponibles para este juego.\nRevisa los pictogramas configurados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade700,
            ),
          ),
        ),
      );
    }

    final progressText =
        'Nivel $_level · $_completedWordsInLevel/'
        '${SyllableWordChallenges.completedWordsToLevelUp} para subir';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _Header(
            progressText: progressText,
            onRepeatWord: () {
              unawaited(_speakCurrentWord());
            },
            onResetWord: _resetCurrentWord,
            onBackToGames: widget.onBackToGames,
          ),
          const SizedBox(height: 14),
          _WordPromptCard(challenge: challenge, pictogram: pictogram),
          const SizedBox(height: 14),
          _SelectedSyllablesRow(
            challenge: challenge,
            selectedOptions: _selectedOptions,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _SyllableOptionsGrid(
              options: _options,
              selectedOptions: _selectedOptions,
              wrongOptionId: _wrongOptionId,
              correctOptionId: _correctOptionId,
              onTap: _handleSyllableTap,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toca las sílabas en orden para formar la palabra.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyllableOption {
  final String id;
  final String text;
  final bool isDistractor;

  const _SyllableOption({
    required this.id,
    required this.text,
    required this.isDistractor,
  });
}

class _Header extends StatelessWidget {
  final String progressText;
  final VoidCallback onRepeatWord;
  final VoidCallback onResetWord;
  final VoidCallback onBackToGames;

  const _Header({
    required this.progressText,
    required this.onRepeatWord,
    required this.onResetWord,
    required this.onBackToGames,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.spellcheck_rounded, size: 34, color: Colors.purple.shade800),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordena la palabra',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progressText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRepeatWord,
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Repetir palabra'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onResetWord,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Borrar'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onBackToGames,
          icon: const Icon(Icons.apps_rounded),
          label: const Text('Juegos'),
        ),
      ],
    );
  }
}

class _WordPromptCard extends StatelessWidget {
  final SyllableWordChallenge challenge;
  final Pictogram pictogram;

  const _WordPromptCard({required this.challenge, required this.pictogram});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.shade200, width: 2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Image.asset(
              pictogram.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.blueGrey.shade400,
                  size: 48,
                );
              },
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.word.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 46,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${challenge.targetSyllables.length} sílabas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedSyllablesRow extends StatelessWidget {
  final SyllableWordChallenge challenge;
  final List<_SyllableOption> selectedOptions;

  const _SelectedSyllablesRow({
    required this.challenge,
    required this.selectedOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < challenge.targetSyllables.length; index++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _SelectedSyllableSlot(
                text: index < selectedOptions.length
                    ? selectedOptions[index].text
                    : '',
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectedSyllableSlot extends StatelessWidget {
  final String text;

  const _SelectedSyllableSlot({required this.text});

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasText ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasText ? Colors.green.shade500 : Colors.purple.shade200,
          width: hasText ? 3 : 2,
        ),
      ),
      child: Text(
        hasText ? text : '—',
        style: TextStyle(
          fontSize: hasText ? 30 : 24,
          fontWeight: FontWeight.w900,
          color: hasText ? Colors.green.shade800 : Colors.blueGrey.shade300,
        ),
      ),
    );
  }
}

class _SyllableOptionsGrid extends StatelessWidget {
  final List<_SyllableOption> options;
  final List<_SyllableOption> selectedOptions;
  final String? wrongOptionId;
  final String? correctOptionId;
  final ValueChanged<_SyllableOption> onTap;

  const _SyllableOptionsGrid({
    required this.options,
    required this.selectedOptions,
    required this.wrongOptionId,
    required this.correctOptionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(
          width: constraints.maxWidth,
          optionCount: options.length,
        );

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.05,
          ),
          itemBuilder: (context, index) {
            final option = options[index];

            return _SyllableOptionTile(
              option: option,
              isSelected: selectedOptions.any(
                (selected) => selected.id == option.id,
              ),
              isWrong: wrongOptionId == option.id,
              isCorrect: correctOptionId == option.id,
              onTap: () => onTap(option),
            );
          },
        );
      },
    );
  }

  int _getCrossAxisCount({required double width, required int optionCount}) {
    if (optionCount <= 3) {
      return 3;
    }

    if (optionCount == 4) {
      return 4;
    }

    if (width >= 900) {
      return 6;
    }

    return 3;
  }
}

class _SyllableOptionTile extends StatelessWidget {
  final _SyllableOption option;
  final bool isSelected;
  final bool isWrong;
  final bool isCorrect;
  final VoidCallback onTap;

  const _SyllableOptionTile({
    required this.option,
    required this.isSelected,
    required this.isWrong,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final borderColor = _getBorderColor();

    return AnimatedOpacity(
      opacity: isSelected ? 0.35 : 1,
      duration: const Duration(milliseconds: 140),
      child: AnimatedScale(
        scale: isWrong ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: isSelected ? null : onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: borderColor,
                  width: isWrong || isCorrect ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                option.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.blueGrey.shade400 : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isWrong) {
      return Colors.red.shade50;
    }

    if (isCorrect) {
      return Colors.green.shade50;
    }

    if (isSelected) {
      return Colors.blueGrey.shade50;
    }

    return Colors.white;
  }

  Color _getBorderColor() {
    if (isWrong) {
      return Colors.red.shade500;
    }

    if (isCorrect) {
      return Colors.green.shade500;
    }

    if (isSelected) {
      return Colors.blueGrey.shade200;
    }

    return Colors.purple.shade300;
  }
}
