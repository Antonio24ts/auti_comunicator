import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../data/models/pictogram.dart';

class PictogramCard extends StatelessWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;
  final CardSize cardSize;

  const PictogramCard({
    super.key,
    required this.pictogram,
    required this.onTap,
    required this.cardSize,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pictogram.imagePath.trim().isNotEmpty;
    final displayText = _getDisplayText();

    return Material(
      color: _getBackgroundColor(),
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(_getCardPadding()),
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
                        return _FallbackIcon(
                          pictogram: pictogram,
                          cardSize: cardSize,
                        );
                      },
                    ),
                  ),
                )
              else if (!pictogram.isLetter)
                Expanded(
                  child: _FallbackIcon(
                    pictogram: pictogram,
                    cardSize: cardSize,
                  ),
                ),
              Text(
                displayText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _getTextSize(),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (!pictogram.isLetter) {
      return pictogram.text;
    }

    return pictogram.text.toLowerCase();
  }

  double _getTextSize() {
    if (pictogram.isLetter) {
      switch (cardSize) {
        case CardSize.small:
          return 28;
        case CardSize.medium:
          return 34;
        case CardSize.large:
          return 40;
      }
    }

    switch (cardSize) {
      case CardSize.small:
        return 15;
      case CardSize.medium:
        return 18;
      case CardSize.large:
        return 22;
    }
  }

  double _getCardPadding() {
    switch (cardSize) {
      case CardSize.small:
        return 4;
      case CardSize.medium:
        return 6;
      case CardSize.large:
        return 8;
    }
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
  final CardSize cardSize;

  const _FallbackIcon({required this.pictogram, required this.cardSize});

  @override
  Widget build(BuildContext context) {
    return Icon(_getIcon(), size: _getIconSize());
  }

  double _getIconSize() {
    switch (cardSize) {
      case CardSize.small:
        return 32;
      case CardSize.medium:
        return 40;
      case CardSize.large:
        return 48;
    }
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
