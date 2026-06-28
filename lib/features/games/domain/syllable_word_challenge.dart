class SyllableWordChallenge {
  final String id;
  final int level;
  final String word;
  final String pictogramId;
  final List<String> targetSyllables;
  final List<String> distractorSyllables;

  const SyllableWordChallenge({
    required this.id,
    required this.level,
    required this.word,
    required this.pictogramId,
    required this.targetSyllables,
    this.distractorSyllables = const [],
  });

  int get totalOptions {
    return targetSyllables.length + distractorSyllables.length;
  }
}
