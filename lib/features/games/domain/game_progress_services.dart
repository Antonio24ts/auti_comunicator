import 'package:shared_preferences/shared_preferences.dart';

import 'game_progress.dart';

class GameProgressService {
  Future<GameProgress> load({
    required String childName,
    required String gameId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keyPrefix = _buildKeyPrefix(childName: childName, gameId: gameId);

    return GameProgress(
      gameId: gameId,
      bestLevel: prefs.getInt('$keyPrefix.bestLevel') ?? 1,
      bestStreak: prefs.getInt('$keyPrefix.bestStreak') ?? 0,
      totalCorrectAnswers: prefs.getInt('$keyPrefix.totalCorrectAnswers') ?? 0,
    );
  }

  Future<GameProgress> record({
    required String childName,
    required GameProgressUpdate update,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final currentProgress = await load(
      childName: childName,
      gameId: update.gameId,
    );

    final newProgress = currentProgress.copyWith(
      bestLevel: update.level > currentProgress.bestLevel
          ? update.level
          : currentProgress.bestLevel,
      bestStreak: update.streak > currentProgress.bestStreak
          ? update.streak
          : currentProgress.bestStreak,
      totalCorrectAnswers:
          currentProgress.totalCorrectAnswers + update.correctAnswersToAdd,
    );

    final keyPrefix = _buildKeyPrefix(
      childName: childName,
      gameId: update.gameId,
    );

    await prefs.setInt('$keyPrefix.bestLevel', newProgress.bestLevel);
    await prefs.setInt('$keyPrefix.bestStreak', newProgress.bestStreak);
    await prefs.setInt(
      '$keyPrefix.totalCorrectAnswers',
      newProgress.totalCorrectAnswers,
    );

    return newProgress;
  }

  String _buildKeyPrefix({required String childName, required String gameId}) {
    final cleanChildName = childName.trim();

    final childKey = cleanChildName.isEmpty
        ? 'sin_nombre'
        : Uri.encodeComponent(cleanChildName.toLowerCase());

    return 'gameProgress.$childKey.$gameId';
  }
}
