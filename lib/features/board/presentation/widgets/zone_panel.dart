import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../data/models/pictogram.dart';
import 'pictogram_card.dart';

class ZonePanel extends StatelessWidget {
  final List<Pictogram> pictograms;
  final int crossAxisCount;
  final double childAspectRatio;
  final CardSize cardSize;
  final ValueChanged<Pictogram> onPictogramTap;
  final ValueChanged<Pictogram>? onPictogramLongPress;

  const ZonePanel({
    super.key,
    required this.pictograms,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.cardSize,
    required this.onPictogramTap,
    this.onPictogramLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: pictograms.length,
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final pictogram = pictograms[index];

        return PictogramCard(
          pictogram: pictogram,
          onTap: () => onPictogramTap(pictogram),
          onLongPress: onPictogramLongPress == null
              ? null
              : () => onPictogramLongPress!(pictogram),
          cardSize: cardSize,
        );
      },
    );
  }
}
