import 'dart:math';

import 'package:flutter/material.dart';

import '../game/campana/campana_solo_controller.dart';
import '../game/campana/etapa.dart';
import '../game/casilla.dart';
import '../game/cuestionados/banco_preguntas.dart';
import '../game/cuestionados/pregunta.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import '../theme/paleta_bloque.dart';
import '../widgets/board/tablero_widget.dart';
import '../widgets/effects/efectos_visuales.dart';
import 'cuestionados_dialog.dart';
import 'minijuego_reflejos_dialog.dart';

/// Campaña Solo: 10 etapas contra un bot con dificultad creciente
/// (sección 6.1). Primer corte jugable de la mecánica core del tablero.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _controller = CampanaSoloController();
  final _rng = Random();
  bool _procesando = false;
  String _mensaje = '';

  @override
  void initState() {
    super.initState();
    _controller.iniciarEtapa(1);
    _mensaje = 'Tu turno: tirá el dado.';
  }

  Etapa get _etapaInfo => Etapa.deNumero(_controller.etapa);

  Future<void> _tirarDadoJugador() async {
    if (_procesando || _controller.turno != Turno.jugador) return;
    if (_controller.jugadorSaltaTurno) {
      setState(() {
        _controller.jugadorSaltaTurno = false;
        _mensaje = 'Perdiste este turno por la cárcel. Le toca al bot.';
        _controller.turno = Turno.bot;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      await _turnoBot();
      return;
    }

    setState(() => _procesando = true);
    final dado = _controller.engine.tirarDado();
    setState(() => _mensaje = 'Sacaste $dado. Avanzando...');
    await _mover(esJugador: true, dado: dado);
    if (!mounted) return;
    setState(() => _procesando = false);
  }

  Future<void> _turnoBot() async {
    if (!mounted) return;
    if (_controller.botSaltaTurno) {
      setState(() {
        _controller.botSaltaTurno = false;
        _mensaje = 'El bot perdió su turno. Te toca a vos.';
        _controller.turno = Turno.jugador;
      });
      return;
    }
    setState(() {
      _procesando = true;
      _mensaje = 'Turno del bot...';
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final dado = _controller.engine.tirarDado();
    setState(() => _mensaje = 'El bot sacó $dado.');
    await _mover(esJugador: false, dado: dado);
    if (!mounted) return;
    setState(() => _procesando = false);
  }

  /// Anima la caminata paso a paso y después resuelve la casilla final.
  Future<void> _mover({required bool esJugador, required int dado}) async {
    final posActual = esJugador ? _controller.posJugador : _controller.posBot;
    final pasos = _controller.engine.secuenciaDePasos(posActual, dado);
    for (final paso in pasos) {
      if (!mounted) return;
      setState(() {
        if (esJugador) {
          _controller.posJugador = paso;
        } else {
          _controller.posBot = paso;
        }
      });
      await Future.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted) return;
    await _resolverCasilla(esJugador: esJugador);
  }

  Future<void> _resolverCasilla({required bool esJugador}) async {
    final pos = esJugador ? _controller.posJugador : _controller.posBot;
    final tipo = _controller.layout.tipoDe(pos);

    if (tipo == TipoCasilla.meta) {
      await _terminarEtapa(ganoJugador: esJugador);
      return;
    }

    switch (tipo) {
      case TipoCasilla.puente:
        final avance = _controller.layout.infoPuenteDe(pos)!.avance;
        setState(() => _mensaje =
            '${esJugador ? "Caíste" : "El bot cayó"} en un puente: +$avance casillas.');
        await Future.delayed(const Duration(milliseconds: 500));
        await _mover(esJugador: esJugador, dado: avance);
        return;

      case TipoCasilla.oca:
      case TipoCasilla.carcel:
      case TipoCasilla.calavera:
        final acerto = await _resolverCuestionados(esJugador: esJugador, tipo: tipo);
        await _aplicarResultadoCuestionados(
          esJugador: esJugador,
          tipo: tipo,
          acerto: acerto,
        );
        return;

      case TipoCasilla.minijuego:
        final gano = esJugador
            ? await MinijuegoReflejosDialog.mostrar(context)
            : _rng.nextDouble() < _controller.config.probabilidadAciertoBot;
        if (gano) {
          setState(() => _mensaje =
              '${esJugador ? "¡Ganaste" : "El bot ganó"} el minijuego! +2 casillas.');
          await Future.delayed(const Duration(milliseconds: 500));
          await _mover(esJugador: esJugador, dado: 2);
          return;
        }
        setState(() => _mensaje =
            '${esJugador ? "Fallaste" : "El bot falló"} el minijuego. Sin premio.');
        break;

      case TipoCasilla.normal:
      case TipoCasilla.meta:
        break;
    }

    await _pasarTurno(esJugador: esJugador);
  }

  Future<bool> _resolverCuestionados({
    required bool esJugador,
    required TipoCasilla tipo,
  }) async {
    final usarDificil =
        tipo == TipoCasilla.calavera || _controller.config.usarBancoDificilEnOcaCarcel;
    final Pregunta pregunta = usarDificil
        ? (BancoPreguntas.preguntasDificil..shuffle(_rng)).first
        : (BancoPreguntas.preguntasPara(_controller.edadBracket)..shuffle(_rng)).first;

    if (!esJugador) {
      return _rng.nextDouble() < _controller.config.probabilidadAciertoBot;
    }

    if (!mounted) return false;
    return CuestionadosDialog.mostrar(
      context,
      pregunta: pregunta,
      tituloCasilla: '${tipo.emoji} ${_nombreCasilla(tipo)}',
      segundos: _controller.config.segundosCuestionados,
    );
  }

  String _nombreCasilla(TipoCasilla tipo) {
    switch (tipo) {
      case TipoCasilla.oca:
        return 'Oca';
      case TipoCasilla.carcel:
        return 'Cárcel';
      case TipoCasilla.calavera:
        return 'Calavera';
      default:
        return '';
    }
  }

  Future<void> _aplicarResultadoCuestionados({
    required bool esJugador,
    required TipoCasilla tipo,
    required bool acerto,
  }) async {
    final quien = esJugador ? 'Vos' : 'El bot';
    switch (tipo) {
      case TipoCasilla.oca:
        if (acerto) {
          setState(() => _mensaje = '$quien acertó la oca: ¡tirada de nuevo!');
          await Future.delayed(const Duration(milliseconds: 500));
          if (esJugador) {
            await _tirarDadoJugador();
          } else {
            await _turnoBot();
          }
          return;
        }
        setState(() => _mensaje = '$quien falló la oca y se queda ahí.');
        break;

      case TipoCasilla.carcel:
        if (acerto) {
          setState(() => _mensaje = '$quien acertó en la cárcel: a salvo.');
        } else {
          setState(() {
            _mensaje = '$quien falló en la cárcel: pierde el próximo turno.';
            if (esJugador) {
              _controller.jugadorSaltaTurno = true;
            } else {
              _controller.botSaltaTurno = true;
            }
          });
        }
        break;

      case TipoCasilla.calavera:
        if (acerto) {
          setState(() => _mensaje = '$quien esquivó la calavera y se queda ahí.');
        } else {
          setState(() => _mensaje = '$quien falló la calavera: vuelve a la salida.');
          await Future.delayed(const Duration(milliseconds: 400));
          await _caminarDeVuelta(esJugador: esJugador);
        }
        break;

      default:
        break;
    }

    await _pasarTurno(esJugador: esJugador);
  }

  Future<void> _caminarDeVuelta({required bool esJugador}) async {
    final posActual = esJugador ? _controller.posJugador : _controller.posBot;
    for (var p = posActual - 1; p >= 0; p--) {
      if (!mounted) return;
      setState(() {
        if (esJugador) {
          _controller.posJugador = p;
        } else {
          _controller.posBot = p;
        }
      });
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _pasarTurno({required bool esJugador}) async {
    if (!mounted) return;
    if (esJugador) {
      setState(() => _controller.turno = Turno.bot);
      await Future.delayed(const Duration(milliseconds: 500));
      await _turnoBot();
    } else {
      setState(() {
        _controller.turno = Turno.jugador;
        _mensaje = 'Tu turno: tirá el dado.';
      });
    }
  }

  Future<void> _terminarEtapa({required bool ganoJugador}) async {
    setState(() => _procesando = true);
    try {
      await SupabaseService.instance.registrarResultadoPartida(
        usuarioId: widget.usuario.id,
        gano: ganoJugador,
      );
    } catch (_) {
      // Sin conexión no debería trabar la campaña; se reintentará en el
      // próximo resultado. El motor de juego local sigue funcionando.
    }
    if (!mounted) return;

    // El monto real de monedas lo calcula el servidor (sección 9); este
    // número es solo una pista visual inmediata para el jugador.
    EfectosVisuales.mostrarMonedasGanadas(context, ganoJugador ? 5 : 2);
    if (ganoJugador) {
      EfectosVisuales.mostrarConfeti(context);
      await _mostrarDialogoVictoriaEtapa();
    } else {
      await _mostrarDialogoDerrotaEtapa();
    }
  }

  Future<void> _mostrarDialogoVictoriaEtapa() async {
    final esUltima = _controller.etapa >= 10;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(esUltima ? '¡Campaña completa! 🏆' : '¡Ganaste la etapa! 🎉'),
        content: Text(esUltima
            ? 'Llegaste a la Cima de Ocaland y completaste las 10 etapas.'
            : 'Superaste "${_etapaInfo.nombre}". Siguiente: '
                '${Etapa.deNumero(_controller.etapa + 1).nombre}.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(esUltima ? 'Volver al menú' : 'Siguiente etapa'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (esUltima) {
      try {
        await SupabaseService.instance.registrarCampanaCompletada(
          usuarioId: widget.usuario.id,
          msTotal: 0,
        );
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _controller.iniciarEtapa(_controller.etapa + 1);
      _controller.reintentosEtapa = 0;
      _mensaje = 'Etapa ${_controller.etapa}: ${_etapaInfo.nombre}. Tu turno.';
      _procesando = false;
    });
  }

  Future<void> _mostrarDialogoDerrotaEtapa() async {
    _controller.reintentosEtapa++;
    final opcion = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('El bot llegó primero'),
        content: Text(
          'Perdiste "${_etapaInfo.nombre}" (reintento n.º ${_controller.reintentosEtapa}). '
          '¿Cómo querés seguir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('reintentar'),
            child: const Text('🔁 Reintentar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('tres_preguntas'),
            child: const Text('🎯 Responder 3 para pasar igual'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (opcion == 'tres_preguntas') {
      final pasoIgual = await _responderTresCuestionados();
      if (!mounted) return;
      if (pasoIgual) {
        setState(() {
          _mensaje = '¡Pasaste "${_etapaInfo.nombre}" respondiendo Cuestionados!';
        });
        await _terminarEtapa(ganoJugador: true);
        return;
      }
    }

    setState(() {
      _controller.reintentarEtapa();
      _mensaje = 'Reintentando "${_etapaInfo.nombre}". Tu turno.';
      _procesando = false;
    });
  }

  Future<bool> _responderTresCuestionados() async {
    for (var i = 0; i < 3; i++) {
      final pregunta =
          (BancoPreguntas.preguntasPara(_controller.edadBracket)..shuffle(_rng)).first;
      if (!mounted) return false;
      final acerto = await CuestionadosDialog.mostrar(
        context,
        pregunta: pregunta,
        tituloCasilla: 'Pregunta ${i + 1} de 3',
        segundos: _controller.config.segundosCuestionados,
      );
      if (!acerto) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final esperandoJugador = _controller.turno == Turno.jugador && !_procesando;
    final paleta = PaletaBloque.deEtapa(_controller.etapa);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: paleta.colorAppBar,
        title: Text('Etapa ${_controller.etapa}: ${_etapaInfo.nombre}'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: paleta.gradiente,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(child: TableroWidget(
                  layout: _controller.layout,
                  posJugador: _controller.posJugador,
                  posBot: _controller.posBot,
                )),
                const SizedBox(height: 12),
                Text(_mensaje, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: paleta.colorAcento),
                  onPressed: esperandoJugador ? _tirarDadoJugador : null,
                  icon: const Icon(Icons.casino),
                  label: const Text('Tirar el dado'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
