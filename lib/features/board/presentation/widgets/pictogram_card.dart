import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';

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
    final backgroundColor = _getBackgroundColor();
    final icon = _getIcon();

    return Material(
      color: backgroundColor,
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
              if (!pictogram.isLetter) ...[
                Icon(icon, size: 32),
                const SizedBox(height: 6),
              ],
              Text(
                pictogram.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: pictogram.isLetter ? 28 : 18,
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

  IconData _getIcon() {
    if (pictogram.isCategory) {
      return Icons.add;
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
