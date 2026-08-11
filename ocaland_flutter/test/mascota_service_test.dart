import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ocaland_flutter/services/mascota_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uid = 'u1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('estado inicial: las tres barras arrancan llenas, sin dormir', () async {
    final e = await MascotaService.obtenerEstado(usuarioId: uid);
    expect(e.hambre, 100);
    expect(e.sueno, 100);
    expect(e.diversion, 100);
    expect(e.durmiendo, false);
    expect(e.secuestrada, false);
  });

  test('hambre, sueño y diversión bajan con el tiempo real transcurrido (despierta)', () async {
    final hace4Horas = DateTime.now().subtract(const Duration(hours: 4)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'mascota_hambre': 100.0,
      'mascota_sueno': 100.0,
      'mascota_diversion': 100.0,
      'mascota_durmiendo': false,
      'mascota_ultima_actualizacion_ms': hace4Horas,
    });
    final e = await MascotaService.obtenerEstado(usuarioId: uid);
    // -5%/hora * 4 horas = -20%
    expect(e.hambre, closeTo(80, 0.5));
    expect(e.sueno, closeTo(80, 0.5));
    expect(e.diversion, closeTo(80, 0.5));
  });

  test('ninguna barra baja de 0 aunque pase mucho tiempo', () async {
    final haceMuchoTiempo = DateTime.now().subtract(const Duration(days: 10)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'mascota_hambre': 100.0,
      'mascota_sueno': 100.0,
      'mascota_diversion': 100.0,
      'mascota_durmiendo': false,
      'mascota_ultima_actualizacion_ms': haceMuchoTiempo,
    });
    final e = await MascotaService.obtenerEstado(usuarioId: uid);
    expect(e.hambre, 0);
    expect(e.sueno, 0);
    expect(e.diversion, 0);
  });

  test('mientras duerme, el sueño sube en vez de bajar (y no se descuenta hambre/diversión aparte de lo normal)', () async {
    final hace1Hora = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'mascota_hambre': 100.0,
      'mascota_sueno': 40.0,
      'mascota_diversion': 100.0,
      'mascota_durmiendo': true,
      'mascota_ultima_actualizacion_ms': hace1Hora,
    });
    final e = await MascotaService.obtenerEstado(usuarioId: uid);
    expect(e.durmiendo, true);
    expect(e.sueno, closeTo(60, 0.5)); // +20%/hora mientras duerme
    expect(e.hambre, closeTo(95, 0.5)); // sigue bajando igual aunque duerma
  });

  test('se despierta sola cuando el sueño llega a 100', () async {
    final hace5Horas = DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'mascota_hambre': 100.0,
      'mascota_sueno': 50.0,
      'mascota_diversion': 100.0,
      'mascota_durmiendo': true,
      'mascota_ultima_actualizacion_ms': hace5Horas,
    });
    final e = await MascotaService.obtenerEstado(usuarioId: uid);
    expect(e.sueno, 100);
    expect(e.durmiendo, false);
  });

  test('alimentar sube el hambre y persiste', () async {
    await MascotaService.obtenerEstado(usuarioId: uid);
    await MascotaService.alimentar(usuarioId: uid); // desde 100 no puede subir más, clampeado
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('mascota_hambre'), 100);

    // Bajamos el hambre manualmente para probar la suba real.
    await prefs.setDouble('mascota_hambre', 40.0);
    final e = await MascotaService.alimentar(usuarioId: uid, suba: 30);
    expect(e.hambre, closeTo(70, 0.5));
  });

  test('alternarDormir cambia el estado y se persiste', () async {
    await MascotaService.obtenerEstado(usuarioId: uid);
    final dormida = await MascotaService.alternarDormir(usuarioId: uid, durmiendo: true);
    expect(dormida.durmiendo, true);
    final despierta = await MascotaService.alternarDormir(usuarioId: uid, durmiendo: false);
    expect(despierta.durmiendo, false);
  });

  test('registrarJuego sube la diversión', () async {
    final prefs = await SharedPreferences.getInstance();
    await MascotaService.obtenerEstado(usuarioId: uid);
    await prefs.setDouble('mascota_diversion', 50.0);
    final e = await MascotaService.registrarJuego(usuarioId: uid, suba: 15);
    expect(e.diversion, closeTo(65, 0.5));
  });

  group('el cazador', () {
    test('todavía no se la lleva si el descuido total es reciente (menos de 48hs)', () async {
      final ahora = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'mascota_hambre': 0.0,
        'mascota_sueno': 0.0,
        'mascota_diversion': 0.0,
        'mascota_durmiendo': false,
        'mascota_ultima_actualizacion_ms': ahora - const Duration(hours: 1).inMilliseconds,
        'mascota_cero_desde_ms': ahora - const Duration(hours: 2).inMilliseconds,
      });
      final e = await MascotaService.obtenerEstado(usuarioId: uid);
      expect(e.secuestrada, false);
    });

    test('se la lleva cuando el descuido total lleva 48hs o más', () async {
      final ahora = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'mascota_hambre': 0.0,
        'mascota_sueno': 0.0,
        'mascota_diversion': 0.0,
        'mascota_durmiendo': false,
        'mascota_ultima_actualizacion_ms': ahora - const Duration(hours: 1).inMilliseconds,
        'mascota_cero_desde_ms': ahora - const Duration(hours: 49).inMilliseconds,
      });
      final e = await MascotaService.obtenerEstado(usuarioId: uid);
      expect(e.secuestrada, true);
    });

    test('intentarRescate con gano=true la libera y le devuelve las barras a un punto amistoso', () async {
      SharedPreferences.setMockInitialValues({'mascota_secuestrada': true});
      final e = await MascotaService.intentarRescate(usuarioId: uid, gano: true);
      expect(e.secuestrada, false);
      expect(e.hambre, 70);
      expect(e.sueno, 70);
      expect(e.diversion, 70);
    });

    test('intentarRescate con gano=false la deja secuestrada para reintentar cuando quiera', () async {
      SharedPreferences.setMockInitialValues({'mascota_secuestrada': true});
      final e = await MascotaService.intentarRescate(usuarioId: uid, gano: false);
      expect(e.secuestrada, true);
    });
  });
}
