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
import '../models/wheel_prizes.dart';
import '../utils/iterable_ext.dart';
import '../utils/uuid.dart';
import 'audio_service.dart';
import 'comodines_service.dart';
import 'economy_service.dart';
import 'identity_service.dart';
import 'mascota_service.dart';
import 'pending_rewards_service.dart';
import 'sellos_service.dart';
import 'session_service.dart';
import 'supabase_service.dart';

enum GameOverlay {
  none,
  sorteo,
  trivia,
  triviaEspectador,
  minijuegoCasilla,
  minijuegoEspectador,
  transicionMinijuego,
  transicionRuleta,
  eleccionPerdiste,
  tresCuestionados,
  campanaTerminada,
  eleccionVideoMonedas,
  anuncioSimulado,
  eleccionComodin,
}

/// Motor del modo solo (campaña de 10 etapas contra un bot), portado 1 a 1
/// de las reglas del prototipo HTML.
///
/// A diferencia del multijugador, el modo solo es "offline-first": toda la
/// partida (tablero, posiciones, turnos) vive únicamente como estado local
/// en memoria — nunca se guarda en las tablas `partidas`/`jugadores_partida`
/// de Supabase, así que se puede jugar sin conexión. Después de cada
/// mutación se guarda un snapshot completo en `SesionActiva` (vía
/// [SessionService]) para poder retomar la campaña desde "Mis partidas"
/// aunque se cierre la app sin internet. Lo único que sí intenta ir a
/// Supabase son las recompensas (monedas/estadísticas) al ganar una partida
/// o completar la campaña — y si eso falla por falta de red, queda
/// encolado en [PendingRewardsService] para reintentarse más tarde.
class SoloGameController extends ChangeNotifier {
  Usuario usuario;
  final String myNombre;
  final String myEdadBracket;
  final String myPais;

  /// Si esta campaña corre atada a un desafío grupal (campañas comparadas
  /// por separado), acá va el id de `desafios_grupales` — al completar las
  /// 10 etapas se guarda el resultado en `desafios_resultados`.
  final String? desafioId;

  SoloGameController({required this.usuario, required this.myNombre, required this.myEdadBracket, required this.myPais, this.desafioId});

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
  bool diceRodando = false;
  int? diceValorMostrado;
  bool botPensando = false;

  /// Igual que [diceRodando]/[diceValorMostrado] pero para la tirada del
  /// bot — así se ve en pantalla qué le salió, en vez de que el turno del
  /// bot sea una caja negra.
  bool botDiceRodando = false;
  int? botDiceValorMostrado;
  bool cargando = true;

  String? animatingPlayerId;
  int? animatingPos; // posición visual durante la caminata; null = usar jugador.posicion

  String? sufriendoPlayerId;

  /// Índice de la casilla que tiene que "temblar" (cárcel/calavera recién
  /// pisadas, antes incluso de mostrar la trivia) — null = ninguna.
  int? trampaCasillaIdx;

  Map<String, int>? sorteoTiradas;
  String? sorteoGanadorId;

  TriviaQuestion? triviaActual;
  String? triviaTipo;
  int triviaSegundosRestantes = 0;
  Timer? _triviaTimer;

  /// Para GameOverlay.triviaEspectador: qué pregunta le "tocó" al bot y si
  /// la supo — de solo lectura, para que el jugador humano tenga algo que
  /// mirar mientras espera su turno en vez de una caja negra.
  String triviaEspectadorNombre = '';
  bool triviaEspectadorAcierto = false;
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

  /// Sellos: coleccionable ganado al caer en trampa (cárcel/calavera),
  /// nuevo respecto del prototipo. Se guarda localmente ([SellosService]).
  int sellos = 0;

