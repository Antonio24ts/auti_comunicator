import 'package:flutter/material.dart';

import '../../../../data/repositories/pictogram_repository.dart';
import '../widgets/pictogram_card.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pictograms = PictogramRepository().getDefaultPictograms();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: pictograms.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final pictogram = pictograms[index];

            return PictogramCard(
              pictogram: pictogram,
              onTap: () {
                debugPrint('Pulsado: ${pictogram.text}');
              },
            );
          },
        ),
      ),
    );
  }
}