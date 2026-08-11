import 'package:shared_preferences/shared_preferences.dart';
import 'mensajes_service.dart';

/// Estado de la Oca-mascota en un momento dado. Las tres necesidades van de
/// 0 a 100; [durmiendo] indica si está en modo descanso (el sueño sube en
/// vez de bajar mientras tanto). [secuestrada] indica si el cazador se la
/// llevó por descuido — mientras esté así, las barras quedan congeladas.
class EstadoMascota {
  final double hambre;
  final double sueno;
  final double diversion;
  final bool durmiendo;
  final bool secuestrada;
  const EstadoMascota({required this.hambre, required this.sueno, required this.diversion, required this.durmiendo, this.secuestrada = false});
}

/// Mascota virtual (la Oca) — mecánica de enganche diario, no bloqueante.
/// Las tres barras (hambre, sueño, diversión) se calculan en base al tiempo
/// real transcurrido desde la última vez que se consultaron (igual que en
/// Pou): no hace falta ningún timer corriendo en segundo plano, alcanza con
/// "poner al día" el estado cada vez que se lee.
///
/// Las barras en sí se guardan localmente por dispositivo (mismo criterio
/// que sellos y comodines), pero el aviso de que el cazador se la llevó
/// necesita llegar aunque no tengas la app abierta en ese momento — por eso
/// ese aviso puntual sí se escribe en el buzón de Supabase (`mensajes`).
class MascotaService {
  MascotaService._();

  static const _kHambre = 'mascota_hambre';
  static const _kSueno = 'mascota_sueno';
  static const _kDiversion = 'mascota_diversion';
  static const _kDurmiendo = 'mascota_durmiendo';
  static const _kSecuestrada = 'mascota_secuestrada';
  static const _kCeroDesdeMs = 'mascota_cero_desde_ms';
  static const _kUltimaActualizacionMs = 'mascota_ultima_actualizacion_ms';

  /// -10% cada 2 horas, como se describió en el diseño.
  static const double _decaimientoPorHora = 5.0;

  /// Mientras duerme, el sueño se recupera más rápido de lo que decae despierta.
  static const double _recuperacionSuenoPorHora = 20.0;

  /// Tiempo real, con hambre y diversión totalmente en cero sin cortar, que
  /// tarda el cazador en aparecer y llevársela.
  static const Duration _tiempoHastaCazador = Duration(hours: 48);

  static double _clamp(double v) => v.clamp(0.0, 100.0);

  /// Pone al día el estado según el tiempo real transcurrido y lo persiste.
  /// Se llama antes de cualquier lectura o acción para que siempre se parta
  /// de valores actualizados. [usuarioId] hace falta para poder avisar por
  /// el buzón si en este momento el cazador se la termina llevando.
  static Future<EstadoMascota> obtenerEstado({required String usuarioId}) async {
    final prefs = await SharedPreferences.getInstance();
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final ultima = prefs.getInt(_kUltimaActualizacionMs);

    var hambre = prefs.getDouble(_kHambre) ?? 100.0;
    var sueno = prefs.getDouble(_kSueno) ?? 100.0;
    var diversion = prefs.getDouble(_kDiversion) ?? 100.0;
    var durmiendo = prefs.getBool(_kDurmiendo) ?? false;
    var secuestrada = prefs.getBool(_kSecuestrada) ?? false;
    var ceroDesdeMs = prefs.getInt(_kCeroDesdeMs);

    if (ultima != null && !secuestrada) {
      final horas = (ahora - ultima) / (1000 * 60 * 60);
      if (horas > 0) {
        hambre = _clamp(hambre - horas * _decaimientoPorHora);
        diversion = _clamp(diversion - horas * _decaimientoPorHora);
        if (durmiendo) {
          sueno = _clamp(sueno + horas * _recuperacionSuenoPorHora);
          if (sueno >= 100.0) durmiendo = false;
        } else {
          sueno = _clamp(sueno - horas * _decaimientoPorHora);
        }
      }
    }

    if (!secuestrada) {
      if (hambre <= 0 && diversion <= 0) {
        ceroDesdeMs ??= ahora;
        if (ahora - ceroDesdeMs >= _tiempoHastaCazador.inMilliseconds) {
          secuestrada = true;
          try {
            await MensajesService.enviarDelSistema(
              usuarioId,
              'cazador',
              '🏹 El cazador se llevó a tu Oca porque la extrañó mucho tiempo. Jugá un desafío de Cuestionados para recuperarla.',
            );
          } catch (_) {
            // Sin conexión: igual queda marcada como secuestrada localmente,
            // el aviso del buzón no es la fuente de verdad del estado.
          }
        }
      } else {
        ceroDesdeMs = null;
      }
    }

    await _guardar(prefs, ahora, hambre, sueno, diversion, durmiendo, secuestrada, ceroDesdeMs);
    return EstadoMascota(hambre: hambre, sueno: sueno, diversion: diversion, durmiendo: durmiendo, secuestrada: secuestrada);
  }

