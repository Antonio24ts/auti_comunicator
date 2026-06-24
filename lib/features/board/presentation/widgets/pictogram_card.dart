import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../data/models/pictogram.dart';
import '../styles/pictogram_style.dart';

class PictogramCard extends StatefulWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;
  final CardSize cardSize;
  final VoidCallback? onLongPress;

  const PictogramCard({
    super.key,
    required this.pictogram,
    required this.onTap,
    required this.cardSize,
    this.onLongPress,
  });

  @override
  State<PictogramCard> createState() => _PictogramCardState();
}

class _PictogramCardState extends State<PictogramCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final style = getPictogramStyle(widget.pictogram);

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
        scale: _isPressed ? 1.035 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed ? style.accentColor : style.borderColor,
              width: _isPressed ? 2.4 : 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.16 : 0.08),
                blurRadius: _isPressed ? 10 : 5,
                offset: Offset(0, _isPressed ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isPressed = false;
                });

                widget.onTap();
              },
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(16),
              splashColor: style.accentColor.withValues(alpha: 0.12),
              highlightColor: style.accentColor.withValues(alpha: 0.08),
              child: Padding(
                padding: EdgeInsets.all(_getPadding()),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(child: _buildImageContent(style)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _CardText(
                      text: _getDisplayText(),
                      fontSize: _getTextFontSize(),
                      isCategory: widget.pictogram.isCategory,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(PictogramStyle style) {
    final imagePath = widget.pictogram.imagePath.trim();

    if (imagePath.isNotEmpty) {
      return Stack(
        children: [
          Center(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackContent(style);
              },
            ),
          ),
          if (widget.pictogram.isCategory)
            Positioned(
              right: 0,
              top: 0,
              child: _CategoryBadge(color: style.accentColor),
            ),
        ],
      );
    }

    return _buildFallbackContent(style);
  }

  Widget _buildFallbackContent(PictogramStyle style) {
    if (widget.pictogram.isLetter) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.pictogram.text.toLowerCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _getFallbackLetterFontSize(),
            fontWeight: FontWeight.w900,
            color: Colors.amber.shade900,
          ),
        ),
      );
    }

    if (widget.pictogram.isCategory) {
      return Icon(
        Icons.folder_rounded,
        size: _getFallbackIconSize(),
        color: style.accentColor,
      );
    }

    if (widget.pictogram.isKeyboardAction) {
      return Icon(
        Icons.keyboard_alt_outlined,
        size: _getFallbackIconSize(),
        color: style.accentColor,
      );
    }

    return Icon(
      Icons.image_not_supported_outlined,
      size: _getFallbackIconSize(),
      color: Colors.blueGrey.shade300,
    );
  }

  String _getDisplayText() {
    if (!widget.pictogram.isLetter) {
      return widget.pictogram.text;
    }

    return widget.pictogram.text.toLowerCase();
  }

  double _getPadding() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 5;
      case CardSize.medium:
        return 7;
      case CardSize.large:
        return 9;
    }
  }

  double _getTextFontSize() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 14;
      case CardSize.medium:
        return 17;
      case CardSize.large:
        return 20;
    }
  }

  double _getFallbackLetterFontSize() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 34;
      case CardSize.medium:
        return 46;
      case CardSize.large:
        return 58;
    }
  }

  double _getFallbackIconSize() {
    switch (widget.cardSize) {
      case CardSize.small:
        return 32;
      case CardSize.medium:
        return 44;
      case CardSize.large:
        return 56;
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final Color color;

  const _CategoryBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.folder_rounded, color: Colors.white, size: 17),
    );
  }
}

class _CardText extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isCategory;

  const _CardText({
    required this.text,
    required this.fontSize,
    required this.isCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.05,
          fontWeight: isCategory ? FontWeight.w900 : FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}
