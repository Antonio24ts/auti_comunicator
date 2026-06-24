import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../board/domain/phrase_item.dart';
import '../domain/recent_phrase.dart';

class RecentPhrasesService {
  static const String _keyPrefix = 'recentPhrases';
  static const int _maxRecentPhrases = 20;

  Future<List<RecentPhrase>> loadRecentPhrases({
    required String childName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    final rawList = prefs.getStringList(key) ?? <String>[];

    return rawList
        .map(_decodePhrase)
        .whereType<RecentPhrase>()
        .where((phrase) => phrase.text.trim().isNotEmpty)
        .toList();
  }

  Future<RecentPhrase?> addRecentPhrase({
    required String childName,
    required List<PhraseItem> items,
  }) async {
    final cleanItems = items
        .where((item) => item.text.trim().isNotEmpty)
        .map(
          (item) => PhraseItem(
            text: item.text.trim(),
            imagePath: item.imagePath,
            isTypedText: item.isTypedText,
          ),
        )
        .toList();

    if (cleanItems.isEmpty) {
      return null;
    }

    final phraseText = cleanItems
        .map((item) => item.text.trim())
        .where((text) => text.isNotEmpty)
        .join(' ')
        .trim();

    if (phraseText.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    final currentPhrases = await loadRecentPhrases(childName: childName);

    final now = DateTime.now();

    final newPhrase = RecentPhrase(
      id: 'recent_${now.microsecondsSinceEpoch}',
      text: phraseText,
      items: cleanItems,
      createdAt: now,
    );

    final updatedPhrases = <RecentPhrase>[
      newPhrase,
      ...currentPhrases.where(
        (phrase) => _normalizeText(phrase.text) != _normalizeText(phraseText),
      ),
    ].take(_maxRecentPhrases).toList();

    await prefs.setStringList(
      key,
      updatedPhrases.map((phrase) => jsonEncode(phrase.toJson())).toList(),
    );

    return newPhrase;
  }

  Future<void> removeRecentPhrase({
    required String childName,
    required String recentPhraseId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    final currentPhrases = await loadRecentPhrases(childName: childName);

    final updatedPhrases = currentPhrases
        .where((phrase) => phrase.id != recentPhraseId)
        .toList();

    await prefs.setStringList(
      key,
      updatedPhrases.map((phrase) => jsonEncode(phrase.toJson())).toList(),
    );
  }

  Future<void> clearAll({required String childName}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    await prefs.remove(key);
  }

  RecentPhrase? _decodePhrase(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final phrase = RecentPhrase.fromJson(decoded);

      if (phrase.id.trim().isEmpty ||
          phrase.text.trim().isEmpty ||
          phrase.items.isEmpty) {
        return null;
      }

      return phrase;
    } catch (_) {
      return null;
    }
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

  String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
