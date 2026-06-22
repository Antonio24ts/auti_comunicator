import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';

enum _MemoryFinishedAction { repeat, next, backToGames }

class MemoryMatchGamePanel extends StatefulWidget {
  final PictogramRepository repository;
  final SpeechService speechService;
  final CardSize cardSize;
  final VoidCallback onBackToGames;

  const MemoryMatchGamePanel({
    super.key,
    required this.repository,
    required this.speechService,
    required this.cardSize,
    required this.onBackToGames,
  });

  @override
  State<MemoryMatchGamePanel> createState() => _MemoryMatchGamePanelState();
}

class _MemoryMatchGamePanelState extends State<MemoryMatchGamePanel> {
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

  static const List<int> _pairsByLevel = [2, 3, 4, 5, 6, 8, 10, 12, 15, 18, 20];

  final Random _random = Random();

  late final List<Pictogram> _gamePool;

  List<_MemoryCardItem> _cards = [];

  int _levelIndex = 0;
  int _attempts = 0;
  int _matchedPairs = 0;
  int _totalCompletedPairs = 0;

  String? _firstSelectedCardId;
  String? _secondSelectedCardId;
  bool _isBoardLocked = false;
  bool _isReady = false;
  String _message = 'Encuentra las parejas iguales';

  @override
  void initState() {
    super.initState();

    _gamePool = _loadGamePool();
    _isReady = _gamePool.isNotEmpty;

    if (_isReady) {
      _startLevel();
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
      final isWord = pictogram.isWord;

      return isWord && hasText && hasImage;
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

  int _getCurrentLevelNumber() {
    return _levelIndex + 1;
  }

  int _getMaxLevelNumber() {
    return _pairsByLevel.length;
  }

  int _getCurrentPairCount() {
    final requestedPairs = _pairsByLevel[_levelIndex];

    return min(requestedPairs, _gamePool.length);
  }

  int _getCurrentCardCount() {
    return _getCurrentPairCount() * 2;
  }

  void _startLevel() {
    final pairCount = _getCurrentPairCount();
    final shuffledPool = List<Pictogram>.from(_gamePool)..shuffle(_random);
    final selectedPictograms = shuffledPool.take(pairCount).toList();

    final cards = <_MemoryCardItem>[];

    for (final pictogram in selectedPictograms) {
      cards.add(
        _MemoryCardItem(
          id: '${pictogram.id}_a_${_random.nextInt(999999)}',
          pairId: pictogram.id,
          pictogram: pictogram,
        ),
      );

      cards.add(
        _MemoryCardItem(
          id: '${pictogram.id}_b_${_random.nextInt(999999)}',
          pairId: pictogram.id,
          pictogram: pictogram,
        ),
      );
    }

    cards.shuffle(_random);

    setState(() {
      _cards = cards;
      _attempts = 0;
      _matchedPairs = 0;
      _firstSelectedCardId = null;
      _secondSelectedCardId = null;
      _isBoardLocked = false;
      _message = 'Encuentra las parejas iguales';
    });
  }

  void _restartCurrentLevel() {
    _startLevel();
  }

  void _goToNextLevel() {
    if (_levelIndex < _pairsByLevel.length - 1) {
      setState(() {
        _levelIndex++;
      });

      _startLevel();
      return;
    }

    _startLevel();
  }

  Future<void> _handleCardTap(_MemoryCardItem card) async {
    if (_isBoardLocked || card.isFaceUp || card.isMatched) {
      return;
    }

    if (_firstSelectedCardId == null) {
      setState(() {
        _firstSelectedCardId = card.id;
        _cards = _cards.map((item) {
          if (item.id == card.id) {
            return item.copyWith(isFaceUp: true);
          }

          return item;
        }).toList();
        _message = 'Busca su pareja';
      });

      return;
    }

    if (_firstSelectedCardId == card.id) {
      return;
    }

    setState(() {
      _secondSelectedCardId = card.id;
      _attempts++;
      _isBoardLocked = true;
      _cards = _cards.map((item) {
        if (item.id == card.id) {
          return item.copyWith(isFaceUp: true);
        }

        return item;
      }).toList();
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    final firstCard = _cards.firstWhere(
      (item) => item.id == _firstSelectedCardId,
    );

    final secondCard = _cards.firstWhere(
      (item) => item.id == _secondSelectedCardId,
    );

    final isMatch = firstCard.pairId == secondCard.pairId;

    if (isMatch) {
      await _handleMatch(firstCard, secondCard);
      return;
    }

    await _handleNoMatch(firstCard, secondCard);
  }

  Future<void> _handleMatch(
    _MemoryCardItem firstCard,
    _MemoryCardItem secondCard,
  ) async {
    final spokenText = firstCard.pictogram.text.trim();
    final feedbackText = spokenText.isEmpty ? 'Muy bien' : spokenText;

    setState(() {
      _matchedPairs++;
      _totalCompletedPairs++;
      _message = feedbackText;

      _cards = _cards.map((item) {
        if (item.id == firstCard.id || item.id == secondCard.id) {
          return item.copyWith(isFaceUp: true, isMatched: true);
        }

        return item;
      }).toList();

      _firstSelectedCardId = null;
      _secondSelectedCardId = null;
      _isBoardLocked = false;
    });

    await widget.speechService.speakPhrase(feedbackText);

    if (!mounted) {
      return;
    }

    final hasCompletedLevel = _matchedPairs >= _getCurrentPairCount();

    if (!hasCompletedLevel) {
      return;
    }

    await Future.delayed(_getDelayAfterPairSpeech(feedbackText));

    if (!mounted) {
      return;
    }

    await _handleLevelCompleted();
  }

  Duration _getDelayAfterPairSpeech(String text) {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return const Duration(milliseconds: 500);
    }

    final estimatedMilliseconds = 650 + (cleanText.length * 55);

    return Duration(milliseconds: estimatedMilliseconds.clamp(900, 2200));
  }

  Future<void> _handleNoMatch(
    _MemoryCardItem firstCard,
    _MemoryCardItem secondCard,
  ) async {
    setState(() {
      _message = 'No son iguales';
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    setState(() {
      _cards = _cards.map((item) {
        if (item.id == firstCard.id || item.id == secondCard.id) {
          return item.copyWith(isFaceUp: false);
        }

        return item;
      }).toList();

      _firstSelectedCardId = null;
      _secondSelectedCardId = null;
      _isBoardLocked = false;
      _message = 'Inténtalo otra vez';
    });
  }

  Future<void> _handleLevelCompleted() async {
    setState(() {
      _message = 'Nivel completado';
      _isBoardLocked = true;
    });

    await widget.speechService.speakPhrase('Nivel completado');

    if (!mounted) {
      return;
    }

    final isLastLevel = _levelIndex >= _pairsByLevel.length - 1;

    final action = await showDialog<_MemoryFinishedAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isLastLevel ? 'Juego completado' : 'Nivel completado'),
          content: Text(
            isLastLevel
                ? 'Has completado el último nivel.'
                : 'Has encontrado todas las parejas.',
            style: const TextStyle(fontSize: 18, height: 1.25),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_MemoryFinishedAction.repeat);
              },
              icon: const Icon(Icons.replay),
              label: const Text('Repetir nivel'),
            ),
            if (isLastLevel)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(_MemoryFinishedAction.backToGames);
                },
                icon: const Icon(Icons.sports_esports),
                label: const Text('Volver a juegos'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(_MemoryFinishedAction.next);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Siguiente nivel'),
              ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == _MemoryFinishedAction.next) {
      _goToNextLevel();
      return;
    }

    if (action == _MemoryFinishedAction.backToGames) {
      widget.onBackToGames();
      return;
    }

    _restartCurrentLevel();
  }

  int _getGridColumnCount() {
    final cardCount = _getCurrentCardCount();

    if (cardCount <= 4) {
      return 2;
    }

    if (cardCount <= 6) {
      return 3;
    }

    if (cardCount <= 12) {
      return 4;
    }

    if (cardCount <= 20) {
      return 5;
    }

    if (cardCount <= 24) {
      return 6;
    }

    if (cardCount <= 28) {
      return 7;
    }

    return 8;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return _buildNotReadyState();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _MemoryHeader(
            level: _getCurrentLevelNumber(),
            maxLevel: _getMaxLevelNumber(),
            pairCount: _getCurrentPairCount(),
            matchedPairs: _matchedPairs,
            attempts: _attempts,
            totalCompletedPairs: _totalCompletedPairs,
            message: _message,
            onRestart: _restartCurrentLevel,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _getGridColumnCount();
                final rows = (_cards.length / columns).ceil();

                const gridPadding = 4.0;
                const spacing = 8.0;

                final totalHorizontalSpacing =
                    (gridPadding * 2) + (spacing * (columns - 1));
                final totalVerticalSpacing =
                    (gridPadding * 2) + (spacing * (rows - 1));

                final availableCellWidth =
                    (constraints.maxWidth - totalHorizontalSpacing) / columns;
                final availableCellHeight =
                    (constraints.maxHeight - totalVerticalSpacing) / rows;

                final rawChildAspectRatio =
                    availableCellWidth / availableCellHeight;

                final childAspectRatio =
                    rawChildAspectRatio.isFinite && rawChildAspectRatio > 0
                    ? rawChildAspectRatio
                    : 1.0;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(gridPadding),
                  itemCount: _cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final card = _cards[index];

                    return _MemoryCard(
                      card: card,
                      cardSize: widget.cardSize,
                      onTap: () => _handleCardTap(card),
                    );
                  },
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

class _MemoryCardItem {
  final String id;
  final String pairId;
  final Pictogram pictogram;
  final bool isFaceUp;
  final bool isMatched;

  const _MemoryCardItem({
    required this.id,
    required this.pairId,
    required this.pictogram,
    this.isFaceUp = false,
    this.isMatched = false,
  });

  _MemoryCardItem copyWith({bool? isFaceUp, bool? isMatched}) {
    return _MemoryCardItem(
      id: id,
      pairId: pairId,
      pictogram: pictogram,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}

class _MemoryHeader extends StatelessWidget {
  final int level;
  final int maxLevel;
  final int pairCount;
  final int matchedPairs;
  final int attempts;
  final int totalCompletedPairs;
  final String message;
  final VoidCallback onRestart;

  const _MemoryHeader({
    required this.level,
    required this.maxLevel,
    required this.pairCount,
    required this.matchedPairs,
    required this.attempts,
    required this.totalCompletedPairs,
    required this.message,
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
        border: Border.all(color: Colors.teal.shade200, width: 1.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MemoryHeaderInfo(
              level: level,
              maxLevel: maxLevel,
              pairCount: pairCount,
              matchedPairs: matchedPairs,
              attempts: attempts,
              totalCompletedPairs: totalCompletedPairs,
              message: message,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 145,
            height: double.infinity,
            child: _MemoryHeaderButton(
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

class _MemoryHeaderInfo extends StatelessWidget {
  final int level;
  final int maxLevel;
  final int pairCount;
  final int matchedPairs;
  final int attempts;
  final int totalCompletedPairs;
  final String message;

  const _MemoryHeaderInfo({
    required this.level,
    required this.maxLevel,
    required this.pairCount,
    required this.matchedPairs,
    required this.attempts,
    required this.totalCompletedPairs,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cleanMessage = message.trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              flex: 3,
              child: Text(
                'Emparejar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal.shade900,
                ),
              ),
            ),
            if (cleanMessage.isNotEmpty) ...[
              const SizedBox(width: 12),
              Flexible(
                flex: 6,
                child: Text(
                  cleanMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Nivel $level/$maxLevel · $pairCount parejas · '
          'Encontradas $matchedPairs/$pairCount · Intentos $attempts',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade700,
          ),
        ),
      ],
    );
  }
}

class _MemoryHeaderButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _MemoryHeaderButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_MemoryHeaderButton> createState() => _MemoryHeaderButtonState();
}

class _MemoryHeaderButtonState extends State<_MemoryHeaderButton> {
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

class _MemoryCard extends StatefulWidget {
  final _MemoryCardItem card;
  final CardSize cardSize;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.card,
    required this.cardSize,
    required this.onTap,
  });

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> {
  bool _isPressed = false;

  double _getCardInnerPadding() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 4;
      case CardSize.medium:
        return 5;
      case CardSize.large:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = widget.card.isFaceUp || widget.card.isMatched;

    return Listener(
      onPointerDown: (_) {
        if (!isVisible) {
          setState(() {
            _isPressed = true;
          });
        }
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isVisible ? Colors.white : Colors.teal.shade200,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.card.isMatched
                  ? Colors.green.shade600
                  : Colors.teal.shade400,
              width: widget.card.isMatched ? 3 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.16 : 0.07),
                blurRadius: _isPressed ? 10 : 5,
                offset: Offset(0, _isPressed ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: EdgeInsets.all(_getCardInnerPadding()),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isVisible
                      ? _MemoryCardFront(
                          key: ValueKey('front_${widget.card.id}'),
                          pictogram: widget.card.pictogram,
                          cardSize: widget.cardSize,
                        )
                      : _MemoryCardBack(
                          key: ValueKey('back_${widget.card.id}'),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryCardFront extends StatelessWidget {
  final Pictogram pictogram;
  final CardSize cardSize;

  const _MemoryCardFront({
    super.key,
    required this.pictogram,
    required this.cardSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Image.asset(
              pictogram.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported_outlined,
                  size: _getIconSize(),
                  color: Colors.blueGrey.shade300,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            pictogram.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _getTextFontSize(),
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  double _getTextFontSize() {
    switch (cardSize) {
      case CardSize.small:
        return 10;
      case CardSize.medium:
        return 12;
      case CardSize.large:
        return 14;
    }
  }

  double _getIconSize() {
    switch (cardSize) {
      case CardSize.small:
        return 30;
      case CardSize.medium:
        return 40;
      case CardSize.large:
        return 50;
    }
  }
}

class _MemoryCardBack extends StatelessWidget {
  const _MemoryCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.teal.shade300,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          Icons.extension_rounded,
          size: 46,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
