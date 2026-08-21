import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/utils/melody_wav.dart';

void main() {
  group('MelodyWav', () {
    test('genera un WAV bien formado (RIFF/WAVE, PCM 16 bits mono) con la duración total de las notas', () {
      final notas = [(440.0, 0.1), (523.25, 0.1)];
      final bytes = MelodyWav.generate(notas, type: 'sine', volume: 0.1);
      final data = bytes.buffer.asByteData();

      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
      expect(data.getUint16(20, Endian.little), 1); // PCM
      expect(data.getUint16(22, Endian.little), 1); // mono
      expect(data.getUint32(24, Endian.little), MelodyWav.sampleRate);

      final expectedSamples = notas.fold<int>(0, (acc, n) => acc + (MelodyWav.sampleRate * n.$2).round());
      final dataLength = data.getUint32(40, Endian.little);
      expect(dataLength, expectedSamples * 2);
      expect(bytes.length, 44 + dataLength);
    });

    test('un silencio (frecuencia 0) genera samples en cero', () {
      final bytes = MelodyWav.generate([(0.0, 0.05)], volume: 0.5);
      final data = bytes.buffer.asByteData();
      final numSamples = (bytes.length - 44) ~/ 2;
      for (var i = 0; i < numSamples; i++) {
        expect(data.getInt16(44 + i * 2, Endian.little), 0);
      }
    });

    test('generateMulti mezcla varias voces en un WAV bien formado, del largo de la voz más larga', () {
      final voz1 = [(440.0, 0.1)];
      final voz2 = [(220.0, 0.05)]; // más corta que voz1
      final bytes = MelodyWav.generateMulti([voz1, voz2], types: ['sine', 'sine'], volumes: [0.1, 0.1]);
      final data = bytes.buffer.asByteData();

      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      final dataLength = data.getUint32(40, Endian.little);
      final expectedSamples = (MelodyWav.sampleRate * 0.1).round(); // el largo de la voz más larga
      expect(dataLength, expectedSamples * 2);
    });

    test('no hay clicks entre notas: cada nota empieza y termina cerca de cero (ataque/relajación suaves)', () {
      final bytes = MelodyWav.generate([(440.0, 0.05)], type: 'sine', volume: 0.5);
      final data = bytes.buffer.asByteData();
      final numSamples = (bytes.length - 44) ~/ 2;

      final primero = data.getInt16(44, Endian.little).abs();
      final ultimo = data.getInt16(44 + (numSamples - 1) * 2, Endian.little).abs();
      // El primer y último sample deben estar cerca de silencio (ataque/relajación en 0),
      // muy por debajo del pico de la nota (que con volumen 0.5 ronda 16000).
      expect(primero, lessThan(3000));
      expect(ultimo, lessThan(3000));
    });
  });
}
