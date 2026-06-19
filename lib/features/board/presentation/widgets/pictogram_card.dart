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
    final backgroundColor = pictogram.isCategory
        ? Colors.lightBlue.shade100
        : Colors.white;

    final icon = pictogram.isCategory ? Icons.add : Icons.chat_bubble_outline;

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
              Icon(icon, size: 32),
              const SizedBox(height: 6),
              Text(
                pictogram.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
