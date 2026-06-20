import 'package:flutter/material.dart';

import '../../domain/phrase_item.dart';

class PhraseBar extends StatelessWidget {
  final List<PhraseItem> items;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onDeleteLast;
  final VoidCallback onClearAll;
  final VoidCallback onSpeakPhrase;
  final ValueChanged<int> onDeleteItemAt;
  final bool canGoBack;

  const PhraseBar({
    super.key,
    required this.items,
    required this.onHome,
    required this.onBack,
    required this.onDeleteLast,
    required this.onClearAll,
    required this.onSpeakPhrase,
    required this.onDeleteItemAt,
    required this.canGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .asMap()
        .entries
        .where((entry) => entry.value.text.trim().isNotEmpty)
        .toList();

    final hasPhrase = visibleItems.isNotEmpty;

    return Container(
      height: 104,
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          _TopActionButton(label: 'Inicio', icon: Icons.home, onTap: onHome),
          const SizedBox(width: 8),
          _TopActionButton(
            label: 'Volver',
            icon: Icons.arrow_back,
            onTap: canGoBack ? onBack : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: hasPhrase ? onSpeakPhrase : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerLeft,
                child: hasPhrase
                    ? _PhraseItemList(
                        items: visibleItems,
                        onDeleteItemAt: onDeleteItemAt,
                      )
                    : const Text(
                        'Pulsa palabras para formar una frase',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            label: 'Hablar',
            icon: Icons.record_voice_over,
            onTap: hasPhrase ? onSpeakPhrase : null,
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            label: 'Borrar',
            icon: Icons.backspace,
            onTap: hasPhrase ? onDeleteLast : null,
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            label: 'Limpiar',
            icon: Icons.delete,
            onTap: hasPhrase ? onClearAll : null,
          ),
        ],
      ),
    );
  }
}

class _PhraseItemList extends StatelessWidget {
  final List<MapEntry<int, PhraseItem>> items;
  final ValueChanged<int> onDeleteItemAt;

  const _PhraseItemList({required this.items, required this.onDeleteItemAt});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in items) ...[
            _MiniPhraseCard(
              item: entry.value,
              onTap: () => onDeleteItemAt(entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _MiniPhraseCard extends StatelessWidget {
  final PhraseItem item;
  final VoidCallback onTap;

  const _MiniPhraseCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imagePath.trim().isNotEmpty;

    return SizedBox(
      width: 86,
      height: 78,
      child: Material(
        color: item.isTypedText ? Colors.amber.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(
                color: item.isTypedText
                    ? Colors.orange.shade300
                    : Colors.blueGrey.shade200,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Expanded(
                  child: hasImage
                      ? Image.asset(
                          item.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _MiniFallbackIcon(
                              isTypedText: item.isTypedText,
                            );
                          },
                        )
                      : _MiniFallbackIcon(isTypedText: item.isTypedText),
                ),
                const SizedBox(height: 3),
                Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniFallbackIcon extends StatelessWidget {
  final bool isTypedText;

  const _MiniFallbackIcon({required this.isTypedText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        isTypedText ? Icons.keyboard : Icons.image_not_supported_outlined,
        size: 24,
        color: Colors.blueGrey,
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return SizedBox(
      width: 88,
      height: double.infinity,
      child: Material(
        color: enabled ? Colors.blueGrey.shade700 : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
