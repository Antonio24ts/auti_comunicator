enum PictogramType { word, category }

class Pictogram {
  final String id;
  final String text;
  final String imagePath;
  final String categoryId;
  final PictogramType type;
  final String? targetCategoryId;

  const Pictogram({
    required this.id,
    required this.text,
    required this.imagePath,
    required this.categoryId,
    required this.type,
    this.targetCategoryId,
  });

  bool get isCategory => type == PictogramType.category;
  bool get isWord => type == PictogramType.word;
}
