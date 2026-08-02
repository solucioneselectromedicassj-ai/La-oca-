import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/board_layout.dart';
import '../models/campana.dart';
import '../models/jugador.dart';
import '../models/pacing.dart';
import '../models/partida.dart';
import '../models/sesion_activa.dart';
import '../models/trivia_bank.dart';
import '../models/usuario.dart';
import '../utils/iterable_ext.dart';
import 'audio_service.dart';
import 'session_service.dart';
import 'supabase_service.dart';

enum GameOverlay {
  none,
  sorteo,
  trivia,
  minijuegoCasilla,
  transicionMinijuego,
  transicionRuleta,
  eleccionPerdiste,
  tresCuestionados,
  campanaTerminada,
}

/// Motor del modo solo (campaña de 10 etapas contra un bot), portado 1 a 1
/// de las reglas del prototipo HTML. Reutiliza el mismo backend Supabase
/// (tablas `partidas` / `jugadores_partida`) aunque juegue una sola persona,
/// para no bifurcar el modelo de datos del resto del juego.
class SoloGameController extends ChangeNotifier {
  Usuario usuario;
  final String myNombre;
  final String myEdadBracket;
  final String myPais;

  SoloGameController({required this.usuario, required this.myNombre, required this.myEdadBracket, required this.myPais});

  String? myPlayerId;
  Partida? partida;
  List<JugadorPartida> jugadores = [];
  EtapaConfig? etapaConfig;
  int reintentosEtapaActual = 0;
  DateTime? _campanaInicioTs;
  DateTime? _etapaInicioTs;
  final List<Map<String, dynamic>> _historialEtapas = [];

  // ---- estado visible para la UI ----
  String gameMsg = '';
  GameOverlay overlay = GameOverlay.none;
  bool diceHabilitado = false;
  bool diceRodando = false;
  int? diceValorMostrado;
  bool botPensando = false;
  bool cargando = true;

  String? animatingPlayerId;
  int? animatingPos; // posición visual durante la caminata; null = usar jugador.posicion

  String? sufriendoPlayerId;

  Map<String, int>? sorteoTiradas;
  String? sorteoGanadorId;

  TriviaQuestion? triviaActual;
  String? triviaTipo;
  int triviaSegundosRestantes = 0;
  Timer? _triviaTimer;
  bool _modoTresCuestionados = false;
  int _tresCuestionadosRespondidas = 0;
  int _tresCuestionadosCorrectas = 0;

  String? minijuegoTipo; // 'reflejos' | 'memoria'
  void Function(bool exito)? _onMinijuegoResuelto;

  String wheelResultLabel = '';
  bool wheelGirando = false;
  bool wheelListaParaContinuar = false;
  String perdidaMsg = '';
  String campanaFinTexto = '';

  bool get esMiTurno {
    final j = _jugadorEnTurno;
    return j != null && j.id == myPlayerId;
  }

  JugadorPartida? get jugadorEnTurno {
    if (jugadores.isEmpty || partida == null) return null;
    return jugadores[partida!.turnoActual % jugadores.length];
  }

  JugadorPartida? get _jugadorEnTurno => jugadorEnTurno;

  JugadorPartida? get yo => jugadores.where((j) => j.id == myPlayerId).firstOrNull;

  void _msg(String m) {
    gameMsg = m;
    notifyListeners();
  }

