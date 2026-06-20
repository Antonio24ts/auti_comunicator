import 'package:flutter/material.dart';

import 'features/board/presentation/screens/board_screen.dart';

class AutiComunicadorApp extends StatelessWidget {
  const AutiComunicadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comunicador auti',
      debugShowCheckedModeBanner: false,
      home: const BoardScreen(),
    );
  }
}
