import 'dart:math';
import 'dart:typed_data';

/// Genera una melodía corta como un único WAV PCM de 16 bits en memoria,
/// para usar como música de fondo en loop (`ReleaseMode.loop`). A
/// diferencia de [ToneWav] (un solo tono con decaimiento exponencial tipo
/// "beep"), acá cada nota tiene ataque/sostén/relajación suaves para que
/// suene más como una melodía y no se escuchen clicks entre nota y nota.
class MelodyWav {
  MelodyWav._();

  static const int sampleRate = 44100;

  /// [notas]: lista de (frecuencia en Hz, duración en segundos). Una
  /// frecuencia de 0 es un silencio (para separar frases).
  static Uint8List generate(List<(double, double)> notas, {String type = 'triangle', double volume = 0.08}) {
    final totalSamples = notas.fold<int>(0, (acc, n) => acc + max(1, (sampleRate * n.$2).round()));
    final samples = Int16List(totalSamples);
    var offset = 0;
    for (final nota in notas) {
      final (freq, duracion) = nota;
      final numSamples = max(1, (sampleRate * duracion).round());
      final attack = (numSamples * 0.08).round();
      final release = (numSamples * 0.18).round();
      for (var i = 0; i < numSamples; i++) {
        if (freq <= 0) {
          samples[offset + i] = 0;
          continue;
        }
        final t = i / sampleRate;
        final wave = _waveAt(type, freq, t);
        double env;
        if (i < attack) {
          env = i / attack;
        } else if (i > numSamples - release) {
          env = (numSamples - i) / release;
        } else {
          env = 1.0;
        }
        final sample = (wave * volume * env).clamp(-1.0, 1.0);
        samples[offset + i] = (sample * 32767).round();
      }
      offset += numSamples;
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
