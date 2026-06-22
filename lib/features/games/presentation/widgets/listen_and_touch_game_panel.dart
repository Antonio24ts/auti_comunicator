import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../../../board/presentation/widgets/pictogram_card.dart';

class ListenAndTouchGamePanel extends StatefulWidget {
  final PictogramRepository repository;
  final SpeechService speechService;
  final CardSize cardSize;

  const ListenAndTouchGamePanel({
    super.key,
    required this.repository,
    required this.speechService,
    required this.cardSize,
  });

  @override
  State<ListenAndTouchGamePanel> createState() =>
      _ListenAndTouchGamePanelState();
}

class _ListenAndTouchGamePanelState extends State<ListenAndTouchGamePanel> {
  static const Set<String> _allowedCategoryIds = {
    'bebida',
    'casa',
    'colegio',
    'comida',
    'cuerpo',
    'emociones',
    'lugares',
    'necesidades',
    'objetos',
    'personas',
    'preguntas',
    'saludos',
    'sensorial',
    'verbos',
    'trabajo',
  };

  static const List<int> _optionsByLevel = [
    2,
    3,
    4,
    6,
    8,
    10,
    12,
    16,
    20,
    24,
    30,
    40,
  ];

  static const int _correctAnswersToLevelUp = 3;

  final Random _random = Random();

  late final List<Pictogram> _gamePool;

  List<Pictogram> _currentOptions = [];
  Pictogram? _targetPictogram;

  int _levelIndex = 0;
  int _totalCorrectAnswers = 0;
  int _streak = 0;
  int _round = 0;

  bool _isReady = false;
  bool _isAnswerLocked = false;
  String? _message;
  String? _selectedPictogramId;

  @override
  void initState() {
    super.initState();

    _gamePool = _loadGamePool();
    _isReady = _gamePool.length >= 2;

    if (_isReady) {
      _startNewRound(speakTarget: true);
    } else {
      _message = 'No hay suficientes pictogramas para jugar.';
    }
  }

  List<Pictogram> _loadGamePool() {
    final pictograms = widget.repository.getPictogramsByCategories(
      _allowedCategoryIds,
    );

    final filtered = pictograms.where((pictogram) {
      final hasText = pictogram.text.trim().isNotEmpty;
      final hasImage = pictogram.imagePath.trim().isNotEmpty;

      return hasText && hasImage;
    }).toList();

    final uniqueByText = <String, Pictogram>{};

    for (final pictogram in filtered) {
      final normalizedText = pictogram.text.trim().toLowerCase();

      uniqueByText.putIfAbsent(normalizedText, () => pictogram);
    }

    final result = uniqueByText.values.toList();

    result.shuffle(_random);

    return result;
  }

  void _startNewRound({required bool speakTarget}) {
    if (!_isReady) {
      return;
    }

    final optionCount = _getCurrentOptionCount();
    final safeOptionCount = min(optionCount, _gamePool.length);

    final shuffledPool = List<Pictogram>.from(_gamePool)..shuffle(_random);
    final options = shuffledPool.take(safeOptionCount).toList();

    final target = options[_random.nextInt(options.length)];

    setState(() {
      _round++;
      _currentOptions = options;
      _targetPictogram = target;
      _message = 'Escucha y toca la imagen correcta';
      _selectedPictogramId = null;
      _isAnswerLocked = false;
    });

    if (speakTarget) {
      _speakTarget();
    }
  }

  int _getCurrentOptionCount() {
    return _optionsByLevel[_levelIndex];
  }

  int _getCurrentLevelNumber() {
    return _levelIndex + 1;
  }

  int _getMaxLevelNumber() {
    return _optionsByLevel.length;
  }

  int _getGridColumnCount() {
    final count = _getCurrentOptionCount();

    if (count <= 2) {
      return 2;
    }

    if (count <= 4) {
      return 4;
    }

    if (count <= 8) {
      return 4;
    }

    if (count <= 12) {
      return 6;
    }

    if (count <= 20) {
      return 8;
    }

    return 8;
  }

  double _getGridAspectRatio() {
    final count = _getCurrentOptionCount();

    if (count <= 4) {
      return 1.05;
    }

    if (count <= 12) {
      return 1.15;
    }

    return 1.25;
  }

  Future<void> _speakTarget() async {
    final target = _targetPictogram;

    if (target == null) {
      return;
    }

    await widget.speechService.speakPhrase(target.text);
  }

  Future<void> _handleOptionTap(Pictogram pictogram) async {
    if (_isAnswerLocked) {
      return;
    }

    final target = _targetPictogram;

    if (target == null) {
      return;
    }

    final isCorrect = pictogram.id == target.id;

    setState(() {
      _selectedPictogramId = pictogram.id;
      _isAnswerLocked = true;
    });

    if (isCorrect) {
      await _handleCorrectAnswer();
      return;
    }

    await _handleWrongAnswer();
  }

  Future<void> _handleCorrectAnswer() async {
    setState(() {
      _totalCorrectAnswers++;
      _streak++;
      _message = 'Bien';
    });

    await widget.speechService.speakPhrase('Bien');

    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) {
      return;
    }

    if (_streak >= _correctAnswersToLevelUp &&
        _levelIndex < _optionsByLevel.length - 1) {
      setState(() {
        _levelIndex++;
        _streak = 0;
        _message = 'Subes de nivel';
      });

      await widget.speechService.speakPhrase('Subes de nivel');

      await Future.delayed(const Duration(milliseconds: 450));

      if (!mounted) {
        return;
      }
    }

