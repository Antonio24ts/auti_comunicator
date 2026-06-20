import 'dart:convert';
import 'dart:io';

void main() {
  const pictogramsPath = 'assets/data/pictograms.json';
  const assetsRoot = 'assets';

  final errors = <String>[];
  final warnings = <String>[];

  final pictogramsFile = File(pictogramsPath);

  if (!pictogramsFile.existsSync()) {
    _printError('No existe el archivo $pictogramsPath');
    exit(1);
  }

  final List<dynamic> rawJson;

  try {
    final content = pictogramsFile.readAsStringSync();
    rawJson = jsonDecode(content) as List<dynamic>;
  } catch (error) {
    _printError('El JSON no es válido: $error');
    exit(1);
  }

  final pictograms = <Map<String, dynamic>>[];

  for (var i = 0; i < rawJson.length; i++) {
    final item = rawJson[i];

    if (item is! Map<String, dynamic>) {
      errors.add('Elemento en posición $i no es un objeto JSON válido.');
      continue;
    }

    pictograms.add(item);
  }

  final ids = <String>{};
  final duplicatedIds = <String>{};

  final categoryIds = <String>{};
  final targetCategoryIds = <String>{};

  final usedImagePaths = <String>{};

  for (final pictogram in pictograms) {
    final id = _readString(pictogram, 'id');
    final text = _readString(pictogram, 'text');
    final imagePath = _readString(pictogram, 'imagePath', required: false);
    final categoryId = _readString(pictogram, 'categoryId');
    final type = _readString(pictogram, 'type');
    final targetCategoryId = _readString(
      pictogram,
      'targetCategoryId',
      required: false,
    );
    final categoryOpenMode = _readString(
      pictogram,
      'categoryOpenMode',
      required: false,
    );
    final keyboardAction = _readString(
      pictogram,
      'keyboardAction',
      required: false,
    );

    if (id == null || id.isEmpty) {
      errors.add('Hay un pictograma sin "id". Texto: ${text ?? 'sin texto'}');
    } else {
      if (ids.contains(id)) {
        duplicatedIds.add(id);
      }

      ids.add(id);
    }

    if (text == null || text.trim().isEmpty) {
      errors.add('El pictograma "$id" no tiene "text" válido.');
    }

    if (categoryId == null || categoryId.trim().isEmpty) {
      errors.add('El pictograma "$id" no tiene "categoryId" válido.');
    } else {
      categoryIds.add(categoryId);
    }

    if (type == null || type.trim().isEmpty) {
      errors.add('El pictograma "$id" no tiene "type" válido.');
    } else if (!_isValidType(type)) {
      errors.add('El pictograma "$id" tiene type no válido: "$type".');
    }

    if (type == 'category') {
      if (targetCategoryId == null || targetCategoryId.trim().isEmpty) {
        errors.add(
          'El pictograma categoría "$id" no tiene "targetCategoryId".',
        );
      } else {
        targetCategoryIds.add(targetCategoryId);
      }
    }

    if (type == 'keyboardAction') {
      if (keyboardAction == null || keyboardAction.trim().isEmpty) {
        errors.add(
          'El pictograma "$id" es keyboardAction pero no tiene "keyboardAction".',
        );
      } else if (!_isValidKeyboardAction(keyboardAction)) {
        errors.add(
          'El pictograma "$id" tiene keyboardAction no válido: "$keyboardAction".',
        );
      }
    }

    if (categoryOpenMode != null &&
        categoryOpenMode.isNotEmpty &&
        !_isValidCategoryOpenMode(categoryOpenMode)) {
      errors.add(
        'El pictograma "$id" tiene categoryOpenMode no válido: "$categoryOpenMode".',
      );
    }

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      usedImagePaths.add(imagePath);

      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        errors.add('Imagen no encontrada en "$id": $imagePath');
      }
    }
  }

  if (duplicatedIds.isNotEmpty) {
    for (final id in duplicatedIds) {
      errors.add('ID duplicado: "$id".');
    }
  }

  for (final targetCategoryId in targetCategoryIds) {
    final hasAnyPictogramInTarget = categoryIds.contains(targetCategoryId);

    if (!hasAnyPictogramInTarget) {
      warnings.add(
        'La categoría "$targetCategoryId" está enlazada, pero no tiene pictogramas.',
      );
    }
  }

  final unusedImages = _findUnusedImages(
    assetsRoot: assetsRoot,
    usedImagePaths: usedImagePaths,
  );

  if (unusedImages.isNotEmpty) {
    warnings.add(
      'Hay ${unusedImages.length} imagen/es en assets que no se usan en el JSON.',
    );

    for (final image in unusedImages.take(20)) {
      warnings.add('Imagen no usada: $image');
    }

    if (unusedImages.length > 20) {
      warnings.add(
        '... y ${unusedImages.length - 20} imagen/es no usadas más.',
      );
    }
  }

  _printSummary(
    pictogramCount: pictograms.length,
    categoryCount: categoryIds.length,
    imageCount: usedImagePaths.length,
    errors: errors,
    warnings: warnings,
  );

  if (errors.isNotEmpty) {
    exit(1);
  }
}

String? _readString(
  Map<String, dynamic> json,
  String key, {
  bool required = true,
}) {
  final value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String) {
    return null;
  }

  return value.trim();
}

bool _isValidType(String type) {
  return type == 'word' ||
      type == 'category' ||
      type == 'letter' ||
      type == 'keyboardAction';
}

bool _isValidKeyboardAction(String action) {
  return action == 'space' || action == 'deleteLetter';
}

bool _isValidCategoryOpenMode(String mode) {
  return mode == 'zone' || mode == 'fullBoard';
}

List<String> _findUnusedImages({
  required String assetsRoot,
  required Set<String> usedImagePaths,
}) {
  final root = Directory(assetsRoot);

  if (!root.existsSync()) {
    return [];
  }

  final imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
  };

  final allImages = root
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll('\\', '/'))
      .where((path) {
        final lowerPath = path.toLowerCase();

        return imageExtensions.any(lowerPath.endsWith);
      })
      .where((path) => !path.contains('/audio/'))
      .toList()
    ..sort();

  return allImages.where((path) => !usedImagePaths.contains(path)).toList();
}

void _printSummary({
  required int pictogramCount,
  required int categoryCount,
  required int imageCount,
  required List<String> errors,
  required List<String> warnings,
}) {
  stdout.writeln('');
  stdout.writeln('==============================');
  stdout.writeln(' Validación de pictogramas');
  stdout.writeln('==============================');
  stdout.writeln('');
  stdout.writeln('Pictogramas: $pictogramCount');
  stdout.writeln('Categorías detectadas: $categoryCount');
  stdout.writeln('Imágenes usadas en JSON: $imageCount');
  stdout.writeln('');

  if (errors.isEmpty && warnings.isEmpty) {
    stdout.writeln('✅ Todo correcto.');
    stdout.writeln('');
    return;
  }

  if (warnings.isNotEmpty) {
    stdout.writeln('⚠️ Warnings:');
    for (final warning in warnings) {
      stdout.writeln('- $warning');
    }
    stdout.writeln('');
  }

  if (errors.isNotEmpty) {
    stdout.writeln('❌ Errores:');
    for (final error in errors) {
      stdout.writeln('- $error');
    }
    stdout.writeln('');
    stdout.writeln('Validación fallida.');
    stdout.writeln('');
    return;
  }

  stdout.writeln('✅ Validación completada sin errores.');
  stdout.writeln('');
}

void _printError(String message) {
  stderr.writeln('');
  stderr.writeln('❌ $message');
  stderr.writeln('');
}