import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;
  const durationSeconds = 0.28;
  const frequencyStart = 420.0;
  const frequencyEnd = 220.0;
  const volume = 0.35;

  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = Int16List(totalSamples);

  for (var i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;

    final progress = i / totalSamples;
    final frequency =
        frequencyStart + ((frequencyEnd - frequencyStart) * progress);

    final envelope = _envelope(progress);

    final value = sin(2 * pi * frequency * t) * volume * envelope;

    samples[i] = (value * 32767).round();
  }

  final wavBytes = _createWavBytes(samples: samples, sampleRate: sampleRate);

  final outputDirectory = Directory('assets/audio');

  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync(recursive: true);
  }

  final outputFile = File('assets/audio/error_suave.wav');
  outputFile.writeAsBytesSync(wavBytes);

  // print('Archivo creado correctamente: ${outputFile.path}');
  // print('Tamaño: ${outputFile.lengthSync()} bytes');
}

double _envelope(double progress) {
  if (progress < 0.02) {
    return progress / 0.02;
  }

  if (progress > 0.70) {
    return (1 - progress) / 0.30;
  }

  return 1;
}

Uint8List _createWavBytes({
  required Int16List samples,
  required int sampleRate,
}) {
  const channels = 1;
  const bitsPerSample = 16;
  const bytesPerSample = bitsPerSample ~/ 8;
  const audioFormatPcm = 1;

  final byteRate = sampleRate * channels * bytesPerSample;
  final blockAlign = channels * bytesPerSample;
  final dataSize = samples.length * bytesPerSample;
  final fileSize = 36 + dataSize;

  final bytes = BytesBuilder();

  void writeString(String value) {
    bytes.add(value.codeUnits);
  }

  void writeUint16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    bytes.add(data.buffer.asUint8List());
  }

  void writeUint32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    bytes.add(data.buffer.asUint8List());
  }

  writeString('RIFF');
  writeUint32(fileSize);
  writeString('WAVE');

  writeString('fmt ');
  writeUint32(16);
  writeUint16(audioFormatPcm);
  writeUint16(channels);
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(blockAlign);
  writeUint16(bitsPerSample);

  writeString('data');
  writeUint32(dataSize);

  final sampleBytes = ByteData(dataSize);

  for (var i = 0; i < samples.length; i++) {
    sampleBytes.setInt16(i * 2, samples[i], Endian.little);
  }

  bytes.add(sampleBytes.buffer.asUint8List());

  return bytes.toBytes();
}
