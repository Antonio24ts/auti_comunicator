import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pictogram.dart';

class PictogramRepository {
  static const String homeMainCategoryId = 'home_main';
  static const String homeCenterCategoryId = 'home_center';
  static const String homeRightCategoryId = 'home_right';
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

  Pictogram? getPictogramById(String id) {
    if (!_isLoaded) {
      throw StateError(
        'PictogramRepository debe cargarse con load() antes de usarse.',
      );
    }

    for (final pictogram in _pictograms) {
      if (pictogram.id == id) {
        return pictogram;
      }
    }

    return null;
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

  List<Pictogram> getPictogramsByCategories(Set<String> categoryIds) {
    if (!_isLoaded) {
      throw StateError(
        'PictogramRepository debe cargarse con load() antes de usarse.',
      );
    }

    return _pictograms
        .where((pictogram) => categoryIds.contains(pictogram.categoryId))
        .toList();
  }
}