  Future<void> _wait(Duration d) => Future.delayed(d);

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  // ---------------------------------------------------------------------
  // Arranque del modo solo
  // ---------------------------------------------------------------------
  Future<void> iniciar() async {
    cargando = true;
    notifyListeners();

    Map<String, dynamic>? partidaRow;
    for (var attempt = 0; attempt < 5 && partidaRow == null; attempt++) {
      try {
        partidaRow = await SupabaseService.from('partidas').insert({
          'codigo': _genCode(),
          'estado': 'esperando',
          'max_jugadores': 2,
          'etapa_actual': 1,
        }).select().single();
      } catch (_) {
        // código duplicado u otro error transitorio: reintenta con otro código
      }
    }
    if (partidaRow == null) throw Exception('No se pudo crear la partida.');

    partida = Partida.fromJson(partidaRow);
    _campanaInicioTs = DateTime.now();
    _etapaInicioTs = _campanaInicioTs;
    etapaConfig = Campana.generarConfigEtapa(1);

    final miFila = await SupabaseService.from('jugadores_partida').insert({
      'partida_id': partida!.id,
      'nombre': myNombre,
      'orden_turno': 0,
      'posicion': 0,
      'edad_bracket': myEdadBracket,
      'pais': myPais,
    }).select().single();
    myPlayerId = miFila['id'] as String;

    await SupabaseService.from('jugadores_partida').insert({
      'partida_id': partida!.id,
      'nombre': 'Bot',
      'orden_turno': 1,
      'posicion': 0,
      'es_bot': true,
      'edad_bracket': myEdadBracket,
    });

    final layout = BoardEngine.generarLayoutAleatorio();
    final updated = await SupabaseService.from('partidas').update({
      'estado': 'en_curso',
      'layout_casillas': layout.layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
      'layout_puentes': layout.layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
    }).eq('id', partida!.id).select().single();
    partida = Partida.fromJson(updated);

    await _refreshJugadores();
    await SessionService.guardar(SesionActiva(
      partidaId: partida!.id,
      playerId: myPlayerId!,
      nombre: myNombre,
      edadBracket: myEdadBracket,
      pais: myPais,
      codigo: partida!.codigo,
      esModoSolo: true,
    ));
    cargando = false;
    notifyListeners();

    await _sortearTurnoInicial();
    _procesarTurnoActual();
  }

  /// Retoma una campaña guardada (pantalla "Mis partidas") en vez de crear
  /// una nueva. No vuelve a sortear el turno: continúa donde había quedado.
  Future<void> reanudar(SesionActiva sesion) async {
    cargando = true;
    notifyListeners();
    final row = await SupabaseService.from('partidas').select().eq('id', sesion.partidaId).single();
    partida = Partida.fromJson(row);
    myPlayerId = sesion.playerId;
    etapaConfig = Campana.generarConfigEtapa(partida!.etapaActual);
    _campanaInicioTs = DateTime.now();
    _etapaInicioTs = DateTime.now();
    await _refreshJugadores();
    cargando = false;
    notifyListeners();
    _procesarTurnoActual();
  }

  Future<void> salir() async {
    if (partida != null) await SessionService.borrar(partida!.id);
  }

