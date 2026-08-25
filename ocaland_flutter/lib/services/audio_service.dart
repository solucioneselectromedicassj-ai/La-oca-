import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../utils/melody_wav.dart';
import '../utils/tone_wav.dart';
import 'preferencias_service.dart';

/// Sonido: mismo diseño del prototipo HTML (Web Audio API, osciladores,
/// sin archivos externos) — acá los tonos se generan como WAV en memoria
/// (`ToneWav`) y se reproducen con un pool chico de `AudioPlayer` en modo
/// de baja latencia, para que los sonidos cortos y superpuestos (tick de
/// caminata, doble beep de acierto, etc.) no se pisen entre sí.
class AudioService {
  AudioService._();

  static bool enabled = true;

  /// Carga la preferencia guardada (si el usuario ya silenció antes) —
  /// se llama una vez al arrancar la app.
  static Future<void> cargarPreferencia() async {
    final v = await PreferenciasService.obtenerSonidoActivado();
    if (v != null) enabled = v;
  }

  /// Botón de silenciar del juego: guarda la preferencia y corta/retoma
  /// la música si hay una partida en curso (no vuelve a arrancarla si no
  /// se le pide explícitamente, para no reactivar música en pantallas
  /// donde no corresponde).
  static Future<void> alternarSonido({bool enJuego = false}) async {
    enabled = !enabled;
    await PreferenciasService.guardarSonidoActivado(enabled);
    if (!enabled) {
      await detenerMusica();
    } else if (enJuego) {
      await iniciarMusica();
    }
  }

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

  /// Paso al caminar por el tablero — más presente que antes (más largo,
  /// más fuerte y con una onda más cálida) para que se note bien la
  /// caminata casilla por casilla.
  static void tick() => _play(640, 0.07, type: 'triangle', vol: 0.11);

  static void diceRoll() => _play(300, 0.15, type: 'triangle', vol: 0.07);

  static void correct() {
    _play(660, 0.12, vol: 0.12);
    Future.delayed(const Duration(milliseconds: 110), () => _play(880, 0.15, vol: 0.12));
  }

  static void wrong() => _play(180, 0.25, type: 'sawtooth', vol: 0.09);

  static void suffer() => _play(150, 0.3, type: 'sawtooth', vol: 0.11);

  /// Golpe de caída + "womp womp" burlón — al caer en cárcel o calavera,
  /// antes incluso de mostrar la trivia (distinto del sonido de
  /// [wrong]/[suffer], que es por fallar la pregunta). El golpe grave del
  /// principio marca la caída en sí; el "womp womp" que sigue es la burla.
  static void trampa() {
    _play(90, 0.15, type: 'sawtooth', vol: 0.15);
    Future.delayed(const Duration(milliseconds: 100), () => _play(392, 0.12, type: 'sawtooth', vol: 0.1));
    Future.delayed(const Duration(milliseconds: 210), () => _play(330, 0.12, type: 'sawtooth', vol: 0.1));
    Future.delayed(const Duration(milliseconds: 320), () => _play(262, 0.24, type: 'sawtooth', vol: 0.11));
  }

  static void win() {
    _play(523, 0.12);
    Future.delayed(const Duration(milliseconds: 120), () => _play(659, 0.12));
    Future.delayed(const Duration(milliseconds: 240), () => _play(784, 0.22));
  }

  static void coin() {
    _play(988, 0.08, type: 'square', vol: 0.08);
    Future.delayed(const Duration(milliseconds: 80), () => _play(1319, 0.12, type: 'square', vol: 0.08));
  }

  /// Distinto del de moneda: un golpe de "sellado" seguido de un brillo,
  /// para cuando se gana un sello (casilla de suerte, tanda de bonus,
  /// canje en el perfil) — así no suena igual que ganar monedas.
  static void sello() {
    _play(300, 0.07, type: 'triangle', vol: 0.11);
    Future.delayed(const Duration(milliseconds: 90), () => _play(784, 0.1, vol: 0.1));
    Future.delayed(const Duration(milliseconds: 170), () => _play(988, 0.16, vol: 0.11));
  }

