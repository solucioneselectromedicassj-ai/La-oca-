import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../utils/tone_wav.dart';

/// Sonido: mismo diseño del prototipo HTML (Web Audio API, osciladores,
/// sin archivos externos) — acá los tonos se generan como WAV en memoria
/// (`ToneWav`) y se reproducen con un pool chico de `AudioPlayer` en modo
/// de baja latencia, para que los sonidos cortos y superpuestos (tick de
/// caminata, doble beep de acierto, etc.) no se pisen entre sí.
class AudioService {
  AudioService._();

  static bool enabled = true;

  static final Map<String, Uint8List> _cache = {};
  static final List<AudioPlayer> _pool = List.generate(6, (_) {
    final p = AudioPlayer(playerId: 'ocaland_tone_${DateTime.now().microsecondsSinceEpoch}_${_counter++}');
    p.setPlayerMode(PlayerMode.lowLatency);
    return p;
  });
  static int _counter = 0;
  static int _poolIdx = 0;

  static Uint8List _toneBytes(double freq, double duration, String type, double vol) {
    final key = '$freq|$duration|$type|$vol';
    return _cache.putIfAbsent(key, () => ToneWav.generate(freq: freq, durationSec: duration, type: type, volume: vol));
  }

  static void _play(double freq, double duration, {String type = 'sine', double vol = 0.1}) {
    if (!enabled) return;
    try {
      final bytes = _toneBytes(freq, duration, type, vol);
      final player = _pool[_poolIdx];
      _poolIdx = (_poolIdx + 1) % _pool.length;
      player.play(BytesSource(bytes, mimeType: 'audio/wav'));
    } catch (_) {
      // sin audio disponible (headless, permiso denegado, etc.): el juego sigue igual sin sonido
    }
  }

  static void tick() => _play(440, 0.07, type: 'square', vol: 0.05);

  static void diceRoll() => _play(300, 0.15, type: 'triangle', vol: 0.07);

  static void correct() {
    _play(660, 0.12, vol: 0.12);
    Future.delayed(const Duration(milliseconds: 110), () => _play(880, 0.15, vol: 0.12));
  }

  static void wrong() => _play(180, 0.25, type: 'sawtooth', vol: 0.09);

  static void suffer() => _play(150, 0.3, type: 'sawtooth', vol: 0.11);

  static void win() {
    _play(523, 0.12);
    Future.delayed(const Duration(milliseconds: 120), () => _play(659, 0.12));
    Future.delayed(const Duration(milliseconds: 240), () => _play(784, 0.22));
  }

  static void coin() {
    _play(988, 0.08, type: 'square', vol: 0.08);
    Future.delayed(const Duration(milliseconds: 80), () => _play(1319, 0.12, type: 'square', vol: 0.08));
  }

  static void sorteo() => _play(220, 0.06, type: 'square', vol: 0.05);

  static void notificacion() {
    _play(740, 0.1, vol: 0.08);
    Future.delayed(const Duration(milliseconds: 100), () => _play(988, 0.14, vol: 0.08));
  }
}
