import 'package:flutter/material.dart';

import '../../domain/game_progress.dart';

class GamesMenuPanel extends StatelessWidget {
  final VoidCallback onOpenListenAndTouch;
  final VoidCallback onOpenMemoryMatch;
  final VoidCallback onOpenSentenceBuilder;
  final VoidCallback onOpenAnimalSounds;
  final VoidCallback onOpenSyllableWords;

  final GameProgress listenAndTouchProgress;
  final GameProgress memoryMatchProgress;
  final GameProgress sentenceBuilderProgress;
  final GameProgress animalSoundsProgress;
  final GameProgress syllableWordsProgress;

  const GamesMenuPanel({
    super.key,
    required this.onOpenListenAndTouch,
    required this.onOpenMemoryMatch,
    required this.onOpenSentenceBuilder,
    required this.onOpenAnimalSounds,
    required this.onOpenSyllableWords,
    required this.listenAndTouchProgress,
    required this.memoryMatchProgress,
    required this.sentenceBuilderProgress,
    required this.animalSoundsProgress,
    required this.syllableWordsProgress,
  });

  @override
  Widget build(BuildContext context) {
    final games = [
      _GameMenuItem(
        title: 'Toca lo que escuchas',
        subtitle: _buildProgressText(listenAndTouchProgress),
        icon: Icons.hearing_rounded,
        color: Colors.blue,
        onTap: onOpenListenAndTouch,
      ),
      _GameMenuItem(
        title: 'Emparejar',
        subtitle: _buildProgressText(memoryMatchProgress),
        icon: Icons.grid_view_rounded,
        color: Colors.orange,
        onTap: onOpenMemoryMatch,
      ),
      _GameMenuItem(
        title: 'Construye la frase',
        subtitle: _buildProgressText(sentenceBuilderProgress),
        icon: Icons.chat_bubble_rounded,
        color: Colors.deepPurple,
        onTap: onOpenSentenceBuilder,
      ),
      _GameMenuItem(
        title: 'Sonidos de animales',
        subtitle: _buildProgressText(animalSoundsProgress),
        icon: Icons.pets_rounded,
        color: Colors.lightGreen,
        onTap: onOpenAnimalSounds,
      ),
      _GameMenuItem(
        title: 'Ordena la palabra',
        subtitle: _buildProgressText(syllableWordsProgress),
        icon: Icons.spellcheck_rounded,
        color: Colors.purple,
        onTap: onOpenSyllableWords,
      ),
    ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.extension_rounded,
                size: 34,
                color: Colors.blueGrey.shade800,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Juegos',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isWide ? 2.05 : 1.45,
                  ),
                  itemBuilder: (context, index) {
                    return games[index];
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildProgressText(GameProgress progress) {
    return 'Nivel: ${progress.bestLevel} · '
        'Racha: ${progress.bestStreak} · '
        'Aciertos: ${progress.totalCorrectAnswers}';
  }
}

class _GameMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _GameMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.shade200, width: 1.6),
                ),
                child: Icon(icon, color: color.shade700, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 205,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.play_arrow_rounded, color: color.shade600, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}
