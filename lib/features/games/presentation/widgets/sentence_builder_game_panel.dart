import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/sound_effects_service.dart';
import '../../../../services/speech_services.dart';
import '../../domain/game_progress.dart';
import '../../domain/sentence_builder_challenge.dart';
import '../../domain/sentence_builder_challenges.dart';

class SentenceBuilderGamePanel extends StatefulWidget {
  final PictogramRepository repository;
  final SpeechService speechService;
  final SoundEffectsService soundEffectsService;
  final GameProgressChanged onProgressChanged;
  final VoidCallback onBackToGames;

  const SentenceBuilderGamePanel({
    super.key,
    required this.repository,
    required this.speechService,
    required this.soundEffectsService,
    required this.onProgressChanged,
    required this.onBackToGames,
  });

  @override
  State<SentenceBuilderGamePanel> createState() =>
      _SentenceBuilderGamePanelState();
}

class _SentenceBuilderGamePanelState extends State<SentenceBuilderGamePanel> {
  static const Duration _wrongFlashDuration = Duration(milliseconds: 420);
  static const Duration _nextRoundDelay = Duration(milliseconds: 900);

  final Random _random = Random();

  int _level = 1;
  int _completedSentencesInLevel = 0;
  int _streak = 0;
  int _currentTargetIndex = 0;

  bool _isChangingRound = false;
  bool _completedCurrentSentenceWithoutError = true;

  String? _wrongPictogramId;
  String? _correctPictogramId;

  late SentenceBuilderChallenge _challenge;
  late List<Pictogram> _targetPictograms;
  late List<Pictogram> _optionPictograms;

  final List<Pictogram> _selectedPictograms = [];

  @override
  void initState() {
    super.initState();
    _startLevel(level: 1, speak: true);
  }

  void _startLevel({required int level, required bool speak}) {
    final cleanLevel = level
        .clamp(1, SentenceBuilderChallenges.maxLevel)
        .toInt();
    final challenges = SentenceBuilderChallenges.getByLevel(cleanLevel);

    if (challenges.isEmpty) {
      return;
    }

    final challenge = challenges[_random.nextInt(challenges.length)];

    _setChallenge(
      level: cleanLevel,
      challenge: challenge,
      resetLevelCounter: level != _level,
      speak: speak,
    );
  }

  void _setChallenge({
    required int level,
    required SentenceBuilderChallenge challenge,
    required bool resetLevelCounter,
    required bool speak,
  }) {
    final targetPictograms = _resolvePictograms(challenge.targetPictogramIds);
    final optionPictograms = _resolvePictograms(challenge.optionPictogramIds)
      ..shuffle(_random);

    setState(() {
      _level = level;
      _challenge = challenge;
      _targetPictograms = targetPictograms;
      _optionPictograms = optionPictograms;
      _selectedPictograms.clear();
      _currentTargetIndex = 0;
      _wrongPictogramId = null;
      _correctPictogramId = null;
      _completedCurrentSentenceWithoutError = true;
      _isChangingRound = false;

      if (resetLevelCounter) {
        _completedSentencesInLevel = 0;
      }
    });

    if (speak) {
      unawaited(_speakCurrentPromptWithDelay());
    }
  }

  List<Pictogram> _resolvePictograms(List<String> ids) {
    final pictograms = <Pictogram>[];

    for (final id in ids) {
      final pictogram = widget.repository.getPictogramById(id);

      if (pictogram != null) {
        pictograms.add(pictogram);
      }
    }

    return pictograms;
  }

