import 'package:flutter/material.dart';

import '../../../recent_phrases/domain/recent_phrase.dart';

class RecentPhrasesPanel extends StatelessWidget {
  final String childName;
  final List<RecentPhrase> recentPhrases;
  final ValueChanged<RecentPhrase> onSpeakRecentPhrase;
  final ValueChanged<RecentPhrase> onLoadRecentPhrase;

  const RecentPhrasesPanel({
    super.key,
    required this.childName,
    required this.recentPhrases,
    required this.onSpeakRecentPhrase,
    required this.onLoadRecentPhrase,
  });

  @override
  Widget build(BuildContext context) {
    final cleanChildName = childName.trim();
    final title = cleanChildName.isEmpty
        ? 'Frases recientes'
        : 'Frases recientes de $cleanChildName';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: Colors.cyan.shade800,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pulsa para hablar. Mantén pulsado para cargar arriba y editar.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: recentPhrases.isEmpty
                ? _EmptyRecentPhrasesMessage(childName: cleanChildName)
                : ListView.separated(
                    itemCount: recentPhrases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final recentPhrase = recentPhrases[index];

                      return _RecentPhraseCard(
                        recentPhrase: recentPhrase,
                        onTap: () => onSpeakRecentPhrase(recentPhrase),
                        onLongPress: () => onLoadRecentPhrase(recentPhrase),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentPhrasesMessage extends StatelessWidget {
  final String childName;

  const _EmptyRecentPhrasesMessage({required this.childName});

  @override
  Widget build(BuildContext context) {
    final message = childName.isEmpty
        ? 'Todavía no hay frases recientes.\nPulsa el botón de hablar para guardar una frase.'
        : 'Todavía no hay frases recientes para $childName.\nPulsa el botón de hablar para guardar una frase.';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.cyan.shade200, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 74, color: Colors.cyan.shade700),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPhraseCard extends StatefulWidget {
  final RecentPhrase recentPhrase;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RecentPhraseCard({
    required this.recentPhrase,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_RecentPhraseCard> createState() => _RecentPhraseCardState();
}

class _RecentPhraseCardState extends State<_RecentPhraseCard> {
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
        scale: _isPressed ? 1.01 : 1,
        duration: const Duration(milliseconds: 90),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.cyan.shade300,
                  width: _isPressed ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.recentPhrase.items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = widget.recentPhrase.items[index];

                          return _RecentPhraseItemTile(
                            text: item.text,
                            imagePath: item.imagePath,
                            isTypedText: item.isTypedText,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.volume_up_rounded,
                    color: Colors.cyan.shade800,
                    size: 32,
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

class _RecentPhraseItemTile extends StatelessWidget {
  final String text;
  final String imagePath;
  final bool isTypedText;

  const _RecentPhraseItemTile({
    required this.text,
    required this.imagePath,
    required this.isTypedText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.shade200, width: 1.6),
      ),
      child: Column(
        children: [
          Expanded(child: _buildImage()),
          const SizedBox(height: 6),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (isTypedText || imagePath.trim().isEmpty) {
      return Center(
        child: Icon(
          Icons.keyboard_rounded,
          color: Colors.cyan.shade700,
          size: 38,
        ),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        return Icon(
          Icons.image_not_supported_outlined,
          color: Colors.blueGrey.shade400,
          size: 34,
        );
      },
    );
  }
}
