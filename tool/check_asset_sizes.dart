import 'dart:io';

const String assetsRootPath = 'assets';

const Set<String> imageExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
};

const Set<String> audioExtensions = {
  '.mp3',
  '.m4a',
  '.aac',
  '.ogg',
  '.wav',
};

const int imageWarningBytes = 150 * 1024; // 150 KB
const int imageCriticalBytes = 500 * 1024; // 500 KB

const int audioWarningBytes = 5 * 1024 * 1024; // 5 MB
const int audioCriticalBytes = 15 * 1024 * 1024; // 15 MB

const int totalAssetsWarningBytes = 150 * 1024 * 1024; // 150 MB
const int totalAssetsCriticalBytes = 300 * 1024 * 1024; // 300 MB

const int topFilesLimit = 15;

void main() {
  final assetsDirectory = Directory(assetsRootPath);

  if (!assetsDirectory.existsSync()) {
    stderr.writeln('ERROR: No existe la carpeta "$assetsRootPath".');
    exitCode = 1;
    return;
  }

  final files = _getAssetFiles(assetsDirectory);

  final imageFiles = files.where((file) {
    return imageExtensions.contains(_getFileExtension(file.path));
  }).toList();

  final audioFiles = files.where((file) {
    return audioExtensions.contains(_getFileExtension(file.path));
  }).toList();

  final otherFiles = files.where((file) {
    final extension = _getFileExtension(file.path);

    return !imageExtensions.contains(extension) &&
        !audioExtensions.contains(extension);
  }).toList();

  final totalImagesBytes = _sumFileSizes(imageFiles);
  final totalAudioBytes = _sumFileSizes(audioFiles);
  final totalOtherBytes = _sumFileSizes(otherFiles);
  final totalAssetsBytes = totalImagesBytes + totalAudioBytes + totalOtherBytes;

  final warnings = <String>[];
  final criticals = <String>[];

  _collectImageWarnings(
    imageFiles: imageFiles,
    warnings: warnings,
    criticals: criticals,
  );

  _collectAudioWarnings(
    audioFiles: audioFiles,
    warnings: warnings,
    criticals: criticals,
  );

  _collectTotalWarnings(
    totalAssetsBytes: totalAssetsBytes,
    warnings: warnings,
    criticals: criticals,
  );

  _printHeader('Resumen de assets');

  _printSummaryLine(
    label: 'Imágenes',
    fileCount: imageFiles.length,
    bytes: totalImagesBytes,
  );

  _printSummaryLine(
    label: 'Audio',
    fileCount: audioFiles.length,
    bytes: totalAudioBytes,
  );

  _printSummaryLine(
    label: 'Otros assets',
    fileCount: otherFiles.length,
    bytes: totalOtherBytes,
  );

  stdout.writeln('');
  stdout.writeln('Total assets: ${_formatBytes(totalAssetsBytes)}');

  _printTopFiles(
    title: 'Imágenes más pesadas',
    files: imageFiles,
  );

  _printTopFiles(
    title: 'Audios más pesados',
    files: audioFiles,
  );

  _printTopFiles(
    title: 'Otros assets más pesados',
    files: otherFiles,
  );

  _printWarnings(
    warnings: warnings,
    criticals: criticals,
  );

  if (criticals.isNotEmpty) {
    exitCode = 1;
  }
}

List<File> _getAssetFiles(Directory directory) {
  final files = <File>[];

  final entities = directory.listSync(
    recursive: true,
    followLinks: false,
  );

  for (final entity in entities) {
    if (entity is! File) {
      continue;
    }

    final normalizedPath = _normalizePath(entity.path);

    if (_shouldIgnoreFile(normalizedPath)) {
      continue;
    }

    files.add(entity);
  }

  files.sort((a, b) => _normalizePath(a.path).compareTo(_normalizePath(b.path)));

  return files;
}

bool _shouldIgnoreFile(String path) {
  final fileName = path.split('/').last;

  if (fileName.startsWith('.')) {
    return true;
  }

  if (fileName == '.DS_Store') {
    return true;
  }

  if (fileName == 'Thumbs.db') {
    return true;
  }

  return false;
}