  static Future<void> _guardar(
    SharedPreferences prefs,
    int ahoraMs,
    double hambre,
    double sueno,
    double diversion,
    bool durmiendo,
    bool secuestrada,
    int? ceroDesdeMs,
  ) async {
    await prefs.setInt(_kUltimaActualizacionMs, ahoraMs);
    await prefs.setDouble(_kHambre, hambre);
    await prefs.setDouble(_kSueno, sueno);
    await prefs.setDouble(_kDiversion, diversion);
    await prefs.setBool(_kDurmiendo, durmiendo);
    await prefs.setBool(_kSecuestrada, secuestrada);
    if (ceroDesdeMs == null) {
      await prefs.remove(_kCeroDesdeMs);
    } else {
      await prefs.setInt(_kCeroDesdeMs, ceroDesdeMs);
    }
  }

  /// Le da de comer: sube el hambre. El costo en monedas se cobra afuera
  /// (vía `EconomyService`) antes de llamar a este método.
  static Future<EstadoMascota> alimentar({required String usuarioId, double suba = 30.0}) async {
    final estado = await obtenerEstado(usuarioId: usuarioId);
    if (estado.secuestrada) return estado;
    final prefs = await SharedPreferences.getInstance();
    final nuevaHambre = _clamp(estado.hambre + suba);
    await _guardar(prefs, DateTime.now().millisecondsSinceEpoch, nuevaHambre, estado.sueno, estado.diversion, estado.durmiendo, false, null);
    return EstadoMascota(hambre: nuevaHambre, sueno: estado.sueno, diversion: estado.diversion, durmiendo: estado.durmiendo);
  }

  /// Alterna entre dormida/despierta (gratis, sin costo).
  static Future<EstadoMascota> alternarDormir({required String usuarioId, required bool durmiendo}) async {
    final estado = await obtenerEstado(usuarioId: usuarioId);
    if (estado.secuestrada) return estado;
    final prefs = await SharedPreferences.getInstance();
    await _guardar(prefs, DateTime.now().millisecondsSinceEpoch, estado.hambre, estado.sueno, estado.diversion, durmiendo, false, null);
    return EstadoMascota(hambre: estado.hambre, sueno: estado.sueno, diversion: estado.diversion, durmiendo: durmiendo);
  }

  /// Se llama como efecto secundario de jugar cualquier partida (solo,
  /// sala, campaña grupal o desafío grupal), o al ganarle un minijuego
  /// cortito desde la pantalla de la mascota: sube la diversión.
  static Future<EstadoMascota> registrarJuego({required String usuarioId, double suba = 15.0}) async {
    final estado = await obtenerEstado(usuarioId: usuarioId);
    if (estado.secuestrada) return estado;
    final prefs = await SharedPreferences.getInstance();
    final nuevaDiversion = _clamp(estado.diversion + suba);
    await _guardar(prefs, DateTime.now().millisecondsSinceEpoch, estado.hambre, estado.sueno, nuevaDiversion, estado.durmiendo, false, null);
    return EstadoMascota(hambre: estado.hambre, sueno: estado.sueno, diversion: nuevaDiversion, durmiendo: estado.durmiendo);
  }

  /// Resultado del duelo de Cuestionados contra el cazador. Si se ganó,
  /// vuelve a casa con las barras en un punto amistoso (no arranca de cero
  /// otra vez, para que no se sienta como un castigo).
  static Future<EstadoMascota> intentarRescate({required String usuarioId, required bool gano}) async {
    if (!gano) return obtenerEstado(usuarioId: usuarioId);
    final prefs = await SharedPreferences.getInstance();
    const vuelta = 70.0;
    await _guardar(prefs, DateTime.now().millisecondsSinceEpoch, vuelta, vuelta, vuelta, false, false, null);
    return const EstadoMascota(hambre: vuelta, sueno: vuelta, diversion: vuelta, durmiendo: false, secuestrada: false);
  }
}
