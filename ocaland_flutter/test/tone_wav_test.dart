import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/utils/tone_wav.dart';

void main() {
  group('ToneWav', () {
    test('genera un WAV bien formado (RIFF/WAVE, PCM 16 bits mono)', () {
      final bytes = ToneWav.generate(freq: 440, durationSec: 0.1, type: 'sine', volume: 0.1);
      final data = bytes.buffer.asByteData();

      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');

      expect(data.getUint16(20, Endian.little), 1); // PCM
      expect(data.getUint16(22, Endian.little), 1); // mono
      expect(data.getUint32(24, Endian.little), ToneWav.sampleRate);
      expect(data.getUint16(34, Endian.little), 16); // bits per sample

      final expectedSamples = (ToneWav.sampleRate * 0.1).round();
      final dataLength = data.getUint32(40, Endian.little);
      expect(dataLength, expectedSamples * 2);
      expect(bytes.length, 44 + dataLength);
    });

    test('la envolvente decae: el final del tono es más suave que el principio', () {
      final bytes = ToneWav.generate(freq: 440, durationSec: 0.2, type: 'sine', volume: 0.2);
      final data = bytes.buffer.asByteData();
      final numSamples = (bytes.length - 44) ~/ 2;

      int peakAbsIn(int fromSample, int toSample) {
        var peak = 0;
        for (var i = fromSample; i < toSample; i++) {
          final v = data.getInt16(44 + i * 2, Endian.little).abs();
          if (v > peak) peak = v;
        }
        return peak;
      }

      final peakStart = peakAbsIn(0, numSamples ~/ 10);
      final peakEnd = peakAbsIn(numSamples - numSamples ~/ 10, numSamples);
      expect(peakEnd, lessThan(peakStart));
    });

    test('cada tipo de onda produce una forma distinta (no todas iguales)', () {
      final sine = ToneWav.generate(freq: 440, durationSec: 0.05, type: 'sine', volume: 0.5);
      final square = ToneWav.generate(freq: 440, durationSec: 0.05, type: 'square', volume: 0.5);
      final sawtooth = ToneWav.generate(freq: 440, durationSec: 0.05, type: 'sawtooth', volume: 0.5);
      final triangle = ToneWav.generate(freq: 440, durationSec: 0.05, type: 'triangle', volume: 0.5);

      expect(sine, isNot(equals(square)));
      expect(square, isNot(equals(sawtooth)));
      expect(sawtooth, isNot(equals(triangle)));
    });
  });
}
