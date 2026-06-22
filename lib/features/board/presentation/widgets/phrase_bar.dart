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

  bool _isMobilePortrait(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return mediaQuery.orientation == Orientation.portrait &&
        size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobilePortrait(context)) {
      return _buildMobileLayout(context);
    }

    return _buildTabletLayout(context);
  }

  Widget _buildTabletLayout(BuildContext context) {
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

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.blueGrey.shade100, width: 1),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _MobilePhraseItems(
              items: items,
              onDeleteItemAt: onDeleteItemAt,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: _MobilePhraseButton(
                    label: 'Inicio',
                    icon: Icons.home_rounded,
                    backgroundColor: Colors.blueGrey.shade700,
                    foregroundColor: Colors.white,
                    onTap: onHome,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MobilePhraseButton(
                    label: 'Volver',
                    icon: Icons.arrow_back_rounded,
                    backgroundColor: canGoBack
                        ? Colors.blueGrey.shade700
                        : Colors.grey.shade300,
                    foregroundColor: canGoBack
                        ? Colors.white
                        : Colors.grey.shade600,
                    onTap: canGoBack ? onBack : null,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MobilePhraseButton(
                    label: 'Hablar',
                    icon: Icons.record_voice_over_rounded,
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    onTap: onSpeakPhrase,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MobilePhraseButton(
                    label: 'Borrar',
                    icon: Icons.backspace_rounded,
                    backgroundColor: Colors.blueGrey.shade100,
                    foregroundColor: Colors.blueGrey.shade800,
                    onTap: onDeleteLast,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MobilePhraseButton(
                    label: 'Limpiar',
                    icon: Icons.delete_rounded,
                    backgroundColor: Colors.blueGrey.shade100,
                    foregroundColor: Colors.blueGrey.shade800,
                    onTap: onClearAll,
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

class _MobilePhraseItems extends StatelessWidget {
  final List<PhraseItem> items;
  final ValueChanged<int> onDeleteItemAt;

  const _MobilePhraseItems({required this.items, required this.onDeleteItemAt});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.asMap().entries.where((entry) {
      return entry.value.text.trim().isNotEmpty;
    }).toList();

    if (visibleItems.isEmpty) {
      return Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.shade100, width: 1.4),
        ),
        child: Text(
          'Pulsa pictogramas para formar una frase',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade500,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100, width: 1.4),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final entry = visibleItems[index];
          final realIndex = entry.key;
          final item = entry.value;

          return GestureDetector(
            onTap: () {
              onDeleteItemAt(realIndex);
            },
            child: Container(
              width: 70,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: _MobilePhraseImage(item: item),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MobilePhraseImage extends StatelessWidget {
  final PhraseItem item;

  const _MobilePhraseImage({required this.item});

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imagePath.trim();

    if (imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Icon(
      item.isTypedText ? Icons.keyboard_rounded : Icons.image_outlined,
      size: 20,
      color: Colors.blueGrey.shade400,
    );
  }
}

class _MobilePhraseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  const _MobilePhraseButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foregroundColor),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
