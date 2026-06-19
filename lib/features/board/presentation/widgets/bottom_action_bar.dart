import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const BottomActionBar({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Auti Comunicador',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
