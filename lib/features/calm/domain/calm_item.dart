enum CalmItemType { phrase, breathing, calmTimer, quietPlace, drinkWater }

class CalmItem {
  final String id;
  final String title;
  final String phraseText;
  final String spokenText;
  final String imagePath;
  final CalmItemType type;

  const CalmItem({
    required this.id,
    required this.title,
    required this.phraseText,
    required this.spokenText,
    required this.imagePath,
    required this.type,
  });
}