  /// Inventario de comodines ganados en la ruleta de premio de etapa
  /// (ventaja3/doble_tiempo/tirada_extra/inmunidad → cantidad). Se guarda
  /// localmente ([ComodinesService]) — ver el comentario ahí sobre por qué
  /// esto es solo para el modo solo.
  Map<String, int> comodines = {};
  Completer<String?>? _comodinCompleter;

  /// Pista de la trivia actual: qué opción quedó eliminada (o null si no
  /// se pidió pista todavía) y si ya se usó (para no permitir pedir dos).
  int? pistaOpcionEliminada;
  bool pistaUsada = false;

  /// Estado del diálogo "elegí cómo conseguirlo" (video / monedas / sellos).
  String eleccionDescripcion = '';
  int eleccionCostoMonedas = 0;
  int eleccionCostoSellos = 0;
  Completer<String>? _eleccionCompleter;

  Completer<void>? _anuncioCompleter;

  bool get esMiTurno {
    final j = _jugadorEnTurno;
    return j != null && j.id == myPlayerId;
  }

  /// Calculado en vivo (no un campo que haya que acordarse de resetear en
  /// cada lugar) — evita que quede "trabado" en false por algún camino que
  /// se haya olvidado de volver a habilitarlo.
  bool get diceHabilitado {
    if (partida?.estado != 'en_curso') return false;
    if (overlay != GameOverlay.none) return false;
    if (diceRodando) return false;
    final j = jugadorEnTurno;
    if (j == null || j.id != myPlayerId) return false;
    if (j.saltaTurno) return false;
    return true;
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
  // Arranque del modo solo — todo local, no depende de la red.
  // ---------------------------------------------------------------------
  Future<void> iniciar() async {
    cargando = true;
    notifyListeners();
    sellos = await SellosService.obtener();
    comodines = await ComodinesService.obtener();

    final partidaId = uuidV4();
    final layout = BoardEngine.generarLayoutAleatorio();
    partida = Partida(
      id: partidaId,
      codigo: _genCode(),
      estado: 'en_curso',
      maxJugadores: 2,
      turnoActual: 0,
      rondaActual: 1,
      etapaActual: 1,
      rachaGanador: 0,
      desempatePendientes: const [],
      desempateTurnoIdx: 0,
      layoutCasillas: layout.layoutCasillas,
      layoutPuentes: layout.layoutPuentes,
    );
    _campanaInicioTs = DateTime.now();
    _etapaInicioTs = _campanaInicioTs;
    etapaConfig = Campana.generarConfigEtapa(1);

    myPlayerId = uuidV4();
    jugadores = [
      JugadorPartida(
        id: myPlayerId!,
        partidaId: partidaId,
        nombre: myNombre,
        esBot: false,
        posicion: 0,
        ordenTurno: 0,
        edadBracket: myEdadBracket,
        pais: myPais,
        saltaTurno: false,
        victorias: 0,
      ),
      JugadorPartida(
        id: uuidV4(),
        partidaId: partidaId,
        nombre: 'El Cazador',
        esBot: true,
        posicion: 0,
        ordenTurno: 1,
        edadBracket: myEdadBracket,
        pais: myPais,
        saltaTurno: false,
        victorias: 0,
      ),
    ];

    await _guardarSesionLocal();
    cargando = false;
    notifyListeners();

    await _sortearTurnoInicial();
    _procesarTurnoActual();
  }

  /// Retoma una campaña guardada (pantalla "Mis partidas") desde el
  /// snapshot local — no depende de la red para nada.
  Future<void> reanudar(SesionActiva sesion) async {
    cargando = true;
    notifyListeners();
    sellos = await SellosService.obtener();
    comodines = await ComodinesService.obtener();

    final snap = sesion.snapshot;
    if (snap == null) {
      throw Exception('Esta partida guardada es de una versión anterior y no se puede retomar.');
    }
    partida = Partida.fromJson((snap['partida'] as Map).cast<String, dynamic>());
    jugadores = ((snap['jugadores'] as List?) ?? [])
        .map((j) => JugadorPartida.fromJson((j as Map).cast<String, dynamic>()))
        .toList();
    myPlayerId = snap['myPlayerId'] as String? ?? sesion.playerId;
    reintentosEtapaActual = (snap['reintentosEtapaActual'] as num?)?.toInt() ?? 0;
    _campanaInicioTs = DateTime.tryParse(snap['campanaInicioTs'] as String? ?? '') ?? DateTime.now();
    _etapaInicioTs = DateTime.tryParse(snap['etapaInicioTs'] as String? ?? '') ?? DateTime.now();
    etapaConfig = Campana.generarConfigEtapa(partida!.etapaActual);

    cargando = false;
    notifyListeners();
    _procesarTurnoActual();
  }

  Future<void> salir() async {
    if (partida != null) await SessionService.borrar(partida!.id);
  }

  /// Snapshot completo del estado local para poder reanudar sin red.
  Map<String, dynamic> _construirSnapshot() => {
        'partida': partida!.toJson(),
        'jugadores': jugadores.map((j) => j.toJson()).toList(),
        'myPlayerId': myPlayerId,
        'reintentosEtapaActual': reintentosEtapaActual,
        'campanaInicioTs': _campanaInicioTs?.toIso8601String(),
        'etapaInicioTs': _etapaInicioTs?.toIso8601String(),
      };

  Future<void> _guardarSesionLocal() async {
    if (partida == null || myPlayerId == null) return;
    await SessionService.guardar(SesionActiva(
      partidaId: partida!.id,
      playerId: myPlayerId!,
      nombre: myNombre,
      edadBracket: myEdadBracket,
      pais: myPais,
      codigo: partida!.codigo,
      esModoSolo: true,
      snapshot: _construirSnapshot(),
    ));
  }

  /// Muta el estado local de la partida (sin red) y persiste el snapshot.
  Future<void> _updatePartida(Map<String, dynamic> values) async {
    partida!.applyPatch(values);
    await _guardarSesionLocal();
    notifyListeners();
  }

  /// Muta el estado local de un jugador (sin red) y persiste el snapshot.
  Future<void> _updateJugador(String id, Map<String, dynamic> values) async {
    jugadores.where((j) => j.id == id).firstOrNull?.applyPatch(values);
    await _guardarSesionLocal();
    notifyListeners();
  }

  /// Aplica el mismo parche a todos los jugadores de la partida (equivalente
  /// al `.update(values).eq('partida_id', ...)` que hacía el multijugador).
  Future<void> _updateTodosLosJugadores(Map<String, dynamic> values) async {
    for (final j in jugadores) {
      j.applyPatch(values);
    }
    await _guardarSesionLocal();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Sorteo de quién empieza (dados visibles, con empates que vuelven a tirar).
  // La primera tirada del jugador humano es interactiva (toca para tirar
  // su propio dado) — pedido del usuario: "el juego de dados déjanos tirar
  // a cada uno, eso ayuda a ser entretenido". El bot (y las rondas de
  // desempate, si hay) tiran solos.
  // ---------------------------------------------------------------------
  String? sorteoEsperandoTapDeId;
  Completer<int>? _sorteoTapCompleter;

  /// Llamado por la UI cuando el jugador toca su fila en el sorteo.
  void tirarDadoSorteo() {
    final c = _sorteoTapCompleter;
    if (c == null || c.isCompleted) return;
    c.complete(1 + Random().nextInt(6));
  }

  Future<int> _tiradaSorteo(JugadorPartida j, bool interactiva) async {
    if (interactiva) {
      sorteoEsperandoTapDeId = j.id;
      _sorteoTapCompleter = Completer<int>();
      notifyListeners();
      final valor = await _sorteoTapCompleter!.future;
      sorteoEsperandoTapDeId = null;
      return valor;
    }
    if (j.esBot) await _wait(const Duration(milliseconds: 550));
    return 1 + Random().nextInt(6);
  }

  Future<void> _sortearTurnoInicial() async {
    var candidatos = jugadores.map((j) => j.id).toList();
    final tiradas = <String, int>{};
    sorteoTiradas = tiradas;
    sorteoGanadorId = null;
    overlay = GameOverlay.sorteo;
    notifyListeners();

    String? ganadorId;
    var vueltas = 0;
    while (ganadorId == null && vueltas < 5) {
      for (final id in candidatos) {
        final j = jugadores.firstWhere((x) => x.id == id);
        final interactiva = vueltas == 0 && !j.esBot && id == myPlayerId;
        final valor = await _tiradaSorteo(j, interactiva);
        tiradas[id] = valor;
        AudioService.sorteo();
        notifyListeners();
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

    sorteoGanadorId = ganadorId;
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
      notifyListeners();
      _saltarTurnoAutomatico(j);
      return;
    }
    if (j.esBot) {
      notifyListeners();
      _jugarTurnoBot(j);
      return;
    }
    notifyListeners();
  }

  Future<void> _saltarTurnoAutomatico(JugadorPartida j) async {
    await _updateJugador(j.id, {'salta_turno': false});
    _msg('⛓️ ${j.id == myPlayerId ? "Perdiste" : "${j.nombre} perdió"} este turno por la cárcel.');
    await _terminarTurno(false);
  }

  Future<void> _jugarTurnoBot(JugadorPartida bot) async {
    botPensando = true;
    _msg('🏹 El Cazador está pensando...');
    notifyListeners();
    await _wait(Pacing.botThink);
    botPensando = false;
    botDiceRodando = true;
    AudioService.diceRoll();
    notifyListeners();
    await _wait(Pacing.diceRoll);
    final valor = 1 + Random().nextInt(6);
    botDiceValorMostrado = valor;
    botDiceRodando = false;
    _msg('🏹 El Cazador tiró un $valor.');
    await _resolverMovimiento(bot.id, bot.posicion, valor, bot.edadBracket ?? myEdadBracket, true, bot.pais ?? myPais);
    await _wait(Pacing.diceResultHold);
    botDiceValorMostrado = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Tirar el dado (jugador humano)
  // ---------------------------------------------------------------------
  Future<void> tirarDado() async {
    if (!diceHabilitado || partida == null) return;
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
      _msg('↩️ ${esBot ? "El Cazador se pasó" : "Te pasaste"} de la meta y rebota a la casilla $rawNewPos.');
    }

    final tipo = BoardEngine.tipoCasilla(rawNewPos, partida!.layoutCasillas);

    if (tipo == 'puente') {
      final destino = BoardEngine.destinoPuente(rawNewPos, partida!.layoutPuentes) ?? rawNewPos;
      await _updateJugador(jugadorId, {'posicion': destino});
      _msg('🌉 ¡Puente! ${esBot ? "El Cazador salta" : "Saltás"} directo a la casilla $destino, sin pregunta.');
      await _terminarTurno(false);
      return;
    }

    if (tipo == 'sello') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      if (!esBot) {
        sellos = await SellosService.agregar(1);
        AudioService.sello();
        _msg('🎖️ ¡Casilla de suerte! Ganaste un sello.');
      } else {
        _msg('🎖️ El Cazador cayó en la casilla de suerte.');
      }
      await _terminarTurno(false);
      return;
    }

    if (tipo == 'oca' || tipo == 'carcel' || tipo == 'calavera') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      if (tipo == 'carcel' || tipo == 'calavera') {
        trampaCasillaIdx = rawNewPos;
        AudioService.trampa();
        notifyListeners();
        await _wait(const Duration(milliseconds: 2200));
        trampaCasillaIdx = null;
        notifyListeners();
      } else {
        AudioService.graznidoAlegre();
      }
      if (esBot) {
        final probAcierto = tipo == 'calavera'
            ? etapaConfig!.botAciertoCalavera
            : tipo == 'carcel'
                ? etapaConfig!.botAciertoCarcel
                : etapaConfig!.botAciertoOca;
        final acierto = Random().nextDouble() < probAcierto;
        await _mostrarTriviaEspectador(tipo!, rawNewPos, jugadorId, edadBracket, pais, acierto);
      } else {
        await _mostrarTriviaCasilla(tipo!, rawNewPos, jugadorId, edadBracket, pais);
      }
      return;
    }

    if (tipo == 'minijuego') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      if (esBot) {
        final exito = Random().nextDouble() < etapaConfig!.botAciertoMinijuego;
        await _mostrarMinijuegoEspectador(rawNewPos, jugadorId, exito);
      } else {
        _mostrarMinijuegoCasilla(rawNewPos, jugadorId);
      }
      return;
    }

    await _updateJugador(jugadorId, {'posicion': rawNewPos});
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
    pistaOpcionEliminada = null;
    pistaUsada = false;
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

  /// Cuando le toca al bot: muestra la misma pregunta que "le tocaría" (de
  /// solo lectura, sin botones habilitados) para que el jugador tenga algo
  /// para mirar mientras espera su turno, en vez de que el turno del bot
  /// sea una caja negra — y después revela si la supo o no.
  Future<void> _mostrarTriviaEspectador(String tipo, int posActual, String jugadorId, String edadBracket, String pais, bool acierto) async {
    final usaDificil = tipo == 'calavera' || etapaConfig!.ocaCarcelUsanBancoDificil;
    final pregunta = usaDificil
        ? (TriviaBank.bancoDificil(edadBracket)..shuffle()).first
        : (TriviaBank.bancoPorPais(pais, edadBracket)..shuffle()).first;

    triviaActual = pregunta;
    triviaTipo = tipo;
    triviaEspectadorNombre = jugadores.where((j) => j.id == jugadorId).firstOrNull?.nombre ?? 'El Cazador';
    triviaEspectadorAcierto = acierto;
    overlay = GameOverlay.triviaEspectador;
    notifyListeners();
    await _wait(const Duration(milliseconds: 5500));
    overlay = GameOverlay.none;
    triviaActual = null;
    notifyListeners();
    await _aplicarResultadoTrivia(jugadorId, tipo, posActual, acierto, true, false);
  }

  /// Igual que [_mostrarTriviaEspectador] pero para la casilla de
  /// minijuego: muestra qué minijuego "le tocó" al bot antes de revelar
  /// si lo superó.
  Future<void> _mostrarMinijuegoEspectador(int posActual, String jugadorId, bool exito) async {
    minijuegoTipo = Random().nextBool() ? 'reflejos' : 'memoria';
    triviaEspectadorNombre = jugadores.where((j) => j.id == jugadorId).firstOrNull?.nombre ?? 'El Cazador';
    triviaEspectadorAcierto = exito;
    overlay = GameOverlay.minijuegoEspectador;
    notifyListeners();
    await _wait(const Duration(milliseconds: 3800));
    overlay = GameOverlay.none;
    notifyListeners();
    await _aplicarResultadoMinijuego(jugadorId, posActual, exito, true);
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
    notifyListeners();

    if (!acierto) {
      final otraOportunidad = await _ofrecerVideoOMonedas(
        descripcion: '¿Querés otra oportunidad para responder antes de la penitencia?',
        costoMonedas: 15,
        costoSellos: 5,
      );
      if (otraOportunidad) {
        await _mostrarTriviaCasilla(triviaTipo!, _triviaCallbackPos, _triviaCallbackJugador, myEdadBracket, myPais);
        return;
      }
    }
    triviaActual = null;
    notifyListeners();
    await _aplicarResultadoTrivia(_triviaCallbackJugador, triviaTipo!, _triviaCallbackPos, acierto, false, porTimeout);
  }

  /// Pedir una pista en la trivia actual: elimina una opción incorrecta.
  /// Cuesta monedas o sellos, o se puede conseguir gratis viendo un video.
  ///
  /// Pausa el timer de la trivia mientras se decide (si no, seguía corriendo
  /// en segundo plano y podía vencer justo mientras se elegía video/monedas,
  /// pisando el overlay/completer de este diálogo y dejando el juego
  /// trabado sin ninguna pantalla con la que interactuar) y siempre vuelve
  /// a mostrar la trivia al terminar, se haya conseguido la pista o no.
  Future<void> pedirPista() async {
    if (pistaUsada || triviaActual == null) return;
    _triviaTimer?.cancel();
    final conseguida = await _ofrecerVideoOMonedas(
      descripcion: 'Una pista elimina una opción incorrecta. ¿Cómo la conseguís?',
      costoMonedas: 10,
      costoSellos: 3,
    );
    if (triviaActual == null) return; // se resolvió por otro lado mientras tanto
    if (conseguida && !pistaUsada) {
      final pregunta = triviaActual!;
      final incorrectas = List.generate(pregunta.options.length, (i) => i).where((i) => i != pregunta.correct).toList();
      incorrectas.shuffle();
      pistaOpcionEliminada = incorrectas.first;
      pistaUsada = true;
    }
    overlay = GameOverlay.trivia;
    notifyListeners();
    _iniciarTimerTrivia();
  }

  // ---------------------------------------------------------------------
  // Video / monedas / sellos — port de `ofrecerVideoOMonedas` y
  // `showAdSimulada` del prototipo. Devuelve true si el jugador consiguió
  // lo que ofrecía el diálogo (vio el video o pagó), false si canceló.
  // ---------------------------------------------------------------------
  Future<bool> _ofrecerVideoOMonedas({required String descripcion, required int costoMonedas, required int costoSellos}) async {
    eleccionDescripcion = descripcion;
    eleccionCostoMonedas = costoMonedas;
    eleccionCostoSellos = costoSellos;
    overlay = GameOverlay.eleccionVideoMonedas;
    notifyListeners();
    _eleccionCompleter = Completer<String>();
    final eleccion = await _eleccionCompleter!.future;

    try {
      if (eleccion == 'video') {
        await _mostrarAnuncioSimulado();
        return true;
      }
      if (eleccion == 'monedas') {
        final r = await EconomyService.gastarMonedas(usuario.id, costoMonedas);
        if (r == null || !r.exito) {
          _msg('🪙 No te alcanzan las monedas.');
          return false;
        }
        usuario = usuario.copyWith(monedas: r.monedasRestantes);
        notifyListeners();
        return true;
      }
      if (eleccion == 'sellos') {
        sellos = await SellosService.agregar(-costoSellos);
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Si falla la red o el guardado local, no dejamos el juego trabado:
      // se trata como si el jugador hubiera cancelado.
      if (overlay == GameOverlay.anuncioSimulado || overlay == GameOverlay.eleccionVideoMonedas) {
        overlay = GameOverlay.none;
      }
      _msg('⚠️ No se pudo completar. Seguimos.');
      return false;
    }
    return false;
  }

  Future<void> _mostrarAnuncioSimulado() {
    overlay = GameOverlay.anuncioSimulado;
    notifyListeners();
    _anuncioCompleter = Completer<void>();
    return _anuncioCompleter!.future;
  }

  void elegirVideo() => _resolverEleccion('video');
  void elegirMonedasParaEleccion() => _resolverEleccion('monedas');
  void elegirSellosParaEleccion() => _resolverEleccion('sellos');
  void cancelarEleccionVideoMonedas() => _resolverEleccion('cancelar');

  void _resolverEleccion(String eleccion) {
    final c = _eleccionCompleter;
    if (c == null || c.isCompleted) return;
    overlay = GameOverlay.none;
    notifyListeners();
    c.complete(eleccion);
  }

  void continuarDesdeAnuncio() {
    final c = _anuncioCompleter;
    if (c == null || c.isCompleted) return;
    overlay = GameOverlay.none;
    notifyListeners();
    c.complete();
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

    final quien = esBot ? 'El Cazador' : 'Vos';
    _msg(forzarSkip ? '⏱️ ${quien == "Vos" ? "Se te acabó" : "Se le acabó"} el tiempo.' : _mensajeTrivia(tipo, acierto, quien));

    if (posFinal >= BoardEngine.meta) {
      await _manejarVictoria(jugadorId);
      return;
    }
    if ((tipo == 'carcel' && skipNext) || forzarSkip) {
      await _updateJugador(jugadorId, {'salta_turno': true});
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
    final quien = esBot ? 'El Cazador' : 'Vos';
    _msg(exito ? '🎮 ¡$quien superó el minijuego! Avanza 2 casillas extra.' : '🎮 ${quien == "Vos" ? "No superaste" : "No superó"} el minijuego esta vez.');

    if (nuevaPos >= BoardEngine.meta) {
      await _manejarVictoria(jugadorId);
      return;
    }
    if (!esBot && !exito) {
      await _mostrarAnuncioSimulado();
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
    _procesarTurnoActual();
  }

  // ---------------------------------------------------------------------
  // Victoria / derrota de una etapa
  // ---------------------------------------------------------------------
  Future<void> _manejarVictoria(String jugadorGanadorId) async {
    final gane = jugadorGanadorId == myPlayerId;
    if (gane) AudioService.win();
    unawaited(MascotaService.registrarJuego(usuarioId: usuario.id));
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
          await IdentityService.actualizarCache(usuario);
        }
      } catch (_) {
        // sin conexión: la recompensa queda encolada y se reintenta cuando vuelva la red
        await PendingRewardsService.encolar(PendingReward('partida_jugada', {'usuario_id': usuario.id, 'gano': gane}));
      }
    }

    if (gane) {
      await _avanzarEtapaCampana();
    } else {
      final etapaActual = partida!.etapaActual;
      perdidaMsg = 'Te ganó el Cazador en la etapa $etapaActual (van $reintentosEtapaActual reintentos). Elegí cómo seguir:';
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
          await IdentityService.actualizarCache(usuario);
        }
      } catch (_) {
        await PendingRewardsService.encolar(PendingReward('campana_completada', {'usuario_id': usuario.id, 'ms_total': msTotal}));
      }
      if (desafioId != null) {
        try {
          await SupabaseService.from('desafios_resultados').insert({
            'desafio_id': desafioId,
            'usuario_id': usuario.id,
            'nombre': myNombre,
            'etapas_completadas': 10,
            'ms_total': msTotal,
          });
        } catch (_) {
          await PendingRewardsService.encolar(PendingReward('desafio_resultado', {
            'desafio_id': desafioId,
            'usuario_id': usuario.id,
            'nombre': myNombre,
            'etapas_completadas': 10,
            'ms_total': msTotal,
          }));
        }
      }
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

  /// A qué división apunta el giro actual — se fija ANTES de arrancar a
  /// girar, para que la rueda pueda animarse hasta frenar justo ahí (y no
  /// mostrar un giro genérico desconectado del premio real).
  int? wheelPremioIdx;

  void _irAFaseRuleta() {
    wheelResultLabel = '';
    wheelGirando = false;
    wheelListaParaContinuar = false;
    wheelPremioIdx = null;
    overlay = GameOverlay.transicionRuleta;
    notifyListeners();
  }

  Future<void> girarRuleta() async {
    if (wheelGirando) return;
    final idx = Random().nextInt(wheelPrizes.length);
    wheelPremioIdx = idx;
    wheelGirando = true;
    notifyListeners();
    final premio = wheelPrizes[idx];
    await _wait(const Duration(milliseconds: 3600));
    wheelResultLabel = '🎁 ¡Premio: ${premio['label']}!';
    wheelGirando = false;
    wheelListaParaContinuar = true;
    final premioId = premio['id'];
    if (premioId != null && premioId != 'nada') {
      comodines = await ComodinesService.agregar(premioId, 1);
    }
    notifyListeners();
  }

  Future<void> continuarDesdeRuleta() async {
    overlay = GameOverlay.none;
    notifyListeners();
    String? comodinElegido;
    if (comodines.isNotEmpty) {
      overlay = GameOverlay.eleccionComodin;
      notifyListeners();
      _comodinCompleter = Completer<String?>();
      comodinElegido = await _comodinCompleter!.future;
    }
    await _continuarSiguienteEtapaCampana(comodinElegido);
  }

  /// Llamado por la UI cuando el jugador elige qué comodín usar en la
  /// nueva etapa (o `null` si toca "No usar ninguno").
  void elegirComodinParaEtapa(String? tipo) {
    final c = _comodinCompleter;
    if (c == null || c.isCompleted) return;
    overlay = GameOverlay.none;
    notifyListeners();
    c.complete(tipo);
  }

  Future<void> _continuarSiguienteEtapaCampana(String? comodinElegido) async {
    final etapaActual = partida!.etapaActual;
    final nuevaEtapa = etapaActual + 1;
    _etapaInicioTs = DateTime.now();
    reintentosEtapaActual = 0;
    etapaConfig = Campana.generarConfigEtapa(nuevaEtapa);
    final layout = BoardEngine.generarLayoutAleatorio();

    await _updateTodosLosJugadores({'posicion': 0, 'salta_turno': false, 'comodin_pendiente': null});

    var mensajeComodin = '';
    if (comodinElegido != null) {
      comodines = await ComodinesService.agregar(comodinElegido, -1);
      if (comodinElegido == 'ventaja3') {
        await _updateJugador(myPlayerId!, {'posicion': 3});
        mensajeComodin = ' 🎁 ¡Arrancás con 3 casillas de ventaja!';
      } else if (comodinElegido == 'tirada_extra') {
        await _updateJugador(myPlayerId!, {'comodin_pendiente': 'tirada_extra_activa'});
        mensajeComodin = ' 🎁 Tu primera tirada de esta etapa te da un turno extra.';
      } else if (comodinElegido == 'inmunidad') {
        await _updateJugador(myPlayerId!, {'comodin_pendiente': 'inmunidad'});
        mensajeComodin = ' 🛡️ Tenés inmunidad para la próxima trampa que te toque.';
      } else if (comodinElegido == 'doble_tiempo') {
        await _updateJugador(myPlayerId!, {'comodin_pendiente': 'doble_tiempo'});
        mensajeComodin = ' ⏳ Tu próxima Cuestionados tiene el doble de tiempo.';
      }
    }

    await _updatePartida({
      'etapa_actual': nuevaEtapa,
      'estado_turno': null,
      'layout_casillas': layout.layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
      'layout_puentes': layout.layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
    });
    _msg('🎉 ¡Superaste la etapa $etapaActual! Arranca la etapa $nuevaEtapa de 10.$mensajeComodin');
    notifyListeners();

    await _sortearTurnoInicial();
    _procesarTurnoActual();
  }

  Future<void> _reintentarEtapaCampana() async {
    final etapaActual = partida!.etapaActual;
    _etapaInicioTs = DateTime.now();
    final layout = BoardEngine.generarLayoutAleatorio();
    await _updateTodosLosJugadores({'posicion': 0, 'salta_turno': false});
    await _updatePartida({
      'estado_turno': null,
      'layout_casillas': layout.layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
      'layout_puentes': layout.layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
    });
    _msg('😕 Te ganó el Cazador en la etapa $etapaActual. ¡Reintentá!');
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
