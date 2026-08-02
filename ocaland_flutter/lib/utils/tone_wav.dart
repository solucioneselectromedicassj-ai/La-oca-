import 'dart:math';
import 'dart:typed_data';

/// Genera un tono corto como WAV PCM de 16 bits en memoria — el equivalente
/// en Flutter al `beep()` del prototipo (osciladores de Web Audio API), sin
/// necesitar ningún archivo de audio como asset.
class ToneWav {
  ToneWav._();

  static const int sampleRate = 44100;
  static const double _minAmp = 0.001;

  /// [type] es una de: 'sine' (default), 'square', 'sawtooth', 'triangle'.
  static Uint8List generate({
    required double freq,
    required double durationSec,
    String type = 'sine',
    double volume = 0.1,
  }) {
    final numSamples = max(1, (sampleRate * durationSec).round());
    final samples = Int16List(numSamples);
    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final wave = _waveAt(type, freq, t);
      final progress = (durationSec > 0 ? t / durationSec : 1.0).clamp(0.0, 1.0);
      // Réplica de gain.exponentialRampToValueAtTime(0.001, duration) de Web Audio.
      final envelope = volume * pow(_minAmp / volume, progress);
      final sample = (wave * envelope).clamp(-1.0, 1.0);
      samples[i] = (sample * 32767).round();
    }
    return _wavBytes(samples);
  }

  static double _waveAt(String type, double freq, double t) {
    switch (type) {
      case 'square':
        return sin(2 * pi * freq * t) >= 0 ? 1.0 : -1.0;
      case 'sawtooth':
        final phase = (freq * t) % 1.0;
        return 2 * phase - 1;
      case 'triangle':
        return (2 / pi) * asin(sin(2 * pi * freq * t));
      default:
        return sin(2 * pi * freq * t);
    }
  }

  static Uint8List _wavBytes(Int16List samples) {
    final dataLength = samples.length * 2;
    final bytes = ByteData(44 + dataLength);
    void writeAscii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample
    writeAscii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}
