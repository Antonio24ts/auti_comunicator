import 'package:flutter/material.dart';

import '../../domain/game_progress.dart';

class GamesMenuPanel extends StatelessWidget {
  final VoidCallback onOpenListenAndTouch;
  final VoidCallback onOpenMemoryMatch;
  final VoidCallback onOpenSentenceBuilder;
  final GameProgress listenAndTouchProgress;
  final GameProgress memoryMatchProgress;
  final GameProgress sentenceBuilderProgress;
  final VoidCallback onOpenAnimalSounds;
  final GameProgress animalSoundsProgress;

  const GamesMenuPanel({
    super.key,
    required this.onOpenListenAndTouch,
    required this.onOpenMemoryMatch,
    required this.onOpenSentenceBuilder,
    required this.listenAndTouchProgress,
    required this.memoryMatchProgress,
    required this.sentenceBuilderProgress,
    required this.onOpenAnimalSounds,
    required this.animalSoundsProgress,
  });

  String _buildProgressText(GameProgress progress) {
    return 'Nv ${progress.bestLevel} · '
        'Racha ${progress.bestStreak} · '
        'Aciertos ${progress.totalCorrectAnswers}';
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      _GameMenuItem(
        title: 'Toca lo que escuchas',
        subtitle: _buildProgressText(listenAndTouchProgress),
        icon: Icons.hearing_rounded,
        onTap: onOpenListenAndTouch,
      ),
      _GameMenuItem(
        title: 'Emparejar',
        subtitle: _buildProgressText(memoryMatchProgress),
        icon: Icons.grid_view_rounded,
        onTap: onOpenMemoryMatch,
      ),
      _GameMenuItem(
        title: 'Construye la frase',
        subtitle: _buildProgressText(sentenceBuilderProgress),
        icon: Icons.account_tree_rounded,
        onTap: onOpenSentenceBuilder,
      ),
      _GameMenuItem(
        title: 'Sonidos de animales',
        subtitle: _buildProgressText(animalSoundsProgress),
        icon: Icons.pets_rounded,
        onTap: onOpenAnimalSounds,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'Juegos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final game = games[index];

                    return _GameButton(
                      title: game.title,
                      subtitle: game.subtitle,
                      icon: game.icon,
                      onTap: game.onTap,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _GameButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
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
        scale: _isPressed ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () {
              setState(() {
                _isPressed = false;
              });

              widget.onTap();
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.indigo.shade300,
                  width: _isPressed ? 2.8 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isPressed ? 0.16 : 0.08,
                    ),
                    blurRadius: _isPressed ? 12 : 6,
                    offset: Offset(0, _isPressed ? 5 : 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 38,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        widget.subtitle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
