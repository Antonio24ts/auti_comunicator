class GameIds {
  static const String listenAndTouch = 'listen_and_touch';
  static const String memoryMatch = 'memory_match';
  static const String sentenceBuilder = 'sentence_builder';
  static const String animalSounds = 'animal_sounds';

  const GameIds._();
}

class GameProgress {
  final String gameId;
  final int bestLevel;
  final int bestStreak;
  final int totalCorrectAnswers;

  const GameProgress({
    required this.gameId,
    required this.bestLevel,
    required this.bestStreak,
    required this.totalCorrectAnswers,
  });

  factory GameProgress.empty(String gameId) {
    return GameProgress(
      gameId: gameId,
      bestLevel: 1,
      bestStreak: 0,
      totalCorrectAnswers: 0,
    );
  }

  GameProgress copyWith({
    int? bestLevel,
    int? bestStreak,
    int? totalCorrectAnswers,
  }) {
    return GameProgress(
      gameId: gameId,
      bestLevel: bestLevel ?? this.bestLevel,
      bestStreak: bestStreak ?? this.bestStreak,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
    );
  }
}

class GameProgressUpdate {
  final String gameId;
  final int level;
  final int streak;
  final int correctAnswersToAdd;

  const GameProgressUpdate({
    required this.gameId,
    required this.level,
    required this.streak,
    this.correctAnswersToAdd = 0,
  });
}

typedef GameProgressChanged = Future<void> Function(GameProgressUpdate update);
