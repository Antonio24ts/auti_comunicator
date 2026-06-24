import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/sound_effects_service.dart';
import '../../../../services/speech_services.dart';
import '../../domain/animal_sound_challenge.dart';
import '../../domain/animal_sound_challenges.dart';
import '../../domain/game_progress.dart';

class AnimalSoundGamePanel extends StatefulWidget {
  final PictogramRepository repository;
  final SpeechService speechService;
  final SoundEffectsService soundEffectsService;
  final GameProgressChanged onProgressChanged;
  final VoidCallback onBackToGames;

  const AnimalSoundGamePanel({
    super.key,
    required this.repository,
    required this.speechService,
    required this.soundEffectsService,
    required this.onProgressChanged,
    required this.onBackToGames,
  });

  @override
  State<AnimalSoundGamePanel> createState() => _AnimalSoundGamePanelState();
}

class _AnimalSoundGamePanelState extends State<AnimalSoundGamePanel> {
  static const Duration _wrongFlashDuration = Duration(milliseconds: 420);
  static const Duration _correctFlashDuration = Duration(milliseconds: 450);
  static const Duration _nextRoundDelay = Duration(milliseconds: 750);

  final Random _random = Random();
  final AudioPlayer _animalAudioPlayer = AudioPlayer();

  int _level = 1;
  int _correctAnswersInLevel = 0;
  int _streak = 0;

  bool _isChangingRound = false;
  bool _isLoadingSound = false;

  String? _wrongPictogramId;
  String? _correctPictogramId;

  late AnimalSoundChallenge _currentChallenge;
  late List<AnimalSoundChallenge> _levelChallenges;
  late List<Pictogram> _optionPictograms;

  final Set<String> _usedChallengeIdsInCurrentLevel = {};

  @override
  void initState() {
    super.initState();
    _startLevel(level: 1, playSound: true);
  }

  @override
  void dispose() {
    unawaited(_animalAudioPlayer.dispose());
    super.dispose();
  }

  void _startLevel({required int level, required bool playSound}) {
    final cleanLevel = level.clamp(1, AnimalSoundChallenges.maxLevel).toInt();

    final challenges = AnimalSoundChallenges.getByLevel(cleanLevel);

    if (challenges.isEmpty) {
      return;
    }

    setState(() {
      _level = cleanLevel;
      _levelChallenges = challenges;
      _usedChallengeIdsInCurrentLevel.clear();
      _correctAnswersInLevel = 0;
    });

    _startNextRound(playSound: playSound);
  }

  void _startNextRound({required bool playSound}) {
    final availableChallenges = _levelChallenges
        .where(
          (challenge) =>
              !_usedChallengeIdsInCurrentLevel.contains(challenge.id),
        )
        .toList();

    final candidates = availableChallenges.isEmpty
        ? _levelChallenges
        : availableChallenges;

    final challenge = candidates[_random.nextInt(candidates.length)];

    _usedChallengeIdsInCurrentLevel.add(challenge.id);

    final optionPictograms = _buildOptionsForChallenge(challenge);

    setState(() {
      _currentChallenge = challenge;
      _optionPictograms = optionPictograms;
      _wrongPictogramId = null;
      _correctPictogramId = null;
      _isChangingRound = false;
    });

    if (playSound) {
      unawaited(_playCurrentAnimalSoundWithDelay());
    }
  }

  List<Pictogram> _buildOptionsForChallenge(AnimalSoundChallenge challenge) {
    final challengePool = _levelChallenges;

    final optionCount = _getOptionCountForLevel(_level);
    final distractorChallenges =
        challengePool.where((item) => item.id != challenge.id).toList()
          ..shuffle(_random);

    final selectedChallenges = <AnimalSoundChallenge>[
      challenge,
      ...distractorChallenges.take(optionCount - 1),
    ]..shuffle(_random);

    return selectedChallenges
        .map((item) => widget.repository.getPictogramById(item.pictogramId))
        .whereType<Pictogram>()
        .toList();
  }

  int _getOptionCountForLevel(int level) {
    if (level <= 1) {
      return 3;
    }

    if (level <= 4) {
      return 3;
    }

    return 3;
  }

