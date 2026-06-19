import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pictogram.dart';

class PictogramRepository {
  static const String homeCategoryId = 'home';
  static const String _pictogramsAssetPath = 'assets/data/pictograms.json';

  final List<Pictogram> _pictograms = [];

  bool _isLoaded = false;

  Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    final jsonString = await rootBundle.loadString(_pictogramsAssetPath);
    final jsonData = jsonDecode(jsonString) as List<dynamic>;

    _pictograms
      ..clear()
      ..addAll(
        jsonData.map(
          (item) => Pictogram.fromJson(item as Map<String, dynamic>),
        ),
      );

    _isLoaded = true;
  }

  List<Pictogram> getPictogramsByCategory(String categoryId) {
    if (!_isLoaded) {
      throw StateError(
        'PictogramRepository debe cargarse con load() antes de usarse.',
      );
    }

    return _pictograms
        .where((pictogram) => pictogram.categoryId == categoryId)
        .toList();
  }
}
