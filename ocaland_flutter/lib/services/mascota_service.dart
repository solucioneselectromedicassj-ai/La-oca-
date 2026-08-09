import 'package:shared_preferences/shared_preferences.dart';

/// Estado de la Oca-mascota en un momento dado. Las tres necesidades van de
/// 0 a 100; [durmiendo] indica si está en modo descanso (el sueño sube en
/// vez de bajar mientras tanto).
class EstadoMascota {
  final double hambre;
  final double sueno;
  final double diversion;
  final bool durmiendo;
  const EstadoMascota({required this.hambre, required this.sueno, required this.diversion, required this.durmiendo});
}

/// Mascota virtual (la Oca) — mecánica de enganche diario, no bloqueante.
/// Las tres barras (hambre, sueño, diversión) se calculan en base al tiempo
/// real transcurrido desde la última vez que se consultaron (igual que en
/// Pou): no hace falta ningún timer corriendo en segundo plano, alcanza con
/// "poner al día" el estado cada vez que se lee.
///
/// Se guarda localmente por dispositivo (mismo criterio que sellos y
/// comodines) para no tocar el esquema de Supabase en producción.
class MascotaService {
  MascotaService._();

  static const _kHambre = 'mascota_hambre';
  static const _kSueno = 'mascota_sueno';
  static const _kDiversion = 'mascota_diversion';
  static const _kDurmiendo = 'mascota_durmiendo';
  static const _kUltimaActualizacionMs = 'mascota_ultima_actualizacion_ms';

  /// -10% cada 2 horas, como se describió en el diseño.
  static const double _decaimientoPorHora = 5.0;

  /// Mientras duerme, el sueño se recupera más rápido de lo que decae despierta.
  static const double _recuperacionSuenoPorHora = 20.0;

  static double _clamp(double v) => v.clamp(0.0, 100.0);

  /// Pone al día el estado según el tiempo real transcurrido y lo persiste.
  /// Se llama antes de cualquier lectura o acción para que siempre se parta
  /// de valores actualizados.
  static Future<EstadoMascota> obtenerEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final ultima = prefs.getInt(_kUltimaActualizacionMs);

    var hambre = prefs.getDouble(_kHambre) ?? 100.0;
    var sueno = prefs.getDouble(_kSueno) ?? 100.0;
    var diversion = prefs.getDouble(_kDiversion) ?? 100.0;
    var durmiendo = prefs.getBool(_kDurmiendo) ?? false;

    if (ultima != null) {
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

    await _guardar(prefs, ahora, hambre, sueno, diversion, durmiendo);
    return EstadoMascota(hambre: hambre, sueno: sueno, diversion: diversion, durmiendo: durmiendo);
  }

  static Future<void> _guardar(SharedPreferences prefs, int ahoraMs, double hambre, double sueno, double diversion, bool durmiendo) async {
    await prefs.setInt(_kUltimaActualizacionMs, ahoraMs);
    await prefs.setDouble(_kHambre, hambre);
    await prefs.setDouble(_kSueno, sueno);
    await prefs.setDouble(_kDiversion, diversion);
    await prefs.setBool(_kDurmiendo, durmiendo);
  }

  /// Le da de comer: sube el hambre. El costo en monedas se cobra afuera
  /// (vía `EconomyService`) antes de llamar a este método.
  static Future<EstadoMascota> alimentar({double suba = 30.0}) async {
    final estado = await obtenerEstado();
    final prefs = await SharedPreferences.getInstance();
    final nuevaHambre = _clamp(estado.hambre + suba);
    await _guardar(prefs, DateTime.now().millisecondsSinceEpoch, nuevaHambre, estado.sueno, estado.diversion, estado.durmiendo);
    return EstadoMascota(hambre: nuevaHambre, sueno: estado.sueno, diversion: estado.diversion, durmiendo: estado.durmiendo);
  }

  /// Alterna entre dormida/despierta (gratis, sin costo).
  static Future<EstadoMascota> alternarDormir(bool durmiendo) async {
    final estado = await obtenerEstado();
    final prefs = await SharedPreferences.getInstance();
    await _guardar(prefs, DateTime.now().millisecondsSinceEpoch, estado.hambre, estado.sueno, estado.diversion, durmiendo);
    return EstadoMascota(hambre: estado.hambre, sueno: estado.sueno, diversion: estado.diversion, durmiendo: durmiendo);
  }

  /// Se llama como efecto secundario de jugar cualquier partida (solo,
  /// sala, campaña grupal o desafío grupal): sube la diversión sola.
  static Future<EstadoMascota> registrarJuego({double suba = 15.0}) async {
    final estado = await obtenerEstado();
    final prefs = await SharedPreferences.getInstance();
    final nuevaDiversion = _clamp(estado.diversion + suba);
    await _guardar(prefs, DateTime.now().millisecondsSinceEpoch, estado.hambre, estado.sueno, nuevaDiversion, estado.durmiendo);
    return EstadoMascota(hambre: estado.hambre, sueno: estado.sueno, diversion: nuevaDiversion, durmiendo: estado.durmiendo);
  }
}
