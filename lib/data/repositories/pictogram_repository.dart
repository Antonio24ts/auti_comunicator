import '../models/pictogram.dart';

class PictogramRepository {
  static const String homeCategoryId = 'home';

  List<Pictogram> getPictogramsByCategory(String categoryId) {
    return _pictograms
        .where((pictogram) => pictogram.categoryId == categoryId)
        .toList();
  }

  final List<Pictogram> _pictograms = const [
    // TABLERO PRINCIPAL
    Pictogram(
      id: 'quien',
      text: '¿Quién?',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.category,
      targetCategoryId: 'personas',
    ),
    Pictogram(
      id: 'que',
      text: '¿Qué?',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.category,
      targetCategoryId: 'cosas',
    ),
    Pictogram(
      id: 'saludos',
      text: 'Saludos',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.category,
      targetCategoryId: 'saludos',
    ),
    Pictogram(
      id: 'necesidades',
      text: 'Necesidades',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.category,
      targetCategoryId: 'necesidades',
    ),
    Pictogram(
      id: 'acciones',
      text: 'Acciones',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.category,
      targetCategoryId: 'acciones',
    ),
    Pictogram(
      id: 'si',
      text: 'Sí',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'no',
      text: 'No',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'ayuda',
      text: 'Ayuda',
      imagePath: '',
      categoryId: 'home',
      type: PictogramType.word,
    ),

    // PERSONAS
    Pictogram(
      id: 'yo',
      text: 'Yo',
      imagePath: '',
      categoryId: 'personas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'tu',
      text: 'Tú',
      imagePath: '',
      categoryId: 'personas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'mama',
      text: 'Mamá',
      imagePath: '',
      categoryId: 'personas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'papa',
      text: 'Papá',
      imagePath: '',
      categoryId: 'personas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'profesor',
      text: 'Profesor',
      imagePath: '',
      categoryId: 'personas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'amigo',
      text: 'Amigo',
      imagePath: '',
      categoryId: 'personas',
      type: PictogramType.word,
    ),

    // SALUDOS
    Pictogram(
      id: 'hola',
      text: 'Hola',
      imagePath: '',
      categoryId: 'saludos',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'adios',
      text: 'Adiós',
      imagePath: '',
      categoryId: 'saludos',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'buenos_dias',
      text: 'Buenos días',
      imagePath: '',
      categoryId: 'saludos',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'buenas_tardes',
      text: 'Buenas tardes',
      imagePath: '',
      categoryId: 'saludos',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'buenas_noches',
      text: 'Buenas noches',
      imagePath: '',
      categoryId: 'saludos',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'por_favor',
      text: 'Por favor',
      imagePath: '',
      categoryId: 'saludos',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'gracias',
      text: 'Gracias',
      imagePath: '',
      categoryId: 'saludos',
      type: PictogramType.word,
    ),

    // NECESIDADES
    Pictogram(
      id: 'quiero',
      text: 'Quiero',
      imagePath: '',
      categoryId: 'necesidades',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'agua',
      text: 'Agua',
      imagePath: '',
      categoryId: 'necesidades',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'comer',
      text: 'Comer',
      imagePath: '',
      categoryId: 'necesidades',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'bano',
      text: 'Baño',
      imagePath: '',
      categoryId: 'necesidades',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'dormir',
      text: 'Dormir',
      imagePath: '',
      categoryId: 'necesidades',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'descansar',
      text: 'Descansar',
      imagePath: '',
      categoryId: 'necesidades',
      type: PictogramType.word,
    ),

    // ACCIONES
    Pictogram(
      id: 'ir',
      text: 'Ir',
      imagePath: '',
      categoryId: 'acciones',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'venir',
      text: 'Venir',
      imagePath: '',
      categoryId: 'acciones',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'dar',
      text: 'Dar',
      imagePath: '',
      categoryId: 'acciones',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'hacer',
      text: 'Hacer',
      imagePath: '',
      categoryId: 'acciones',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'ver',
      text: 'Ver',
      imagePath: '',
      categoryId: 'acciones',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'escuchar',
      text: 'Escuchar',
      imagePath: '',
      categoryId: 'acciones',
      type: PictogramType.word,
    ),

    // COSAS
    Pictogram(
      id: 'juguete',
      text: 'Juguete',
      imagePath: '',
      categoryId: 'cosas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'pelota',
      text: 'Pelota',
      imagePath: '',
      categoryId: 'cosas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'telefono',
      text: 'Teléfono',
      imagePath: '',
      categoryId: 'cosas',
      type: PictogramType.word,
    ),
    Pictogram(
      id: 'tablet',
      text: 'Tablet',
      imagePath: '',
      categoryId: 'cosas',
      type: PictogramType.word,
    ),
  ];
}
