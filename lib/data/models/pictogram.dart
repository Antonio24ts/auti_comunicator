enum PictogramType { word, category, letter, keyboardAction }

enum KeyboardAction { space, deleteLetter }

class Pictogram {
  final String id;
  final String text;
  final String imagePath;
  final String categoryId;
  final PictogramType type;
  final String? targetCategoryId;
  final String? value;
  final KeyboardAction? keyboardAction;

  const Pictogram({
    required this.id,
    required this.text,
    required this.imagePath,
    required this.categoryId,
    required this.type,
    this.targetCategoryId,
    this.value,
    this.keyboardAction,
  });

  factory Pictogram.fromJson(Map<String, dynamic> json) {
    return Pictogram(
      id: json['id'] as String,
      text: json['text'] as String,
      imagePath: json['imagePath'] as String? ?? '',
      categoryId: json['categoryId'] as String,
      type: _parseType(json['type'] as String),
      targetCategoryId: json['targetCategoryId'] as String?,
      value: json['value'] as String?,
      keyboardAction: _parseKeyboardAction(json['keyboardAction'] as String?),
    );
  }

  static PictogramType _parseType(String value) {
    switch (value) {
      case 'word':
        return PictogramType.word;
      case 'category':
        return PictogramType.category;
      case 'letter':
        return PictogramType.letter;
      case 'keyboardAction':
        return PictogramType.keyboardAction;
      default:
        throw ArgumentError('Tipo de pictograma no válido: $value');
    }
  }

  static KeyboardAction? _parseKeyboardAction(String? value) {
    switch (value) {
      case null:
        return null;
      case 'space':
        return KeyboardAction.space;
      case 'deleteLetter':
        return KeyboardAction.deleteLetter;
      default:
        throw ArgumentError('Acción de teclado no válida: $value');
    }
  }

  bool get isCategory => type == PictogramType.category;
  bool get isWord => type == PictogramType.word;
  bool get isLetter => type == PictogramType.letter;
  bool get isKeyboardAction => type == PictogramType.keyboardAction;
}