  Future<void> _speakCurrentPromptWithDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    await _speakCurrentPrompt();
  }

  Future<void> _speakCurrentPrompt() async {
    switch (_challenge.mode) {
      case SentenceBuilderMode.audioPrompt:
        await widget.speechService.speakPhrase(_challenge.spokenSentence);
        break;

      case SentenceBuilderMode.textPrompt:
        await widget.speechService.speakPhrase(_challenge.spokenSentence);
        break;

      case SentenceBuilderMode.imagePrompt:
        await widget.speechService.speakPhrase(
          'Mira la imagen y construye la frase',
        );
        break;
    }
  }

  void _repeatPrompt() {
    unawaited(_speakCurrentPrompt());
  }

  Future<void> _handleOptionTap(Pictogram pictogram) async {
    if (_isChangingRound) {
      return;
    }

    if (_currentTargetIndex >= _targetPictograms.length) {
      return;
    }

    final expectedPictogram = _targetPictograms[_currentTargetIndex];

    if (pictogram.id != expectedPictogram.id) {
      _handleWrongPictogram(pictogram);
      return;
    }

    await _handleCorrectPictogram(pictogram);
  }

  void _handleWrongPictogram(Pictogram pictogram) {
    widget.soundEffectsService.playError();

    setState(() {
      _wrongPictogramId = pictogram.id;
      _completedCurrentSentenceWithoutError = false;
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

  Future<void> _handleCorrectPictogram(Pictogram pictogram) async {
    setState(() {
      _selectedPictograms.add(pictogram);
      _correctPictogramId = pictogram.id;
      _currentTargetIndex++;
    });

    unawaited(widget.speechService.speakPhrase(pictogram.text));

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (!mounted) {
          return;
        }

        if (_correctPictogramId == pictogram.id) {
          setState(() {
            _correctPictogramId = null;
          });
        }
      }),
    );

    if (_currentTargetIndex >= _targetPictograms.length) {
      await _handleSentenceCompleted();
    }
  }

  Future<void> _handleSentenceCompleted() async {
    setState(() {
      _isChangingRound = true;
    });

    final nextCompletedSentences = _completedSentencesInLevel + 1;
    final shouldLevelUp =
        nextCompletedSentences >=
        SentenceBuilderChallenges.completedSentencesToLevelUp;

    final nextLevel = shouldLevelUp
        ? (_level + 1).clamp(1, SentenceBuilderChallenges.maxLevel)
        : _level;

    final newStreak = _completedCurrentSentenceWithoutError
        ? _streak + 1
        : _streak;

    setState(() {
      _completedSentencesInLevel = shouldLevelUp ? 0 : nextCompletedSentences;
      _streak = newStreak;
    });

    await widget.onProgressChanged(
      GameProgressUpdate(
        gameId: GameIds.sentenceBuilder,
        level: nextLevel,
        streak: _streak,
        correctAnswersToAdd: 1,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) {
      return;
    }

    await widget.speechService.speakPhrase('Muy bien');

    await Future<void>.delayed(_getDelayAfterSpeech('Muy bien'));

    if (!mounted) {
      return;
    }

    await widget.speechService.speakPhrase(_challenge.spokenSentence);

    await Future<void>.delayed(_getDelayAfterSpeech(_challenge.spokenSentence));

    if (!mounted) {
      return;
    }

    if (shouldLevelUp && _level < SentenceBuilderChallenges.maxLevel) {
      await widget.speechService.speakPhrase('Subes de nivel');
      await Future<void>.delayed(_getDelayAfterSpeech('Subes de nivel'));
    }

    if (!mounted) {
      return;
    }

    await Future<void>.delayed(_nextRoundDelay);

    if (!mounted) {
      return;
    }

    _startLevel(level: nextLevel, speak: true);
  }

  Duration _getDelayAfterSpeech(String text) {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return const Duration(milliseconds: 500);
    }

    final estimatedMilliseconds = 650 + (cleanText.length * 55);

    return Duration(milliseconds: estimatedMilliseconds.clamp(850, 2400));
  }

  void _removeLastSelected() {
    if (_isChangingRound || _selectedPictograms.isEmpty) {
      return;
    }

    setState(() {
      _selectedPictograms.removeLast();
      _currentTargetIndex = max(0, _currentTargetIndex - 1);
    });
  }

  void _clearSelected() {
    if (_isChangingRound || _selectedPictograms.isEmpty) {
      return;
    }

    setState(() {
      _selectedPictograms.clear();
      _currentTargetIndex = 0;
      _completedCurrentSentenceWithoutError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressText =
        'Nivel $_level · $_completedSentencesInLevel/'
        '${SentenceBuilderChallenges.completedSentencesToLevelUp} para subir';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _Header(
            progressText: progressText,
            repeatButtonText: _challenge.mode == SentenceBuilderMode.audioPrompt
                ? 'Repetir frase'
                : 'Leer frase',
            onRepeatPrompt: _repeatPrompt,
            onBackToGames: widget.onBackToGames,
          ),
          const SizedBox(height: 12),
          _PromptPanel(challenge: _challenge),
          const SizedBox(height: 12),
          _SentenceTargetBar(
            targetLength: _targetPictograms.length,
            selectedPictograms: _selectedPictograms,
            isCompleted: _currentTargetIndex >= _targetPictograms.length,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _OptionsGrid(
              options: _optionPictograms,
              wrongPictogramId: _wrongPictogramId,
              correctPictogramId: _correctPictogramId,
              selectedPictogramIds: _selectedPictograms
                  .map((pictogram) => pictogram.id)
                  .toSet(),
              onTap: _handleOptionTap,
            ),
          ),
          const SizedBox(height: 12),
          _BottomControls(
            onRemoveLast: _removeLastSelected,
            onClear: _clearSelected,
            canRemoveLast: _selectedPictograms.isNotEmpty && !_isChangingRound,
            canClear: _selectedPictograms.isNotEmpty && !_isChangingRound,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String progressText;
  final String repeatButtonText;
  final VoidCallback onRepeatPrompt;
  final VoidCallback onBackToGames;

  const _Header({
    required this.progressText,
    required this.repeatButtonText,
    required this.onRepeatPrompt,
    required this.onBackToGames,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.account_tree_rounded,
          size: 34,
          color: Colors.deepPurple.shade700,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Construye la frase',
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
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRepeatPrompt,
          icon: const Icon(Icons.volume_up_rounded),
          label: Text(repeatButtonText),
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

class _PromptPanel extends StatelessWidget {
  final SentenceBuilderChallenge challenge;

  const _PromptPanel({required this.challenge});

  @override
  Widget build(BuildContext context) {
    switch (challenge.mode) {
      case SentenceBuilderMode.audioPrompt:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.deepPurple.shade100, width: 1.8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.volume_up_rounded,
                color: Colors.deepPurple.shade700,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Escucha la frase y constrúyela con pictogramas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            ],
          ),
        );

      case SentenceBuilderMode.textPrompt:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.deepPurple.shade200, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                color: Colors.deepPurple.shade700,
                size: 34,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  challenge.spokenSentence,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );

      case SentenceBuilderMode.imagePrompt:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.deepPurple.shade100, width: 1.8),
          ),
          child: Row(
            children: [
              Container(
                width: 140,
                height: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.deepPurple.shade200,
                    width: 1.6,
                  ),
                ),
                child: Image.asset(
                  challenge.promptImagePath ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(
                      Icons.image_not_supported_outlined,
                      size: 42,
                      color: Colors.deepPurple.shade300,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Mira la imagen y construye la frase correcta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
              Icon(
                Icons.visibility_rounded,
                color: Colors.deepPurple.shade500,
                size: 34,
              ),
            ],
          ),
        );
    }
  }
}

