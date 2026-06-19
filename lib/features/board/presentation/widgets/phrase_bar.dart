import 'package:flutter/material.dart';

class PhraseBar extends StatelessWidget {
  final List<String> words;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onDeleteLast;
  final VoidCallback onClearAll;
  final VoidCallback onSpeakPhrase;
  final bool canGoBack;

  const PhraseBar({
    super.key,
    required this.words,
    required this.onHome,
    required this.onBack,
    required this.onDeleteLast,
    required this.onClearAll,
    required this.onSpeakPhrase,
    required this.canGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final phrase = words
        .where((word) => word.trim().isNotEmpty)
        .join(' ')
        .trim();
    final hasPhrase = phrase.isNotEmpty;

    return Container(
      height: 96,
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    hasPhrase ? phrase : 'Pulsa palabras para formar una frase',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: hasPhrase ? Colors.black : Colors.grey,
                    ),
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
            onTap: words.isEmpty ? null : onDeleteLast,
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            label: 'Limpiar',
            icon: Icons.delete,
            onTap: words.isEmpty ? null : onClearAll,
          ),
        ],
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
