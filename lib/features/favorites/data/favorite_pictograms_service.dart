import 'package:shared_preferences/shared_preferences.dart';

class FavoritePictogramsService {
  static const String _keyPrefix = 'favoritePictograms';

  Future<List<String>> loadFavoriteIds({required String childName}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    return prefs.getStringList(key) ?? <String>[];
  }

  Future<void> addFavorite({
    required String childName,
    required String pictogramId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    final currentIds = prefs.getStringList(key) ?? <String>[];

    if (currentIds.contains(pictogramId)) {
      return;
    }

    final updatedIds = <String>[pictogramId, ...currentIds];

    await prefs.setStringList(key, updatedIds);
  }

  Future<void> removeFavorite({
    required String childName,
    required String pictogramId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    final currentIds = prefs.getStringList(key) ?? <String>[];

    final updatedIds = currentIds
        .where((currentId) => currentId != pictogramId)
        .toList();

    await prefs.setStringList(key, updatedIds);
  }

  Future<bool> isFavorite({
    required String childName,
    required String pictogramId,
  }) async {
    final favoriteIds = await loadFavoriteIds(childName: childName);

    return favoriteIds.contains(pictogramId);
  }

  String _buildKey(String childName) {
    final childKey = _buildChildKey(childName);

    return '$_keyPrefix.$childKey';
  }

  String _buildChildKey(String childName) {
    final cleanName = childName.trim().toLowerCase();

    if (cleanName.isEmpty) {
      return 'sin_nombre';
    }

    return Uri.encodeComponent(cleanName);
  }
}