class _SentenceTargetBar extends StatelessWidget {
  final int targetLength;
  final List<Pictogram> selectedPictograms;
  final bool isCompleted;

  const _SentenceTargetBar({
    required this.targetLength,
    required this.selectedPictograms,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCompleted
        ? Colors.green.shade500
        : Colors.deepPurple.shade200;
    final backgroundColor = isCompleted ? Colors.green.shade50 : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isCompleted ? 3 : 2),
      ),
      child: Row(
        children: [
          Text(
            'Tu frase',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: targetLength,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index < selectedPictograms.length) {
                    return _MiniSelectedPictogram(
                      pictogram: selectedPictograms[index],
                    );
                  }

                  return _EmptySlot(index: index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSelectedPictogram extends StatelessWidget {
  final Pictogram pictogram;

  const _MiniSelectedPictogram({required this.pictogram});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade400, width: 2.4),
      ),
      child: Image.asset(
        pictogram.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return Icon(
            Icons.image_not_supported_outlined,
            color: Colors.green.shade700,
          );
        },
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final int index;

  const _EmptySlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade200, width: 2),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.shade300,
        ),
      ),
    );
  }
}

class _OptionsGrid extends StatelessWidget {
  final List<Pictogram> options;
  final String? wrongPictogramId;
  final String? correctPictogramId;
  final Set<String> selectedPictogramIds;
  final ValueChanged<Pictogram> onTap;

  const _OptionsGrid({
    required this.options,
    required this.wrongPictogramId,
    required this.correctPictogramId,
    required this.selectedPictogramIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(options.length);
        final rowCount = (options.length / crossAxisCount).ceil();

        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 12)) /
            crossAxisCount;

        final itemHeight =
            (constraints.maxHeight - ((rowCount - 1) * 12)) / rowCount;

        final childAspectRatio = itemWidth / itemHeight.clamp(100, 190);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final pictogram = options[index];

            return _SentenceOptionTile(
              pictogram: pictogram,
              isWrong: wrongPictogramId == pictogram.id,
              isCorrect: correctPictogramId == pictogram.id,
              isAlreadySelected: selectedPictogramIds.contains(pictogram.id),
              onTap: () => onTap(pictogram),
            );
          },
        );
      },
    );
  }

  int _getCrossAxisCount(int length) {
    if (length <= 4) {
      return 4;
    }

    if (length <= 6) {
      return 3;
    }

    if (length <= 8) {
      return 4;
    }

    return 5;
  }
}

class _SentenceOptionTile extends StatelessWidget {
  final Pictogram pictogram;
  final bool isWrong;
  final bool isCorrect;
  final bool isAlreadySelected;
  final VoidCallback onTap;

  const _SentenceOptionTile({
    required this.pictogram,
    required this.isWrong,
    required this.isCorrect,
    required this.isAlreadySelected,
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isWrong || isCorrect ? 3 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: isAlreadySelected ? null : onTap,
            borderRadius: BorderRadius.circular(18),
            child: Opacity(
              opacity: isAlreadySelected ? 0.35 : 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  pictogram.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.blueGrey.shade400,
                      size: 38,
                    );
                  },
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

    return Colors.white;
  }

  Color _getBorderColor() {
    if (isWrong) {
      return Colors.red.shade500;
    }

    if (isCorrect) {
      return Colors.green.shade500;
    }

    return Colors.deepPurple.shade200;
  }
}

class _BottomControls extends StatelessWidget {
  final VoidCallback onRemoveLast;
  final VoidCallback onClear;
  final bool canRemoveLast;
  final bool canClear;

  const _BottomControls({
    required this.onRemoveLast,
    required this.onClear,
    required this.canRemoveLast,
    required this.canClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: canRemoveLast ? onRemoveLast : null,
          icon: const Icon(Icons.backspace_outlined),
          label: const Text('Borrar último'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: canClear ? onClear : null,
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Limpiar'),
        ),
        const Spacer(),
        Text(
          'Construye la frase tocando los pictogramas en orden.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }
}
