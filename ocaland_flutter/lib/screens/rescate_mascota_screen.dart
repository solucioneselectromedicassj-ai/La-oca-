import 'package:flutter/material.dart';
import '../models/trivia_bank.dart';
import '../models/usuario.dart';
import '../services/audio_service.dart';
import '../services/mascota_service.dart';
import '../services/sellos_service.dart';
import '../theme/app_colors.dart';
import 'widgets/trivia_overlay.dart';

enum _Fase { intro, jugando, exito, fracaso }

/// Costo en sellos para traerla de vuelta directo, sin depender de acertar
/// las preguntas — la garantía de que nunca queda sin salida (además de
/// poder reintentar los Cuestionados las veces que hagan falta, gratis).
const _costoSellosRescate = 10;

/// El cazador se llevó a la Oca por descuido — para recuperarla hay que
/// ganarle un duelo de Cuestionados (mejor de 3, banco normal según edad y
/// país). Se puede reintentar las veces que hagan falta, sin límite: no es
/// un castigo, es una invitación a volver a jugar. Y si no hay caso con las
/// preguntas, también se puede pagar con sellos para traerla directo.
class RescateMascotaScreen extends StatefulWidget {
  final Usuario usuario;
  final String edadBracket;
  final String pais;
  const RescateMascotaScreen({super.key, required this.usuario, required this.edadBracket, required this.pais});

  @override
  State<RescateMascotaScreen> createState() => _RescateMascotaScreenState();
}

class _RescateMascotaScreenState extends State<RescateMascotaScreen> {
  _Fase _fase = _Fase.intro;
  int _ronda = 0;
  int _correctas = 0;
  TriviaQuestion? _pregunta;
  final Set<String> _usadas = {};
  int _sellos = 0;
  EstadoMascota? _ultimoEstado;

  @override
  void initState() {
    super.initState();
    SellosService.obtener().then((s) {
      if (mounted) setState(() => _sellos = s);
    });
  }

  Future<void> _pagarConSellos() async {
    if (_sellos < _costoSellosRescate) return;
    final restantes = await SellosService.agregar(-_costoSellosRescate);
    final nuevo = await MascotaService.intentarRescate(usuarioId: widget.usuario.id, gano: true);
    if (!mounted) return;
    AudioService.win();
    setState(() {
      _sellos = restantes;
      _ultimoEstado = nuevo;
      _fase = _Fase.exito;
    });
  }

  void _empezar() {
    setState(() {
      _fase = _Fase.jugando;
      _ronda = 0;
      _correctas = 0;
      _usadas.clear();
    });
    _siguientePregunta();
  }

  void _siguientePregunta() {
    final banco = TriviaBank.bancoPorPais(widget.pais, widget.edadBracket);
    TriviaQuestion pregunta;
    var intentos = 0;
    do {
      pregunta = (banco..shuffle()).first;
      intentos++;
    } while (_usadas.contains(pregunta.q) && intentos < 20);
    _usadas.add(pregunta.q);
    setState(() => _pregunta = pregunta);
  }

  Future<void> _responder(int idx) async {
    final acierto = idx == _pregunta!.correct;
    if (acierto) {
      AudioService.correct();
      _correctas++;
    } else {
      AudioService.wrong();
    }
    _ronda++;
    if (_ronda >= 3) {
      final gano = _correctas >= 2;
      final nuevo = await MascotaService.intentarRescate(usuarioId: widget.usuario.id, gano: gano);
      if (!mounted) return;
      if (gano) AudioService.win();
      setState(() {
        _ultimoEstado = nuevo;
        _fase = gano ? _Fase.exito : _Fase.fracaso;
      });
    } else {
      _siguientePregunta();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('🏹 Recuperar a la Oca')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(padding: const EdgeInsets.all(20), child: _contenido()),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    switch (_fase) {
      case _Fase.intro:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏹', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 12),
            const Text(
              'El cazador se llevó a tu Oca porque la extrañaste mucho tiempo. Para traerla de vuelta a casa, respondé bien 2 de 3 Cuestionados.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.violetDark, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Si no te sale, no pasa nada: podés volver a intentarlo cuando quieras.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF9B8AB5))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _empezar, child: const Text('Empezar a buscarla'))),
            const SizedBox(height: 10),
            _botonPagarSellos(),
          ],
        );
      case _Fase.jugando:
        final p = _pregunta;
        if (p == null) return const Center(child: CircularProgressIndicator(color: AppColors.violetDark));
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pregunta ${_ronda + 1} de 3 · $_correctas correctas', style: const TextStyle(fontSize: 13, color: Color(0xFF9B8AB5))),
            const SizedBox(height: 12),
            TriviaOverlay(titulo: '🏹 Rescate', pregunta: p, segundos: 0, onResponder: _responder),
          ],
        );
      case _Fase.exito:
        final e = _ultimoEstado;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉🪿', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 12),
            const Text('¡La recuperaste! Volvió contenta a casa.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
            if (e != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Hambre ${e.hambre.round()}% · Sueño ${e.sueno.round()}% · Diversión ${e.diversion.round()}%', style: const TextStyle(fontSize: 12, color: Color(0xFF9B8AB5)))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Volver'))),
          ],
        );
      case _Fase.fracaso:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 12),
            Text('Esta vez no llegaste ($_correctas/3). El cazador todavía la tiene, pero podés volver a intentarlo cuando quieras.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.violetDark, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _empezar, child: const Text('Intentar de nuevo'))),
            const SizedBox(height: 10),
            _botonPagarSellos(),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Volver'))),
          ],
        );
    }
  }

  Widget _botonPagarSellos() {
    final alcanza = _sellos >= _costoSellosRescate;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: alcanza ? _pagarConSellos : null,
        child: Text(alcanza ? '🎖️ Usar $_costoSellosRescate sellos y traerla directo' : '🎖️ Te faltan sellos ($_sellos/$_costoSellosRescate)'),
      ),
    );
  }
}
