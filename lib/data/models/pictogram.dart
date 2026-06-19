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

  bool get isCategory => type == PictogramType.category;
  bool get isWord => type == PictogramType.word;
  bool get isLetter => type == PictogramType.letter;
  bool get isKeyboardAction => type == PictogramType.keyboardAction;
}