void _collectImageWarnings({
  required List<File> imageFiles,
  required List<String> warnings,
  required List<String> criticals,
}) {
  for (final file in imageFiles) {
    final bytes = file.lengthSync();
    final path = _normalizePath(file.path);

    if (bytes >= imageCriticalBytes) {
      criticals.add(
        'Imagen crítica: $path · ${_formatBytes(bytes)}. '
        'Intenta bajarla a menos de ${_formatBytes(imageWarningBytes)}.',
      );
      continue;
    }

    if (bytes >= imageWarningBytes) {
      warnings.add(
        'Imagen pesada: $path · ${_formatBytes(bytes)}. '
        'Revisa si puedes comprimirla.',
      );
    }
  }
}

void _collectAudioWarnings({
  required List<File> audioFiles,
  required List<String> warnings,
  required List<String> criticals,
}) {
  for (final file in audioFiles) {
    final bytes = file.lengthSync();
    final path = _normalizePath(file.path);

    if (bytes >= audioCriticalBytes) {
      criticals.add(
        'Audio crítico: $path · ${_formatBytes(bytes)}. '
        'Intenta bajarlo a menos de ${_formatBytes(audioWarningBytes)}.',
      );
      continue;
    }

    if (bytes >= audioWarningBytes) {
      warnings.add(
        'Audio pesado: $path · ${_formatBytes(bytes)}. '
        'Revisa duración, bitrate o compresión.',
      );
    }
  }
}

void _collectTotalWarnings({
  required int totalAssetsBytes,
  required List<String> warnings,
  required List<String> criticals,
}) {
  if (totalAssetsBytes >= totalAssetsCriticalBytes) {
    criticals.add(
      'Total de assets crítico: ${_formatBytes(totalAssetsBytes)}. '
      'Considera packs descargables o reducir assets internos.',
    );
    return;
  }

  if (totalAssetsBytes >= totalAssetsWarningBytes) {
    warnings.add(
      'Total de assets alto: ${_formatBytes(totalAssetsBytes)}. '
      'Conviene revisar imágenes, audios y contenido base.',
    );
  }
}

void _printHeader(String title) {
  stdout.writeln('');
  stdout.writeln('============================================================');
  stdout.writeln(title);
  stdout.writeln('============================================================');
}

void _printSummaryLine({
  required String label,
  required int fileCount,
  required int bytes,
}) {
  stdout.writeln(
    '- $label: $fileCount archivos · ${_formatBytes(bytes)}',
  );
}

void _printTopFiles({
  required String title,
  required List<File> files,
}) {
  if (files.isEmpty) {
    return;
  }

  final sortedFiles = [...files];

  sortedFiles.sort((a, b) {
    return b.lengthSync().compareTo(a.lengthSync());
  });

  final visibleFiles = sortedFiles.take(topFilesLimit).toList();

  _printHeader(title);

  for (var index = 0; index < visibleFiles.length; index++) {
    final file = visibleFiles[index];
    final position = index + 1;

    stdout.writeln(
      '$position. ${_normalizePath(file.path)} · ${_formatBytes(file.lengthSync())}',
    );
  }
}

void _printWarnings({
  required List<String> warnings,
  required List<String> criticals,
}) {
  _printHeader('Avisos');

  if (warnings.isEmpty && criticals.isEmpty) {
    stdout.writeln('No hay avisos de peso.');
    return;
  }

  if (criticals.isNotEmpty) {
    stdout.writeln('Críticos:');
    for (final critical in criticals) {
      stdout.writeln('- $critical');
    }
    stdout.writeln('');
  }

  if (warnings.isNotEmpty) {
    stdout.writeln('Advertencias:');
    for (final warning in warnings) {
      stdout.writeln('- $warning');
    }
  }
}

int _sumFileSizes(List<File> files) {
  var totalBytes = 0;

  for (final file in files) {
    totalBytes += file.lengthSync();
  }

  return totalBytes;
}

String _getFileExtension(String path) {
  final normalizedPath = _normalizePath(path);
  final fileName = normalizedPath.split('/').last;
  final dotIndex = fileName.lastIndexOf('.');

  if (dotIndex == -1) {
    return '';
  }

  return fileName.substring(dotIndex).toLowerCase();
}

String _normalizePath(String path) {
  return path.replaceAll('\\', '/');
}

String _formatBytes(int bytes) {
  const int kb = 1024;
  const int mb = 1024 * 1024;
  const int gb = 1024 * 1024 * 1024;

  if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(2)} GB';
  }

  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(2)} MB';
  }

  if (bytes >= kb) {
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  return '$bytes B';
}