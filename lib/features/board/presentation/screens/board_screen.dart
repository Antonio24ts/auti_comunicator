import 'package:flutter/material.dart';

import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../widgets/pictogram_card.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final SpeechService _speechService = SpeechService();

  @override
  void initState() {
    super.initState();
    _speechService.init();
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1000) {
      return 5;
    }

    if (width >= 700) {
      return 4;
    }

    if (width >= 500) {
      return 3;
    }

    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final pictograms = PictogramRepository().getDefaultPictograms();

    return Scaffold(
      appBar: AppBar(title: const Text('Tablero')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: pictograms.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final pictogram = pictograms[index];

                return PictogramCard(
                  pictogram: pictogram,
                  onTap: () {
                    _speechService.speak(pictogram.text);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