  static void sorteo() => _play(220, 0.06, type: 'square', vol: 0.05);

  /// Sonido tierno para las interacciones con la mascota (darle de comer,
  /// despertarla) — un par de tonos cortos y suaves, distinto de [coin] y
  /// [sello] para no confundirse con ganar algo.
  static void carino() {
    _play(523, 0.09, type: 'triangle', vol: 0.09);
    Future.delayed(const Duration(milliseconds: 100), () => _play(659, 0.13, type: 'triangle', vol: 0.09));
  }

  static void notificacion() {
    _play(740, 0.1, vol: 0.08);
    Future.delayed(const Duration(milliseconds: 100), () => _play(988, 0.14, vol: 0.08));
  }

  /// Graznido alegre — dos "honk" cortos y ascendentes. Se usa cuando la
  /// Oca pasa a un ánimo contento y al caer en una casilla de oca.
  static void graznidoAlegre() {
    _play(520, 0.09, type: 'sawtooth', vol: 0.13);
    Future.delayed(const Duration(milliseconds: 90), () => _play(640, 0.12, type: 'sawtooth', vol: 0.13));
  }

  /// Graznido triste — un solo "honk" más grave y apagado, para cuando la
  /// Oca pasa a un ánimo de hambre o aburrimiento.
  static void graznidoTriste() {
    _play(340, 0.14, type: 'sawtooth', vol: 0.1);
    Future.delayed(const Duration(milliseconds: 120), () => _play(260, 0.18, type: 'sawtooth', vol: 0.09));
  }

  // ---------------------------------------------------------------------
  // Música de fondo — una melodía corta generada en memoria (igual que los
  // efectos, sin archivos de audio), en loop mientras se está jugando una
  // partida. Usa un reproductor propio, separado del pool de efectos, para
  // no pisarse con los sonidos cortos que suenan encima.
  // ---------------------------------------------------------------------
  static Uint8List? _musicaBytes;
  static AudioPlayer? _musicaPlayer;

  /// Melodía principal con ritmo "swing" (corta-larga) en vez de notas
  /// todas iguales — eso, más la línea de bajo de abajo sonando a la vez,
  /// es lo que le saca el aire de secuencia de beeps robótica y lo acerca
  /// a algo con más rebote, tipo circo/carnaval.
  static const List<(double, double)> _melodiaPrincipal = [
    (261.63, 0.30), (329.63, 0.18), (392.00, 0.30), (523.25, 0.18),
    (392.00, 0.30), (329.63, 0.18), (349.23, 0.30), (440.00, 0.18),
    (523.25, 0.30), (440.00, 0.18), (349.23, 0.30), (293.66, 0.18),
    (392.00, 0.30), (493.88, 0.18), (587.33, 0.30), (392.00, 0.34),
  ];

  /// Línea de bajo: progresión I-V-vi-IV-I-V-IV-I en Do mayor, una nota
  /// por cada par de la melodía principal (misma duración total).
  static const List<(double, double)> _melodiaBajo = [
    (130.81, 0.48), (196.00, 0.48), (220.00, 0.48), (174.61, 0.48),
    (130.81, 0.48), (196.00, 0.48), (174.61, 0.48), (130.81, 0.64),
  ];

  static Future<void> iniciarMusica() async {
    if (!enabled) return;
    try {
      _musicaBytes ??= MelodyWav.generateMulti(
        [_melodiaPrincipal, _melodiaBajo],
        types: ['triangle', 'triangle'],
        volumes: [0.055, 0.045],
      );
      final player = _musicaPlayer ??= AudioPlayer(playerId: 'ocaland_musica');
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(BytesSource(_musicaBytes!, mimeType: 'audio/wav'));
    } catch (_) {
      // sin audio disponible: la partida sigue igual, solo sin música
    }
  }

  static Future<void> detenerMusica() async {
    try {
      await _musicaPlayer?.stop();
    } catch (_) {}
  }
}
