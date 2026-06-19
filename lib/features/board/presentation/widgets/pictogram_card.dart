import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';
import 'package:flutter/foundation.dart';

class PictogramCard extends StatelessWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;

  const PictogramCard({
    super.key,
    required this.pictogram,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pictogram.imagePath.trim().isNotEmpty;

    return Material(
      color: _getBackgroundColor(),
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasImage)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Image.asset(
                      pictogram.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('ERROR cargando imagen: ${pictogram.imagePath}');
                        debugPrint('Detalle: $error');

                        return _FallbackIcon(pictogram: pictogram);
                      },
                    ),
                  ),
                )
              else if (!pictogram.isLetter)
                Expanded(child: _FallbackIcon(pictogram: pictogram)),
              Text(
                pictogram.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: pictogram.isLetter ? 34 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (pictogram.isCategory) {
      return Colors.lightBlue.shade100;
    }

    if (pictogram.isLetter) {
      return Colors.amber.shade100;
    }

    if (pictogram.isKeyboardAction) {
      return Colors.orange.shade100;
    }

    return Colors.white;
  }
}

class _FallbackIcon extends StatelessWidget {
  final Pictogram pictogram;

  const _FallbackIcon({required this.pictogram});

  @override
  Widget build(BuildContext context) {
    return Icon(_getIcon(), size: pictogram.isLetter ? 24 : 40);
  }

  IconData _getIcon() {
    if (pictogram.isCategory) {
      return Icons.folder;
    }

    if (pictogram.isLetter) {
      return Icons.keyboard;
    }

    if (pictogram.keyboardAction == KeyboardAction.space) {
      return Icons.space_bar;
    }

    if (pictogram.keyboardAction == KeyboardAction.deleteLetter) {
      return Icons.backspace;
    }

    return Icons.chat_bubble_outline;
  }
}