  Future<void> _refreshJugadores() async {
    final rows = await SupabaseService.from('jugadores_partida').select().eq('partida_id', partida!.id).order('orden_turno');
    jugadores = (rows as List).map((r) => JugadorPartida.fromJson(r as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> _updatePartida(Map<String, dynamic> values) async {
    final updated = await SupabaseService.from('partidas').update(values).eq('id', partida!.id).select().single();
    partida = Partida.fromJson(updated);
  }

  Future<void> _updateJugador(String id, Map<String, dynamic> values) async {
    await SupabaseService.from('jugadores_partida').update(values).eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Sorteo de quién empieza (dados visibles, con empates que vuelven a tirar)
  // ---------------------------------------------------------------------
  Future<void> _sortearTurnoInicial() async {
    var candidatos = jugadores.map((j) => j.id).toList();
    final tiradas = <String, int>{};
    String? ganadorId;
    var vueltas = 0;
    final rnd = Random();
    while (ganadorId == null && vueltas < 5) {
      for (final id in candidatos) {
        tiradas[id] = 1 + rnd.nextInt(6);
      }
      final maxVal = candidatos.map((id) => tiradas[id]!).reduce(max);
      final empatados = candidatos.where((id) => tiradas[id] == maxVal).toList();
      if (empatados.length == 1) {
        ganadorId = empatados.first;
      } else {
        candidatos = empatados;
      }
      vueltas++;
    }
    ganadorId ??= candidatos.first;
    final turnoInicial = max(0, jugadores.indexWhere((j) => j.id == ganadorId));

    await _updatePartida({'turno_actual': turnoInicial, 'sorteo_tiradas': tiradas});

    sorteoTiradas = tiradas;
    sorteoGanadorId = ganadorId;
    overlay = GameOverlay.sorteo;
    AudioService.sorteo();
    notifyListeners();

    await _wait(Pacing.sorteoDisplay);
    overlay = GameOverlay.none;
    notifyListeners();
    await _wait(Pacing.sorteoWaitTotal - Pacing.sorteoDisplay);
  }

  // ---------------------------------------------------------------------
  // Turno: decide si le toca al bot, si está preso, o espera al humano
  // ---------------------------------------------------------------------
  void _procesarTurnoActual() {
    final j = _jugadorEnTurno;
    if (j == null) return;

    if (j.saltaTurno) {
      diceHabilitado = false;
      notifyListeners();
      _saltarTurnoAutomatico(j);
      return;
    }
    if (j.esBot) {
      diceHabilitado = false;
      notifyListeners();
      _jugarTurnoBot(j);
      return;
    }
    diceHabilitado = true;
    notifyListeners();
  }

  Future<void> _saltarTurnoAutomatico(JugadorPartida j) async {
    await _updateJugador(j.id, {'salta_turno': false});
    _msg('⛓️ ${j.id == myPlayerId ? "Perdiste" : "${j.nombre} perdió"} este turno por la cárcel.');
    await _refreshJugadores();
    await _terminarTurno(false);
  }

  Future<void> _jugarTurnoBot(JugadorPartida bot) async {
    botPensando = true;
    _msg('🤖 El bot está pensando...');
    notifyListeners();
    await _wait(Pacing.botThink);
    final valor = 1 + Random().nextInt(6);
    botPensando = false;
    await _resolverMovimiento(bot.id, bot.posicion, valor, bot.edadBracket ?? myEdadBracket, true, bot.pais ?? myPais);
  }

  // ---------------------------------------------------------------------
  // Tirar el dado (jugador humano)
  // ---------------------------------------------------------------------
  Future<void> tirarDado() async {
    if (!diceHabilitado || partida == null) return;
    diceHabilitado = false;
    diceRodando = true;
    AudioService.diceRoll();
    notifyListeners();
    await _wait(Pacing.diceRoll);
    final valor = 1 + Random().nextInt(6);
    diceValorMostrado = valor;
    diceRodando = false;
    notifyListeners();
    final mio = yo!;
    await _resolverMovimiento(myPlayerId!, mio.posicion, valor, myEdadBracket, false, myPais);
    await _wait(Pacing.diceResultHold);
    diceValorMostrado = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Movimiento + regla de rebote + resolución por tipo de casilla
  // ---------------------------------------------------------------------
  Future<void> _resolverMovimiento(String jugadorId, int posActual, int valorDado, String edadBracket, bool esBot, String pais) async {
    final (rawNewPos, huboRebote) = BoardEngine.resolverPosicion(posActual, valorDado);
    final tope = min(posActual + valorDado, BoardEngine.meta);

    await _animarCaminata(jugadorId, posActual, tope);
    if (huboRebote) {
      await _animarCaminata(jugadorId, tope, rawNewPos);
      _msg('↩️ ${esBot ? "El bot se pasó" : "Te pasaste"} de la meta y rebota a la casilla $rawNewPos.');
    }

    final tipo = BoardEngine.tipoCasilla(rawNewPos, partida!.layoutCasillas);

    if (tipo == 'puente') {
      final destino = BoardEngine.destinoPuente(rawNewPos, partida!.layoutPuentes) ?? rawNewPos;
      await _updateJugador(jugadorId, {'posicion': destino});
      _msg('🌉 ¡Puente! ${esBot ? "El bot salta" : "Saltás"} a la casilla $destino.');
      await _refreshJugadores();
      await _terminarTurno(false);
      return;
    }

    if (tipo == 'oca' || tipo == 'carcel' || tipo == 'calavera') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      await _refreshJugadores();
      if (esBot) {
        final probAcierto = tipo == 'calavera'
            ? etapaConfig!.botAciertoCalavera
            : tipo == 'carcel'
                ? etapaConfig!.botAciertoCarcel
                : etapaConfig!.botAciertoOca;
        final acierto = Random().nextDouble() < probAcierto;
        await _aplicarResultadoTrivia(jugadorId, tipo!, rawNewPos, acierto, true, false);
      } else {
        await _mostrarTriviaCasilla(tipo!, rawNewPos, jugadorId, edadBracket, pais);
      }
      return;
    }

    if (tipo == 'minijuego') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      await _refreshJugadores();
      if (esBot) {
        final exito = Random().nextDouble() < etapaConfig!.botAciertoMinijuego;
        await _aplicarResultadoMinijuego(jugadorId, rawNewPos, exito, true);
      } else {
        _mostrarMinijuegoCasilla(rawNewPos, jugadorId);
      }
      return;
    }

    await _updateJugador(jugadorId, {'posicion': rawNewPos});
    await _refreshJugadores();
    if (rawNewPos >= BoardEngine.meta) {
      await _manejarVictoria(jugadorId);
      return;
    }
    await _terminarTurno(false);
  }

  Future<void> _animarCaminata(String jugadorId, int desde, int hasta) async {
    if (desde == hasta) return;
    animatingPlayerId = jugadorId;
    final paso = hasta > desde ? 1 : -1;
    var actual = desde;
    while (actual != hasta) {
      actual += paso;
      animatingPos = actual;
      AudioService.tick();
      notifyListeners();
      await _wait(Pacing.walkStep);
    }
    animatingPlayerId = null;
    animatingPos = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Cuestionados (trivia)
  // ---------------------------------------------------------------------
  Future<void> _mostrarTriviaCasilla(String tipo, int posActual, String jugadorId, String edadBracket, String pais) async {
    await _updatePartida({'estado_turno': 'resolviendo_trivia'});
    final usaDificil = tipo == 'calavera' || etapaConfig!.ocaCarcelUsanBancoDificil;
    final pregunta = usaDificil
        ? (TriviaBank.bancoDificil(edadBracket)..shuffle()).first
        : (TriviaBank.bancoPorPais(pais, edadBracket)..shuffle()).first;

    triviaActual = pregunta;
    triviaTipo = tipo;
    _triviaCallbackPos = posActual;
    _triviaCallbackJugador = jugadorId;
    triviaSegundosRestantes = etapaConfig!.tiempoLimiteTrivia;
    if (jugadorId == myPlayerId && yo?.comodinPendiente == 'doble_tiempo') {
      triviaSegundosRestantes *= 2;
      await _updateJugador(myPlayerId!, {'comodin_pendiente': null});
      _msg('⏳ ¡Usaste tu doble tiempo!');
    }
    overlay = GameOverlay.trivia;
    notifyListeners();
    _iniciarTimerTrivia();
  }

  int _triviaCallbackPos = 0;
  String _triviaCallbackJugador = '';

  void _iniciarTimerTrivia() {
    _triviaTimer?.cancel();
    _triviaTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      triviaSegundosRestantes--;
      notifyListeners();
      if (triviaSegundosRestantes <= 0) {
        t.cancel();
        _resolverTriviaActual(null, porTimeout: true);
      }
    });
  }

  /// Llamado por la UI cuando el jugador toca una opción (idx) o se vence el timer (null).
  Future<void> responderTrivia(int idx) async {
    _triviaTimer?.cancel();
    await _resolverTriviaActual(idx, porTimeout: false);
  }

  Future<void> _resolverTriviaActual(int? idx, {required bool porTimeout}) async {
    final pregunta = triviaActual!;
    final acierto = idx != null && idx == pregunta.correct;
    if (acierto) {
      AudioService.correct();
    } else {
      AudioService.wrong();
    }
    if (_modoTresCuestionados) {
      overlay = GameOverlay.none;
      notifyListeners();
      await _avanzarTresCuestionados(acierto);
      return;
    }
    if (porTimeout) await _wait(const Duration(milliseconds: 900));
    overlay = GameOverlay.none;
    triviaActual = null;
    notifyListeners();
    await _aplicarResultadoTrivia(_triviaCallbackJugador, triviaTipo!, _triviaCallbackPos, acierto, false, porTimeout);
  }

  static const _triviaOutcomeExtraTurn = {'oca'};

  Future<void> _aplicarResultadoTrivia(String jugadorId, String tipo, int posActual, bool acierto, bool esBot, bool forzarSkip) async {
    if (!acierto && !esBot && jugadorId == myPlayerId) {
      final mio = yo;
      if (mio != null && mio.comodinPendiente == 'inmunidad') {
        acierto = true;
        await _updateJugador(myPlayerId!, {'comodin_pendiente': null});
        _msg('🛡️ ¡Tu inmunidad te salvó de la trampa!');
        await _wait(const Duration(milliseconds: 1100));
      }
    }

    int posFinal = posActual;
    bool extraTurn = false;
    bool skipNext = false;
    if (tipo == 'oca') {
      if (acierto) {
        extraTurn = true;
      }
    } else if (tipo == 'carcel') {
      if (!acierto) skipNext = true;
    } else if (tipo == 'calavera') {
      if (!acierto) posFinal = 0;
    }

    if (!acierto && (tipo == 'calavera' || tipo == 'carcel')) {
      sufriendoPlayerId = jugadorId;
      AudioService.suffer();
      notifyListeners();
      await _wait(const Duration(milliseconds: 650));
      sufriendoPlayerId = null;
    }
    if (!acierto && tipo == 'calavera') {
      await _animarCaminata(jugadorId, posActual, posFinal);
    }

    await _updateJugador(jugadorId, {'posicion': posFinal});
    await _refreshJugadores();

    final quien = esBot ? 'El bot' : 'Vos';
    _msg(forzarSkip ? '⏱️ ${quien == "Vos" ? "Se te acabó" : "Se le acabó"} el tiempo.' : _mensajeTrivia(tipo, acierto, quien));

    if (posFinal >= BoardEngine.meta) {
      await _manejarVictoria(jugadorId);
      return;
    }
    if ((tipo == 'carcel' && skipNext) || forzarSkip) {
      await _updateJugador(jugadorId, {'salta_turno': true});
      await _refreshJugadores();
    }
    await _terminarTurno(_triviaOutcomeExtraTurn.contains(tipo) && extraTurn && !forzarSkip);
  }

  String _mensajeTrivia(String tipo, bool acierto, String quien) {
    switch (tipo) {
      case 'oca':
        return acierto ? '🪿 ¡Bien! $quien tira de nuevo.' : '🪿 $quien no acertó, sigue en la misma casilla.';
      case 'carcel':
        return acierto ? '⛓️ ¡$quien se salvó de la cárcel!' : '⛓️ $quien cayó preso y pierde el próximo turno.';
      case 'calavera':
        return acierto ? '💀 Trivia difícil superada, $quien se queda en esta casilla.' : '💀 $quien no la supo y vuelve a la salida.';
      default:
        return '';
    }
  }

  // ---------------------------------------------------------------------
  // Minijuegos
  // ---------------------------------------------------------------------
  void _mostrarMinijuegoCasilla(int posActual, String jugadorId) {
    minijuegoTipo = Random().nextBool() ? 'reflejos' : 'memoria';
    overlay = GameOverlay.minijuegoCasilla;
    _onMinijuegoResuelto = (exito) async {
      overlay = GameOverlay.none;
      notifyListeners();
      await _aplicarResultadoMinijuego(jugadorId, posActual, exito, false);
    };
    notifyListeners();
  }

  /// Llamado por el widget del minijuego (reflejos/memoria) cuando termina.
  void resolverMinijuegoActual(bool exito) {
    final cb = _onMinijuegoResuelto;
    _onMinijuegoResuelto = null;
    cb?.call(exito);
  }

  Future<void> _aplicarResultadoMinijuego(String jugadorId, int posActual, bool exito, bool esBot) async {
    final nuevaPos = exito ? min(posActual + 2, BoardEngine.meta) : posActual;
    await _updateJugador(jugadorId, {'posicion': nuevaPos});
    await _refreshJugadores();
    final quien = esBot ? 'El bot' : 'Vos';
    _msg(exito ? '🎮 ¡$quien superó el minijuego! Avanza 2 casillas extra.' : '🎮 ${quien == "Vos" ? "No superaste" : "No superó"} el minijuego esta vez.');

    if (nuevaPos >= BoardEngine.meta) {
      await _manejarVictoria(jugadorId);
      return;
    }
    await _terminarTurno(false);
  }

  // ---------------------------------------------------------------------
  // Fin de turno
  // ---------------------------------------------------------------------
  Future<void> _terminarTurno(bool extraTurn) async {
    var usarExtra = extraTurn;
    if (!usarExtra) {
      final actual = _jugadorEnTurno;
      if (actual != null && actual.comodinPendiente == 'tirada_extra_activa') {
        usarExtra = true;
        await _updateJugador(actual.id, {'comodin_pendiente': null});
        _msg(actual.id == myPlayerId ? '🎁 ¡Tirada extra! Tirá de nuevo.' : '🎁 ¡${actual.nombre} tiene tirada extra!');
      }
    }
    final siguiente = usarExtra ? partida!.turnoActual : (partida!.turnoActual + 1) % jugadores.length;
    await _updatePartida({'turno_actual': siguiente, 'estado_turno': null});
    await _refreshJugadores();
    _procesarTurnoActual();
  }

  // ---------------------------------------------------------------------
  // Victoria / derrota de una etapa
  // ---------------------------------------------------------------------
  Future<void> _manejarVictoria(String jugadorGanadorId) async {
    final gane = jugadorGanadorId == myPlayerId;
    if (gane) AudioService.win();
    if (usuario.id.isNotEmpty) {
      try {
        final data = await SupabaseService.client.schema('la_vuelta').rpc('registrar_resultado_partida', params: {
          'p_usuario_id': usuario.id,
          'p_gano': gane,
        });
        final fila = data is List ? (data.isNotEmpty ? data.first as Map<String, dynamic> : null) : data as Map<String, dynamic>?;
        if (fila != null) {
          usuario = usuario.copyWith(
            partidasJugadas: usuario.partidasJugadas + 1,
            partidasGanadas: usuario.partidasGanadas + (gane ? 1 : 0),
            monedas: (fila['monedas_total'] as num?)?.toInt(),
          );
        }
      } catch (_) {
        // si falla la RPC (p.ej. sin conexión) seguimos sin bloquear el juego
      }
    }

    if (gane) {
      await _avanzarEtapaCampana();
    } else {
      final etapaActual = partida!.etapaActual;
      perdidaMsg = 'Te ganó el bot en la etapa $etapaActual (van $reintentosEtapaActual reintentos). Elegí cómo seguir:';
      overlay = GameOverlay.eleccionPerdiste;
      notifyListeners();
    }
  }

  Future<void> elegirReintentar() async {
    overlay = GameOverlay.none;
    reintentosEtapaActual++;
    notifyListeners();
    await _reintentarEtapaCampana();
  }

  Future<void> elegirTresCuestionados() async {
    overlay = GameOverlay.none;
    notifyListeners();
    _modoTresCuestionados = true;
    _tresCuestionadosRespondidas = 0;
    _tresCuestionadosCorrectas = 0;
    _siguientePreguntaTresCuestionados();
  }

  final Set<String> _tresCuestionadosUsadas = {};

  void _siguientePreguntaTresCuestionados() {
    final bank = TriviaBank.bancoPorPais(myPais, myEdadBracket);
    TriviaQuestion pregunta;
    var intentos = 0;
    do {
      pregunta = bank[Random().nextInt(bank.length)];
      intentos++;
    } while (_tresCuestionadosUsadas.contains(pregunta.q) && intentos < 20);
    _tresCuestionadosUsadas.add(pregunta.q);
    triviaActual = pregunta;
    triviaTipo = null;
    triviaSegundosRestantes = 0; // sin límite de tiempo, igual que el prototipo
    overlay = GameOverlay.tresCuestionados;
    notifyListeners();
  }

  Future<void> _avanzarTresCuestionados(bool acierto) async {
    if (acierto) _tresCuestionadosCorrectas++;
    _tresCuestionadosRespondidas++;
    await _wait(const Duration(milliseconds: 900));
    if (_tresCuestionadosRespondidas >= 3) {
      _modoTresCuestionados = false;
      _tresCuestionadosUsadas.clear();
      triviaActual = null;
      if (_tresCuestionadosCorrectas == 3) {
        _msg('🎉 ¡Respondiste las 3 Cuestionados! Pasás a la siguiente etapa igual.');
        await _avanzarEtapaCampana();
      } else {
        _msg('😕 Fallaste alguna ($_tresCuestionadosCorrectas/3). Toca reintentar la etapa.');
        reintentosEtapaActual++;
        await _reintentarEtapaCampana();
      }
    } else {
      _siguientePreguntaTresCuestionados();
    }
  }

  Future<void> _avanzarEtapaCampana() async {
    final ahora = DateTime.now();
    final msEtapa = ahora.difference(_etapaInicioTs ?? ahora).inMilliseconds;
    final etapaActual = partida!.etapaActual;
    _historialEtapas.add({'etapa': etapaActual, 'ms': msEtapa});
    diceHabilitado = false;
    notifyListeners();

    if (etapaActual >= 10) {
      final msTotal = ahora.difference(_campanaInicioTs ?? ahora).inMilliseconds;
      await _updatePartida({'estado': 'finalizada'});
      await _guardarHistorialCampana(msTotal);
      try {
        final data = await SupabaseService.client.schema('la_vuelta').rpc('registrar_campana_completada', params: {
          'p_usuario_id': usuario.id,
          'p_ms_total': msTotal,
        });
        final fila = data is List ? (data.isNotEmpty ? data.first as Map<String, dynamic> : null) : data as Map<String, dynamic>?;
        if (fila != null) {
          usuario = usuario.copyWith(
            campanasCompletadas: usuario.campanasCompletadas + 1,
            mejorTiempoCampanaMs: (usuario.mejorTiempoCampanaMs == null || msTotal < usuario.mejorTiempoCampanaMs!) ? msTotal : usuario.mejorTiempoCampanaMs,
            monedas: (fila['monedas_total'] as num?)?.toInt(),
          );
        }
      } catch (_) {}
      AudioService.win();
      campanaFinTexto = '🏆🎉 ¡COMPLETASTE LAS 10 ETAPAS! Tiempo total: ${_formatearMs(msTotal)}';
      overlay = GameOverlay.campanaTerminada;
      notifyListeners();
      return;
    }

    _mostrarTransicionPremio();
  }

  Future<void> _guardarHistorialCampana(int msTotal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList('ocaland_historial_campanas') ?? [];
      lista.insert(0, '$msTotal|$myNombre|${DateTime.now().toIso8601String()}');
      await prefs.setStringList('ocaland_historial_campanas', lista.take(20).toList());
    } catch (_) {}
  }

  String _formatearMs(int ms) {
    final totalSeg = (ms / 1000).round();
    final min = totalSeg ~/ 60;
    final seg = totalSeg % 60;
    return min > 0 ? '${min}m ${seg}s' : '${seg}s';
  }

  // ---------------------------------------------------------------------
  // Transición entre etapas: mini-juego + ruleta de premio real
  // ---------------------------------------------------------------------
  void _mostrarTransicionPremio() {
    minijuegoTipo = Random().nextBool() ? 'reflejos' : 'memoria';
    overlay = GameOverlay.transicionMinijuego;
    _onMinijuegoResuelto = (_) {
      // el resultado del mini-juego de transición es cosmético: siempre se pasa a la ruleta
      _irAFaseRuleta();
    };
    notifyListeners();
  }

  static const List<Map<String, String>> _wheelPrizes = [
    {'id': 'ventaja3', 'label': '+3 casillas de ventaja'},
    {'id': 'doble_tiempo', 'label': 'Doble tiempo en tu próxima Cuestionados'},
    {'id': 'nada', 'label': 'Nada esta vez'},
    {'id': 'tirada_extra', 'label': '+1 tirada extra al empezar'},
    {'id': 'inmunidad', 'label': 'Inmunidad a una trampa'},
    {'id': 'nada', 'label': 'Nada esta vez'},
  ];

  void _irAFaseRuleta() {
    wheelResultLabel = '';
    wheelGirando = false;
    wheelListaParaContinuar = false;
    overlay = GameOverlay.transicionRuleta;
    notifyListeners();
  }

  Future<void> girarRuleta() async {
    if (wheelGirando) return;
    wheelGirando = true;
    notifyListeners();
    final premio = _wheelPrizes[Random().nextInt(_wheelPrizes.length)];
    await _wait(const Duration(milliseconds: 3600));
    wheelResultLabel = '🎁 ¡Premio: ${premio['label']}!';
    wheelGirando = false;
    wheelListaParaContinuar = true;
    if (premio['id'] != 'nada' && myPlayerId != null) {
      await _updateJugador(myPlayerId!, {'comodin_pendiente': premio['id']});
    }
    notifyListeners();
  }

  Future<void> continuarDesdeRuleta() async {
    overlay = GameOverlay.none;
    notifyListeners();
    await _continuarSiguienteEtapaCampana();
  }

  Future<void> _continuarSiguienteEtapaCampana() async {
    final etapaActual = partida!.etapaActual;
    final nuevaEtapa = etapaActual + 1;
    _etapaInicioTs = DateTime.now();
    reintentosEtapaActual = 0;
    etapaConfig = Campana.generarConfigEtapa(nuevaEtapa);
    final layout = BoardEngine.generarLayoutAleatorio();

    final mio = yo;
    final comodin = mio?.comodinPendiente;

    await SupabaseService.from('jugadores_partida').update({'posicion': 0, 'salta_turno': false, 'comodin_pendiente': null}).eq('partida_id', partida!.id);

    var mensajeComodin = '';
    if (comodin == 'ventaja3') {
      await _updateJugador(myPlayerId!, {'posicion': 3});
      mensajeComodin = ' 🎁 ¡Arrancás con 3 casillas de ventaja!';
    } else if (comodin == 'tirada_extra') {
      await _updateJugador(myPlayerId!, {'comodin_pendiente': 'tirada_extra_activa'});
      mensajeComodin = ' 🎁 Tu primera tirada de esta etapa te da un turno extra.';
    } else if (comodin == 'inmunidad') {
      await _updateJugador(myPlayerId!, {'comodin_pendiente': 'inmunidad'});
      mensajeComodin = ' 🛡️ Tenés inmunidad para la próxima trampa que te toque.';
    } else if (comodin == 'doble_tiempo') {
      await _updateJugador(myPlayerId!, {'comodin_pendiente': 'doble_tiempo'});
      mensajeComodin = ' ⏳ Tu próxima Cuestionados tiene el doble de tiempo.';
    }

    await _updatePartida({
      'etapa_actual': nuevaEtapa,
      'estado_turno': null,
      'layout_casillas': layout.layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
      'layout_puentes': layout.layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
    });
    await _refreshJugadores();
    _msg('🎉 ¡Superaste la etapa $etapaActual! Arranca la etapa $nuevaEtapa de 10.$mensajeComodin');
    notifyListeners();

    await _sortearTurnoInicial();
    _procesarTurnoActual();
  }

  Future<void> _reintentarEtapaCampana() async {
    final etapaActual = partida!.etapaActual;
    _etapaInicioTs = DateTime.now();
    final layout = BoardEngine.generarLayoutAleatorio();
    await SupabaseService.from('jugadores_partida').update({'posicion': 0, 'salta_turno': false}).eq('partida_id', partida!.id);
    await _updatePartida({
      'estado_turno': null,
      'layout_casillas': layout.layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
      'layout_puentes': layout.layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
    });
    await _refreshJugadores();
    _msg('😕 Te ganó el bot en la etapa $etapaActual. ¡Reintentá!');
    notifyListeners();

    await _sortearTurnoInicial();
    _procesarTurnoActual();
  }

  @override
  void dispose() {
    _triviaTimer?.cancel();
    super.dispose();
  }
}