  Future<void> _playCurrentAnimalSoundWithDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    await _playCurrentAnimalSound();
  }

  Future<void> _playCurrentAnimalSound() async {
    if (_isLoadingSound) {
      return;
    }

    setState(() {
      _isLoadingSound = true;
    });

    try {
      await _animalAudioPlayer.stop();
      await _animalAudioPlayer.setAsset(_currentChallenge.soundAssetPath);
      await _animalAudioPlayer.seek(Duration.zero);
      await _animalAudioPlayer.play();
    } catch (error, stackTrace) {
      debugPrint('[AnimalSoundGame] Error reproduciendo animal: $error');
      debugPrint('$stackTrace');

      widget.soundEffectsService.playError();
    } finally {
      setState(() {
        _isLoadingSound = false;
      });
    }
  }

  Future<void> _handleOptionTap(Pictogram pictogram) async {
    if (_isChangingRound) {
      return;
    }

    if (pictogram.id != _currentChallenge.pictogramId) {
      _handleWrongAnswer(pictogram);
      return;
    }

    await _handleCorrectAnswer(pictogram);
  }

  void _handleWrongAnswer(Pictogram pictogram) {
    widget.soundEffectsService.playError();

    setState(() {
      _wrongPictogramId = pictogram.id;
      _streak = 0;
    });

    unawaited(
      Future<void>.delayed(_wrongFlashDuration, () {
        if (!mounted) {
          return;
        }

        if (_wrongPictogramId == pictogram.id) {
          setState(() {
            _wrongPictogramId = null;
          });
        }
      }),
    );
  }

  Future<void> _handleCorrectAnswer(Pictogram pictogram) async {
    setState(() {
      _isChangingRound = true;
      _correctPictogramId = pictogram.id;
      _streak++;
    });

    unawaited(widget.speechService.speakPhrase(_currentChallenge.animalName));

    await Future<void>.delayed(_correctFlashDuration);

    if (!mounted) {
      return;
    }

    final nextCorrectAnswersInLevel = _correctAnswersInLevel + 1;

    final shouldLevelUp =
        nextCorrectAnswersInLevel >=
        AnimalSoundChallenges.correctAnswersToLevelUp;

    final nextLevel = shouldLevelUp
        ? (_level + 1).clamp(1, AnimalSoundChallenges.maxLevel).toInt()
        : _level;

    await widget.onProgressChanged(
      GameProgressUpdate(
        gameId: GameIds.animalSounds,
        level: nextLevel,
        streak: _streak,
        correctAnswersToAdd: 1,
      ),
    );

    if (!mounted) {
      return;
    }

    if (shouldLevelUp && _level < AnimalSoundChallenges.maxLevel) {
      setState(() {
        _correctAnswersInLevel = 0;
      });

      await widget.speechService.speakPhrase('Subes de nivel');
      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) {
        return;
      }

      _startLevel(level: nextLevel, playSound: true);

      return;
    }

    setState(() {
      _correctAnswersInLevel = nextCorrectAnswersInLevel;
    });

    await Future<void>.delayed(_nextRoundDelay);

    if (!mounted) {
      return;
    }

    _startNextRound(playSound: true);
  }

  @override
  Widget build(BuildContext context) {
    final progressText =
        'Nivel $_level · $_correctAnswersInLevel/'
        '${AnimalSoundChallenges.correctAnswersToLevelUp} para subir';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _Header(
            progressText: progressText,
            isLoadingSound: _isLoadingSound,
            onRepeatSound: () {
              unawaited(_playCurrentAnimalSound());
            },
            onBackToGames: widget.onBackToGames,
          ),
          const SizedBox(height: 16),
          _SoundPromptCard(
            isLoadingSound: _isLoadingSound,
            onPlaySound: () {
              unawaited(_playCurrentAnimalSound());
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _AnimalOptionsGrid(
              options: _optionPictograms,
              wrongPictogramId: _wrongPictogramId,
              correctPictogramId: _correctPictogramId,
              onTap: _handleOptionTap,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Escucha el sonido y toca el animal correcto.',
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

class _Header extends StatelessWidget {
  final String progressText;
  final bool isLoadingSound;
  final VoidCallback onRepeatSound;
  final VoidCallback onBackToGames;

  const _Header({
    required this.progressText,
    required this.isLoadingSound,
    required this.onRepeatSound,
    required this.onBackToGames,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.pets_rounded, size: 34, color: Colors.lightGreen.shade800),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sonidos de animales',
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
                  color: Colors.lightGreen.shade800,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: isLoadingSound ? null : onRepeatSound,
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Repetir sonido'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onBackToGames,
          icon: const Icon(Icons.apps_rounded),
          label: const Text('Juegos'),
        ),
      ],
    );
  }
}

class _SoundPromptCard extends StatelessWidget {
  final bool isLoadingSound;
  final VoidCallback onPlaySound;

  const _SoundPromptCard({
    required this.isLoadingSound,
    required this.onPlaySound,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: isLoadingSound ? null : onPlaySound,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.lightGreen.shade300, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLoadingSound
                    ? Icons.hourglass_top_rounded
                    : Icons.volume_up_rounded,
                size: 46,
                color: Colors.lightGreen.shade800,
              ),
              const SizedBox(width: 16),
              Text(
                isLoadingSound ? 'Cargando sonido...' : 'Escuchar animal',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalOptionsGrid extends StatelessWidget {
  final List<Pictogram> options;
  final String? wrongPictogramId;
  final String? correctPictogramId;
  final ValueChanged<Pictogram> onTap;

  const _AnimalOptionsGrid({
    required this.options,
    required this.wrongPictogramId,
    required this.correctPictogramId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final pictogram = options[index];

        return _AnimalOptionTile(
          pictogram: pictogram,
          isWrong: wrongPictogramId == pictogram.id,
          isCorrect: correctPictogramId == pictogram.id,
          onTap: () => onTap(pictogram),
        );
      },
    );
  }
}

class _AnimalOptionTile extends StatelessWidget {
  final Pictogram pictogram;
  final bool isWrong;
  final bool isCorrect;
  final VoidCallback onTap;

  const _AnimalOptionTile({
    required this.pictogram,
    required this.isWrong,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final borderColor = _getBorderColor();

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isWrong ? 0.96 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor,
            width: isWrong || isCorrect ? 3 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                pictogram.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.blueGrey.shade400,
                    size: 44,
                  );
                },
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

    return Colors.white;
  }

  Color _getBorderColor() {
    if (isWrong) {
      return Colors.red.shade500;
    }

    if (isCorrect) {
      return Colors.green.shade500;
    }

    return Colors.lightGreen.shade300;
  }
}
