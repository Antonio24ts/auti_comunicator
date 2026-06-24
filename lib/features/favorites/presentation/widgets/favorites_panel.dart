import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';

class FavoritesPanel extends StatelessWidget {
  final String childName;
  final List<Pictogram> favorites;
  final ValueChanged<Pictogram> onPictogramTap;
  final ValueChanged<Pictogram> onRemoveFavorite;

  const FavoritesPanel({
    super.key,
    required this.childName,
    required this.favorites,
    required this.onPictogramTap,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final cleanChildName = childName.trim();
    final title = cleanChildName.isEmpty
        ? 'Favoritos'
        : 'Favoritos de $cleanChildName';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade800, size: 34),
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
              'Mantén pulsado un favorito para eliminarlo.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: favorites.isEmpty
                ? _EmptyFavoritesMessage(childName: cleanChildName)
                : _FavoritesGrid(
                    favorites: favorites,
                    onPictogramTap: onPictogramTap,
                    onRemoveFavorite: onRemoveFavorite,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavoritesMessage extends StatelessWidget {
  final String childName;

  const _EmptyFavoritesMessage({required this.childName});

  @override
  Widget build(BuildContext context) {
    final message = childName.isEmpty
        ? 'Todavía no hay favoritos.\nMantén pulsado un pictograma para añadirlo aquí.'
        : 'Todavía no hay favoritos para $childName.\nMantén pulsado un pictograma para añadirlo aquí.';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.amber.shade200, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 74,
              color: Colors.amber.shade700,
            ),
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

class _FavoritesGrid extends StatelessWidget {
  final List<Pictogram> favorites;
  final ValueChanged<Pictogram> onPictogramTap;
  final ValueChanged<Pictogram> onRemoveFavorite;

  const _FavoritesGrid({
    required this.favorites,
    required this.onPictogramTap,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          itemCount: favorites.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final pictogram = favorites[index];

            return _FavoriteTile(
              pictogram: pictogram,
              onTap: () => onPictogramTap(pictogram),
              onLongPress: () => onRemoveFavorite(pictogram),
            );
          },
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1100) {
      return 6;
    }

    if (width >= 900) {
      return 5;
    }

    if (width >= 700) {
      return 4;
    }

    return 3;
  }
}

class _FavoriteTile extends StatefulWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FavoriteTile({
    required this.pictogram,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_FavoriteTile> createState() => _FavoriteTileState();
}

class _FavoriteTileState extends State<_FavoriteTile> {
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
        scale: _isPressed ? 1.03 : 1,
        duration: const Duration(milliseconds: 90),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.amber.shade300,
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
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      widget.pictogram.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        return Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.blueGrey.shade400,
                          size: 44,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pictogram.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
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