    _startNewRound(speakTarget: true);
  }

  Future<void> _handleWrongAnswer() async {
    setState(() {
      _streak = 0;
      _message = 'Inténtalo otra vez';
    });

    await widget.speechService.speakPhrase('Inténtalo otra vez');

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPictogramId = null;
      _isAnswerLocked = false;
      _message = 'Escucha otra vez y toca la imagen correcta';
    });

    await _speakTarget();
  }

  void _restartGame() {
    setState(() {
      _levelIndex = 0;
      _totalCorrectAnswers = 0;
      _streak = 0;
      _round = 0;
      _message = null;
      _selectedPictogramId = null;
      _isAnswerLocked = false;
    });

    _startNewRound(speakTarget: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return _buildNotReadyState();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _GameHeader(
            level: _getCurrentLevelNumber(),
            maxLevel: _getMaxLevelNumber(),
            optionCount: _getCurrentOptionCount(),
            totalCorrectAnswers: _totalCorrectAnswers,
            streak: _streak,
            round: _round,
            message: _message,
            onRepeat: _speakTarget,
            onRestart: _restartGame,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: _currentOptions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getGridColumnCount(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: _getGridAspectRatio(),
              ),
              itemBuilder: (context, index) {
                final pictogram = _currentOptions[index];

                return _GameOptionCard(
                  pictogram: pictogram,
                  cardSize: widget.cardSize,
                  isSelected: _selectedPictogramId == pictogram.id,
                  isCorrectTarget: _targetPictogram?.id == pictogram.id,
                  isAnswerLocked: _isAnswerLocked,
                  onTap: () => _handleOptionTap(pictogram),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotReadyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          'No hay suficientes pictogramas con imagen para este juego.\n'
          'Añade imágenes en las categorías permitidas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: Colors.red.shade900,
          ),
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  final int level;
  final int maxLevel;
  final int optionCount;
  final int totalCorrectAnswers;
  final int streak;
  final int round;
  final String? message;
  final VoidCallback onRepeat;
  final VoidCallback onRestart;

  const _GameHeader({
    required this.level,
    required this.maxLevel,
    required this.optionCount,
    required this.totalCorrectAnswers,
    required this.streak,
    required this.round,
    required this.message,
    required this.onRepeat,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200, width: 1.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HeaderInfo(
              level: level,
              maxLevel: maxLevel,
              optionCount: optionCount,
              totalCorrectAnswers: totalCorrectAnswers,
              streak: streak,
              round: round,
              message: message,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 170,
            height: double.infinity,
            child: _HeaderButton(
              label: 'Escuchar',
              icon: Icons.volume_up_rounded,
              backgroundColor: Colors.green.shade100,
              borderColor: Colors.green.shade500,
              textColor: Colors.green.shade900,
              onTap: onRepeat,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            height: double.infinity,
            child: _HeaderButton(
              label: 'Reiniciar',
              icon: Icons.replay_rounded,
              backgroundColor: Colors.orange.shade100,
              borderColor: Colors.orange.shade500,
              textColor: Colors.deepOrange.shade900,
              onTap: onRestart,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final int level;
  final int maxLevel;
  final int optionCount;
  final int totalCorrectAnswers;
  final int streak;
  final int round;
  final String? message;

  const _HeaderInfo({
    required this.level,
    required this.maxLevel,
    required this.optionCount,
    required this.totalCorrectAnswers,
    required this.streak,
    required this.round,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cleanMessage = message?.trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              flex: 5,
              child: Text(
                'Toca lo que escuchas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo.shade900,
                ),
              ),
            ),
            if (cleanMessage != null && cleanMessage.isNotEmpty) ...[
              const SizedBox(width: 14),
              Flexible(
                flex: 6,
                child: Text(
                  cleanMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Nivel $level/$maxLevel · $optionCount opciones · '
          'Aciertos $totalCorrectAnswers · Racha $streak · Ronda $round',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade700,
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onPointerUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onPointerCancel: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Material(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              setState(() {
                _isPressed = false;
              });

              widget.onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.borderColor,
                  width: _isPressed ? 2.4 : 1.6,
                ),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 26, color: widget.textColor),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: widget.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOptionCard extends StatelessWidget {
  final Pictogram pictogram;
  final CardSize cardSize;
  final bool isSelected;
  final bool isCorrectTarget;
  final bool isAnswerLocked;
  final VoidCallback onTap;

  const _GameOptionCard({
    required this.pictogram,
    required this.cardSize,
    required this.isSelected,
    required this.isCorrectTarget,
    required this.isAnswerLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor();
    final borderWidth = _getBorderWidth();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: PictogramCard(
        pictogram: pictogram,
        cardSize: cardSize,
        onTap: onTap,
      ),
    );
  }

  Color _getBorderColor() {
    if (!isAnswerLocked) {
      return Colors.transparent;
    }

    if (isSelected && isCorrectTarget) {
      return Colors.green.shade600;
    }

    if (isSelected && !isCorrectTarget) {
      return Colors.red.shade600;
    }

    if (isCorrectTarget) {
      return Colors.green.shade300;
    }

    return Colors.transparent;
  }

  double _getBorderWidth() {
    if (!isAnswerLocked) {
      return 0;
    }

    if (isSelected || isCorrectTarget) {
      return 4;
    }

    return 0;
  }
}
