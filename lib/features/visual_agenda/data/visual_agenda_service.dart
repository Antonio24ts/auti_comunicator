import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/visual_agenda_state.dart';

class VisualAgendaService {
  static const String _keyPrefix = 'visualAgenda';

  Future<VisualAgendaState> loadAgenda({required String childName}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    final rawValue = prefs.getString(key);

    if (rawValue == null || rawValue.trim().isEmpty) {
      return VisualAgendaState.empty();
    }

    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map<String, dynamic>) {
        return VisualAgendaState.empty();
      }

      return VisualAgendaState.fromJson(decoded);
    } catch (_) {
      return VisualAgendaState.empty();
    }
  }

  Future<void> saveAgenda({
    required String childName,
    required VisualAgendaState agendaState,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    await prefs.setString(key, jsonEncode(agendaState.toJson()));
  }

  Future<void> clearAgenda({required String childName}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(childName);

    await prefs.remove(key);
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
