import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';

class PictogramStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;

  const PictogramStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
  });
}

PictogramStyle getPictogramStyle(Pictogram pictogram) {
  if (pictogram.isLetter) {
    return PictogramStyle(
      backgroundColor: Colors.amber.shade100,
      borderColor: Colors.amber.shade400,
      accentColor: Colors.amber.shade700,
    );
  }

  if (pictogram.isKeyboardAction) {
    return PictogramStyle(
      backgroundColor: Colors.orange.shade100,
      borderColor: Colors.orange.shade400,
      accentColor: Colors.orange.shade700,
    );
  }

  if (pictogram.isCategory) {
    return _categoryStyle(pictogram.targetCategoryId ?? pictogram.id);
  }

  return _categoryStyle(pictogram.categoryId);
}

PictogramStyle _categoryStyle(String categoryId) {
  switch (categoryId) {
    case 'personas':
      return PictogramStyle(
        backgroundColor: Colors.yellow.shade100,
        borderColor: Colors.yellow.shade600,
        accentColor: Colors.orange.shade700,
      );

    case 'verbos':
    case 'acciones':
      return PictogramStyle(
        backgroundColor: Colors.green.shade100,
        borderColor: Colors.green.shade500,
        accentColor: Colors.green.shade700,
      );

    case 'preguntas':
      return PictogramStyle(
        backgroundColor: Colors.deepPurple.shade50,
        borderColor: Colors.deepPurple.shade300,
        accentColor: Colors.deepPurple.shade600,
      );

    case 'emociones':
      return PictogramStyle(
        backgroundColor: Colors.pink.shade50,
        borderColor: Colors.pink.shade300,
        accentColor: Colors.pink.shade500,
      );

    case 'comida':
      return PictogramStyle(
        backgroundColor: Colors.orange.shade100,
        borderColor: Colors.orange.shade400,
        accentColor: Colors.deepOrange.shade500,
      );

    case 'bebida':
      return PictogramStyle(
        backgroundColor: Colors.lightBlue.shade50,
        borderColor: Colors.lightBlue.shade300,
        accentColor: Colors.blue.shade600,
      );

    case 'salud':
      return PictogramStyle(
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade300,
        accentColor: Colors.red.shade500,
      );

    case 'cuerpo':
      return PictogramStyle(
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade300,
        accentColor: Colors.red.shade500,
      );

    case 'casa':
      return PictogramStyle(
        backgroundColor: Colors.brown.shade50,
        borderColor: Colors.brown.shade300,
        accentColor: Colors.brown.shade500,
      );

    case 'colegio':
      return PictogramStyle(
        backgroundColor: Colors.cyan.shade50,
        borderColor: Colors.cyan.shade300,
        accentColor: Colors.cyan.shade700,
      );

    case 'juegos':
      return PictogramStyle(
        backgroundColor: Colors.indigo.shade50,
        borderColor: Colors.indigo.shade300,
        accentColor: Colors.indigo.shade700,
      );

    case 'juego_escucha_toca':
      return PictogramStyle(
        backgroundColor: Colors.indigo.shade50,
        borderColor: Colors.indigo.shade300,
        accentColor: Colors.indigo.shade700,
      );

    case 'posicion':
      return PictogramStyle(
        backgroundColor: Colors.cyan.shade50,
        borderColor: Colors.cyan.shade300,
        accentColor: Colors.cyan.shade700,
      );

    case 'trabajo':
      return PictogramStyle(
        backgroundColor: Colors.blueGrey.shade50,
        borderColor: Colors.blueGrey.shade300,
        accentColor: Colors.blueGrey.shade600,
      );

    case 'lugares':
      return PictogramStyle(
        backgroundColor: Colors.teal.shade50,
        borderColor: Colors.teal.shade300,
        accentColor: Colors.teal.shade600,
      );

    case 'objetos':
    case 'cosas':
      return PictogramStyle(
        backgroundColor: Colors.indigo.shade50,
        borderColor: Colors.indigo.shade200,
        accentColor: Colors.indigo.shade500,
      );

    case 'saludos':
      return PictogramStyle(
        backgroundColor: Colors.lime.shade100,
        borderColor: Colors.lime.shade500,
        accentColor: Colors.lime.shade800,
      );

    case 'alfabeto':
      return PictogramStyle(
        backgroundColor: Colors.amber.shade100,
        borderColor: Colors.amber.shade400,
        accentColor: Colors.amber.shade700,
      );

    case 'home_main':
    case 'home_center':
    case 'home_right':
    case 'mas_categorias':
      return PictogramStyle(
        backgroundColor: Colors.white,
        borderColor: Colors.blueGrey.shade200,
        accentColor: Colors.blueGrey.shade600,
      );
    case 'calculadora':
      return PictogramStyle(
        backgroundColor: Colors.blue.shade50,
        borderColor: Colors.blue.shade300,
        accentColor: Colors.blue.shade700,
      );
    case 'temporizador':
      return PictogramStyle(
        backgroundColor: Colors.purple.shade50,
        borderColor: Colors.purple.shade300,
        accentColor: Colors.purple.shade700,
      );
    case 'sensorial':
      return PictogramStyle(
        backgroundColor: Colors.deepPurple.shade50,
        borderColor: Colors.deepPurple.shade300,
        accentColor: Colors.deepPurple.shade700,
      );
    case 'ropa':
      return PictogramStyle(
        backgroundColor: Colors.lightBlue.shade50,
        borderColor: Colors.lightBlue.shade300,
        accentColor: Colors.lightBlue.shade700,
      );

    case 'tiempo':
      return PictogramStyle(
        backgroundColor: Colors.cyan.shade50,
        borderColor: Colors.cyan.shade300,
        accentColor: Colors.cyan.shade700,
      );

    case 'animales':
      return PictogramStyle(
        backgroundColor: Colors.lightGreen.shade50,
        borderColor: Colors.lightGreen.shade300,
        accentColor: Colors.lightGreen.shade700,
      );

    case 'colores':
      return PictogramStyle(
        backgroundColor: Colors.amber.shade50,
        borderColor: Colors.amber.shade300,
        accentColor: Colors.amber.shade800,
      );

    case 'tamanos':
      return PictogramStyle(
        backgroundColor: Colors.indigo.shade50,
        borderColor: Colors.indigo.shade300,
        accentColor: Colors.indigo.shade700,
      );

    case 'higiene':
      return PictogramStyle(
        backgroundColor: Colors.teal.shade50,
        borderColor: Colors.teal.shade300,
        accentColor: Colors.teal.shade700,
      );

    case 'frases_recientes':
      return PictogramStyle(
        backgroundColor: Colors.teal.shade50,
        borderColor: const Color.fromARGB(255, 6, 100, 91),
        accentColor: const Color.fromARGB(255, 37, 109, 100),
      );

    case 'favoritos':
      return PictogramStyle(
        backgroundColor: Colors.teal.shade50,
        borderColor: const Color.fromARGB(255, 6, 100, 91),
        accentColor: const Color.fromARGB(255, 37, 109, 100),
      );

    case 'conectores':
      return PictogramStyle(
        backgroundColor: Colors.deepPurple.shade50,
        borderColor: Colors.deepPurple.shade300,
        accentColor: Colors.deepPurple.shade700,
      );

    default:
      return PictogramStyle(
        backgroundColor: Colors.white,
        borderColor: Colors.grey.shade300,
        accentColor: Colors.blueGrey.shade500,
      );
  }
}
