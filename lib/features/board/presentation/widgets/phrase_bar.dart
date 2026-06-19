import 'package:flutter/material.dart';

class PhraseBar extends StatelessWidget {
  final List<String> words;
  final VoidCallback onDeleteLast;
  final VoidCallback onSpeakPhrase;

  const PhraseBar({
    super.key,
    required this.words,
    required this.onDeleteLast,
    required this.onSpeakPhrase,
  });

  @override
  Widget build(BuildContext context) {
    final phrase = words.join(' ');

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: words.isEmpty ? null : onSpeakPhrase,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    phrase.isEmpty
                        ? 'Pulsa palabras para formar una frase'
                        : phrase,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: phrase.isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: double.infinity,
            child: ElevatedButton.icon(
              onPressed: words.isEmpty ? null : onDeleteLast,
              icon: const Icon(Icons.backspace),
              label: const Text('Borrar', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
