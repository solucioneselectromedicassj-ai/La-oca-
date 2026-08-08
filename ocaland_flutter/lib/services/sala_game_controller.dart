import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:realtime_client/realtime_client.dart';

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
import 'audio_service.dart';
import 'economy_service.dart';
import 'join_room_result.dart';
import 'sellos_service.dart';
import 'session_service.dart';
import 'supabase_service.dart';

enum MpOverlay { none, sorteo, trivia, minijuego, transicionMinijuego, transicionRuleta, eleccionVideoMonedas, anuncioSimulado }

const _horasPlazoTurno = 6;
const _tiempoLimiteTriviaTanda = 15; // segundos, fijo (sin escalado de dificultad, a diferencia de la campaña)
const _totalPartidasTanda = 3; // mejor de 3

/// Motor de la sala normal multijugador ("tanda"): crear/unirse por código,
/// sala de espera, sorteo de turno, tirar el dado por turnos con plazo de
/// 6hs, Cuestionados, minijuegos, mejor-de-3 con desempate por trivia.
/// Portado del prototipo HTML, reutilizando el mismo backend Supabase.
class SalaGameController extends ChangeNotifier {
  Usuario usuario;
  final String myNombre;
  final String myEdadBracket;
  final String myPais;

  SalaGameController({required this.usuario, required this.myNombre, required this.myEdadBracket, required this.myPais});

  Partida? partida;
  List<JugadorPartida> jugadores = [];
  String? myPlayerId;
  bool cargando = false;
  EtapaConfig? etapaConfig;

  RealtimeChannel? _channel;
  Timer? _pollTimer;
  int _caminataEnCurso = 0;
  bool _saltandoTurno = false;
  bool _autoSaltandoPorVencimiento = false;
  bool _desempateTriviaMostrada = false;

  // ---- estado visible para la UI ----
  String gameMsg = '';
  MpOverlay overlay = MpOverlay.none;
  bool diceRodando = false;
  int? diceValorMostrado;
  String? animatingPlayerId;
  int? animatingPos;
  String? sufriendoPlayerId;
  int? trampaCasillaIdx;
  Map<String, int>? sorteoTiradas;
  String? sorteoGanadorId;
  bool _sorteoMostrado = false;

  TriviaQuestion? triviaActual;
  String? triviaTipo;
  int triviaSegundosRestantes = 0;
  Timer? _triviaTimer;
  int _triviaCallbackPos = 0;
  String _triviaCallbackJugador = '';
  bool _esDesempateTrivia = false;

  String? minijuegoTipo;
  void Function(bool exito)? _onMinijuegoResuelto;

  // ---- ruleta de premio del ganador de cada etapa (solo campaña grupal) ----
  String wheelResultLabel = '';
  bool wheelGirando = false;
  bool wheelListaParaContinuar = false;

  // ---- fin de partida / tanda ----
  String? finMensaje;
  bool finMostrarRevancha = false;
  String finLabelRevancha = '';
  bool finMostrarNuevaTanda = false;
  bool finMostrarJugarOtra = false;

  /// Sellos: coleccionable ganado al caer en trampa (cárcel/calavera).
  int sellos = 0;
  int? pistaOpcionEliminada;
  bool pistaUsada = false;
  String eleccionDescripcion = '';
  int eleccionCostoMonedas = 0;
  int eleccionCostoSellos = 0;
  Completer<String>? _eleccionCompleter;
  Completer<void>? _anuncioCompleter;

  Future<void> _cargarSellos() async {
    sellos = await SellosService.obtener();
  }

  bool get esCampanaGrupal => partida?.esCampanaGrupal ?? false;
  int get _totalRondas => esCampanaGrupal ? 10 : _totalPartidasTanda;
  String get _palabraRonda => esCampanaGrupal ? 'etapa' : 'partida';

  bool get soyHost {
    if (jugadores.isEmpty) return false;
    final ordenMinimo = jugadores.map((j) => j.ordenTurno).reduce(min);
    final host = jugadores.firstWhere((j) => j.ordenTurno == ordenMinimo);
    return host.id == myPlayerId;
  }

  bool get puedoIniciar => soyHost && jugadores.length >= 2 && partida?.estado == 'esperando';

  JugadorPartida? get yo => jugadores.where((j) => j.id == myPlayerId).firstOrNull;

  JugadorPartida? get jugadorEnTurno {
    if (jugadores.isEmpty || partida == null) return null;
    return jugadores[partida!.turnoActual % jugadores.length];
  }

  bool get esMiTurno => jugadorEnTurno?.id == myPlayerId;

  /// Calculado en vivo (en vez de un flag que hay que sincronizar a mano en
  /// cada punto del código donde cambia el turno): habilitado solo si la
  /// partida está en curso, no hay ningún overlay abierto, no se está
  /// resolviendo ya una tirada, y es mi turno sin estar preso.
  bool get diceHabilitado {
    if (partida?.estado != 'en_curso') return false;
    if (overlay != MpOverlay.none) return false;
    if (diceRodando) return false;
    final j = jugadorEnTurno;
    if (j == null || j.id != myPlayerId) return false;
    if (j.saltaTurno) return false;
    return true;
  }

  String get marcadorTexto => jugadores.map((j) => '${j.nombre}: ${j.victorias}').join('  ·  ');

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
  // Crear / unirse / reconectar
  // ---------------------------------------------------------------------
  Future<void> crearSala() async {
    cargando = true;
    notifyListeners();
    await _cargarSellos();
    Map<String, dynamic>? row;
    for (var attempt = 0; attempt < 5 && row == null; attempt++) {
      try {
        row = await SupabaseService.from('partidas').insert({'codigo': _genCode(), 'estado': 'esperando', 'max_jugadores': 6}).select().single();
      } catch (_) {}
    }
    if (row == null) throw Exception('No se pudo crear la sala.');
    partida = Partida.fromJson(row);
    await _joinAsPlayer(partida!.id, 0);
    await _refreshJugadores();
    await _guardarSesion();
    cargando = false;
    notifyListeners();
    _subscribeRealtime();
    _startPolling();
  }

  /// Campaña grupal en vivo: mismo tablero para todos, pero cada ronda es
  /// una etapa distinta (1 a 10) con la dificultad progresiva de la campaña.
  Future<void> crearSalaCampanaGrupal() async {
    cargando = true;
    notifyListeners();
    await _cargarSellos();
    Map<String, dynamic>? row;
    for (var attempt = 0; attempt < 5 && row == null; attempt++) {
      try {
        row = await SupabaseService.from('partidas').insert({'codigo': _genCode(), 'estado': 'esperando', 'max_jugadores': 6, 'modo': 'campana_grupal', 'etapa_actual': 1}).select().single();
      } catch (_) {}
    }
    if (row == null) throw Exception('No se pudo crear la campaña grupal.');
    partida = Partida.fromJson(row);
    await _joinAsPlayer(partida!.id, 0);
    await _refreshJugadores();
    await _guardarSesion();
    cargando = false;
    notifyListeners();
    _subscribeRealtime();
    _startPolling();
  }

  Future<JoinRoomResult> unirseSala(String codigo) async {
    cargando = true;
    notifyListeners();
    await _cargarSellos();
    Map<String, dynamic>? row;
    try {
      row = await SupabaseService.from('partidas').select().eq('codigo', codigo.toUpperCase()).single();
    } catch (_) {
      cargando = false;
      notifyListeners();
      return JoinRoomResult.noExiste();
    }
    final p = Partida.fromJson(row);

    if (p.estado != 'esperando') {
      final existentesRaw = await SupabaseService.from('jugadores_partida').select().eq('partida_id', p.id);
      final existentes = (existentesRaw as List).map((r) => JugadorPartida.fromJson(r as Map<String, dynamic>)).where((j) => !j.esBot).toList();
      cargando = false;
      notifyListeners();
      return JoinRoomResult.reconectar(p, existentes);
    }

    final existentesRaw = await SupabaseService.from('jugadores_partida').select('id').eq('partida_id', p.id);
    if ((existentesRaw as List).length >= p.maxJugadores) {
      cargando = false;
      notifyListeners();
      return JoinRoomResult.salaLlena();
    }

    partida = p;
    await _joinAsPlayer(p.id, existentesRaw.length);
    await _refreshJugadores();
    await _guardarSesion();
    cargando = false;
    notifyListeners();
    _subscribeRealtime();
    _startPolling();
    return JoinRoomResult.ok(p);
  }

  /// Desde "Mis partidas": recupera la partida y el jugador guardados por
  /// id directamente (sin pasar por el código de sala) y reconecta.
  /// Devuelve false si la partida ya no existe (se borró, etc.).
  Future<bool> reanudarDesdeSesion(SesionActiva sesion) async {
    try {
      final partidaRow = await SupabaseService.from('partidas').select().eq('id', sesion.partidaId).single();
      final jugadorRow = await SupabaseService.from('jugadores_partida').select().eq('id', sesion.playerId).single();
      await reconectarComo(Partida.fromJson(partidaRow), JugadorPartida.fromJson(jugadorRow));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reconectarComo(Partida p, JugadorPartida jugador) async {
    partida = p;
    myPlayerId = jugador.id;
    await _cargarSellos();
    if (esCampanaGrupal) etapaConfig = Campana.generarConfigEtapa(p.etapaActual);
    await _refreshJugadores();
    await _guardarSesion();
    notifyListeners();
    _subscribeRealtime();
    _startPolling();
    if (partida!.estado == 'finalizada') _mostrarFinDePartida();
  }

  Future<void> _guardarSesion() async {
    await SessionService.guardar(SesionActiva(
      partidaId: partida!.id,
      playerId: myPlayerId!,
      nombre: myNombre,
      edadBracket: myEdadBracket,
      pais: myPais,
      codigo: partida!.codigo,
      esModoSolo: false,
    ));
  }

  Future<void> _joinAsPlayer(String partidaId, int ordenTurno) async {
    final row = await SupabaseService.from('jugadores_partida').insert({
      'partida_id': partidaId,
      'nombre': myNombre,
      'orden_turno': ordenTurno,
      'posicion': 0,
      'edad_bracket': myEdadBracket,
      'pais': myPais,
    }).select().single();
    myPlayerId = row['id'] as String;
  }

  Future<void> _refreshJugadores() async {
    final rows = await SupabaseService.from('jugadores_partida').select().eq('partida_id', partida!.id).order('orden_turno');
    jugadores = (rows as List).map((r) => JugadorPartida.fromJson(r as Map<String, dynamic>)).toList();
    notifyListeners();
    onPosiblePropioTurnoSaltado();
  }

  Future<void> _refreshPartida() async {
    final row = await SupabaseService.from('partidas').select().eq('id', partida!.id).single();
    _aplicarPartidaActualizada(Partida.fromJson(row));
  }

  Future<void> _updatePartida(Map<String, dynamic> values) async {
    final updated = await SupabaseService.from('partidas').update(values).eq('id', partida!.id).select().single();
    _aplicarPartidaActualizada(Partida.fromJson(updated));
  }

  Future<void> _updateJugador(String id, Map<String, dynamic> values) async {
    await SupabaseService.from('jugadores_partida').update(values).eq('id', id);
  }

  void _aplicarPartidaActualizada(Partida nueva) {
    final estadoAnterior = partida?.estado;
    partida = nueva;
    if (estadoAnterior != 'finalizada' && nueva.estado == 'finalizada') {
      _mostrarFinDePartida();
    }
    if (nueva.estado == 'desempate') {
      _actualizarPanelDesempate();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Realtime + polling de respaldo (igual que el prototipo: dos capas)
  // ---------------------------------------------------------------------
  void _subscribeRealtime() {
    _channel = SupabaseService.client.channel('partida-${partida!.id}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'la_vuelta',
        table: 'jugadores_partida',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'partida_id', value: partida!.id),
        callback: (_) => _refreshJugadores(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'la_vuelta',
        table: 'partidas',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: partida!.id),
        callback: (payload) => _aplicarPartidaActualizada(Partida.fromJson(payload.newRecord)),
      );
    _channel!.subscribe();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (partida == null) return;
      await _refreshJugadores();
      if (_caminataEnCurso == 0) {
        await _refreshPartida();
      }
      _chequearVencimientoTurno();
    });
  }

  void _chequearVencimientoTurno() {
    if (partida?.estado != 'en_curso' || partida?.turnoVenceTs == null) return;
    if (_autoSaltandoPorVencimiento) return;
    if (DateTime.now().isAfter(partida!.turnoVenceTs!)) {
      _autoSaltarPorVencimiento();
    }
  }

  Future<void> _autoSaltarPorVencimiento() async {
    _autoSaltandoPorVencimiento = true;
    final j = jugadorEnTurno;
    _msg('⏰ Se venció el plazo de ${_horasPlazoTurno}hs para ${j?.nombre ?? "el jugador"}, se saltea su turno.');
    try {
      await _terminarTurno(false);
    } finally {
      _autoSaltandoPorVencimiento = false;
    }
  }

  DateTime _calcularNuevoVencimiento() => DateTime.now().add(const Duration(hours: _horasPlazoTurno));

  // ---------------------------------------------------------------------
  // Iniciar la partida (host)
  // ---------------------------------------------------------------------
  Future<void> iniciarPartida() async {
    if (esCampanaGrupal) etapaConfig = Campana.generarConfigEtapa(partida!.etapaActual);
    final layout = BoardEngine.generarLayoutAleatorio();
    await _updatePartida({
      'estado': 'en_curso',
      'layout_casillas': layout.layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
      'layout_puentes': layout.layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
    });
    await _sortearTurnoInicial();
  }

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

    await _updatePartida({'estado_turno': 'sorteo', 'turno_actual': turnoInicial, 'sorteo_tiradas': tiradas});
    _mostrarSorteoDados(tiradas, ganadorId);
    await _wait(Pacing.sorteoWaitTotal);
    await _updatePartida({'estado_turno': null, 'turno_vence_ts': _calcularNuevoVencimiento().toIso8601String()});
  }

  void _mostrarSorteoDados(Map<String, int> tiradas, String ganadorId) {
    if (_sorteoMostrado) return;
    _sorteoMostrado = true;
    AudioService.sorteo();
    sorteoTiradas = tiradas;
    sorteoGanadorId = ganadorId;
    overlay = MpOverlay.sorteo;
    notifyListeners();
    _wait(Pacing.sorteoDisplay).then((_) {
      overlay = MpOverlay.none;
      _sorteoMostrado = false;
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------
  // Turno propio: salta_turno (cárcel) o tirar el dado
  // ---------------------------------------------------------------------
  void onPosiblePropioTurnoSaltado() {
    final j = jugadorEnTurno;
    if (j == null || j.id != myPlayerId || !j.saltaTurno || _saltandoTurno) return;
    _saltarTurnoAutomatico(j);
  }

  Future<void> _saltarTurnoAutomatico(JugadorPartida j) async {
    _saltandoTurno = true;
    await _updateJugador(j.id, {'salta_turno': false});
    _msg('⛓️ Perdiste este turno por la cárcel.');
    await _refreshJugadores();
    await _terminarTurno(false);
    _saltandoTurno = false;
  }

  Future<void> tirarDado() async {
    if (!esMiTurno || partida?.estado != 'en_curso' || overlay != MpOverlay.none) return;
    diceRodando = true;
    AudioService.diceRoll();
    notifyListeners();
    await _wait(Pacing.diceRoll);
    final valor = 1 + Random().nextInt(6);
    diceValorMostrado = valor;
    diceRodando = false;
    notifyListeners();
    final mio = yo!;
    await _resolverMovimiento(mio.posicion, valor);
    await _wait(Pacing.diceResultHold);
    diceValorMostrado = null;
    notifyListeners();
  }

  Future<void> _resolverMovimiento(int posActual, int valorDado) async {
    final jugadorId = myPlayerId!;
    final (rawNewPos, huboRebote) = BoardEngine.resolverPosicion(posActual, valorDado);
    final tope = min(posActual + valorDado, BoardEngine.meta);

    await _animarCaminata(jugadorId, posActual, tope);
    if (huboRebote) {
      await _animarCaminata(jugadorId, tope, rawNewPos);
      _msg('↩️ Te pasaste de la meta y rebota a la casilla $rawNewPos.');
    }

    final tipo = BoardEngine.tipoCasilla(rawNewPos, partida!.layoutCasillas);

    if (tipo == 'puente') {
      final destino = BoardEngine.destinoPuente(rawNewPos, partida!.layoutPuentes) ?? rawNewPos;
      await _updateJugador(jugadorId, {'posicion': destino});
      _msg('🌉 ¡Puente! Saltás directo a la casilla $destino, sin pregunta.');
      await _refreshJugadores();
      await _terminarTurno(false);
      return;
    }

    if (tipo == 'sello') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      await _refreshJugadores();
      sellos = await SellosService.agregar(1);
      AudioService.sello();
      _msg('🎖️ ¡Casilla de suerte! Ganaste un sello.');
      await _terminarTurno(false);
      return;
    }

    if (tipo == 'oca' || tipo == 'carcel' || tipo == 'calavera') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      await _refreshJugadores();
      if (tipo == 'carcel' || tipo == 'calavera') {
        trampaCasillaIdx = rawNewPos;
        AudioService.trampa();
        notifyListeners();
        await _wait(const Duration(milliseconds: 2200));
        trampaCasillaIdx = null;
        notifyListeners();
      }
      await _mostrarTriviaCasilla(tipo!, rawNewPos, jugadorId);
      return;
    }

    if (tipo == 'minijuego') {
      await _updateJugador(jugadorId, {'posicion': rawNewPos});
      await _refreshJugadores();
      _mostrarMinijuegoCasilla(rawNewPos, jugadorId);
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
    _caminataEnCurso++;
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
    _caminataEnCurso = max(0, _caminataEnCurso - 1);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Cuestionados
  // ---------------------------------------------------------------------
  Future<void> _mostrarTriviaCasilla(String tipo, int posActual, String jugadorId) async {
    await _updatePartida({'estado_turno': 'resolviendo_trivia'});
    final usaDificil = tipo == 'calavera' || (esCampanaGrupal && etapaConfig != null && etapaConfig!.ocaCarcelUsanBancoDificil);
    final pregunta = usaDificil
        ? (TriviaBank.bancoDificil(myEdadBracket)..shuffle()).first
        : (TriviaBank.bancoPorPais(myPais, myEdadBracket)..shuffle()).first;

    triviaActual = pregunta;
    triviaTipo = tipo;
    pistaOpcionEliminada = null;
    pistaUsada = false;
    _esDesempateTrivia = false;
    _triviaCallbackPos = posActual;
    _triviaCallbackJugador = jugadorId;
    triviaSegundosRestantes = (esCampanaGrupal && etapaConfig != null) ? etapaConfig!.tiempoLimiteTrivia : _tiempoLimiteTriviaTanda;
    if (yo?.comodinPendiente == 'doble_tiempo') {
      triviaSegundosRestantes *= 2;
      await _updateJugador(myPlayerId!, {'comodin_pendiente': null});
      _msg('⏳ ¡Usaste tu doble tiempo!');
    }
    await _updatePartida({'trivia_pregunta_actual': pregunta.q});
    overlay = MpOverlay.trivia;
    notifyListeners();
    _iniciarTimerTrivia();
  }

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
    if (porTimeout) await _wait(const Duration(milliseconds: 900));
    overlay = MpOverlay.none;
    notifyListeners();

    if (_esDesempateTrivia) {
      triviaActual = null;
      notifyListeners();
      await _resolverDesempate(_triviaCallbackJugador, acierto, partida!.desempatePendientes);
      return;
    }

    if (!acierto) {
      final otraOportunidad = await _ofrecerVideoOMonedas(
        descripcion: '¿Querés otra oportunidad para responder antes de la penitencia?',
        costoMonedas: 15,
        costoSellos: 5,
      );
      if (otraOportunidad) {
        await _mostrarTriviaCasilla(triviaTipo!, _triviaCallbackPos, _triviaCallbackJugador);
        return;
      }
    }
    triviaActual = null;
    notifyListeners();
    await _aplicarResultadoTrivia(_triviaCallbackJugador, triviaTipo!, _triviaCallbackPos, acierto, porTimeout);
  }

  /// Pedir una pista en la trivia actual: elimina una opción incorrecta.
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
    overlay = MpOverlay.trivia;
    notifyListeners();
    _iniciarTimerTrivia();
  }

  // ---------------------------------------------------------------------
  // Video / monedas / sellos — ver comentario equivalente en SoloGameController.
  // ---------------------------------------------------------------------
  Future<bool> _ofrecerVideoOMonedas({required String descripcion, required int costoMonedas, required int costoSellos}) async {
    eleccionDescripcion = descripcion;
    eleccionCostoMonedas = costoMonedas;
    eleccionCostoSellos = costoSellos;
    overlay = MpOverlay.eleccionVideoMonedas;
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
      if (overlay == MpOverlay.anuncioSimulado || overlay == MpOverlay.eleccionVideoMonedas) {
        overlay = MpOverlay.none;
      }
      _msg('⚠️ No se pudo completar. Seguimos.');
      return false;
    }
    return false;
  }

  Future<void> _mostrarAnuncioSimulado() {
    overlay = MpOverlay.anuncioSimulado;
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
    overlay = MpOverlay.none;
    notifyListeners();
    c.complete(eleccion);
  }

  void continuarDesdeAnuncio() {
    final c = _anuncioCompleter;
    if (c == null || c.isCompleted) return;
    overlay = MpOverlay.none;
    notifyListeners();
    c.complete();
  }

  static const _tiposConTiroExtra = {'oca'};

  Future<void> _aplicarResultadoTrivia(String jugadorId, String tipo, int posActual, bool acierto, bool forzarSkip) async {
    if (!acierto && jugadorId == myPlayerId) {
      final mio = yo;
      if (mio != null && mio.comodinPendiente == 'inmunidad') {
        acierto = true;
        await _updateJugador(myPlayerId!, {'comodin_pendiente': null});
        _msg('🛡️ ¡Tu inmunidad te salvó de la trampa!');
        await _wait(const Duration(milliseconds: 1100));
      }
    }

    int posFinal = posActual;
    bool skipNext = false;
    if (tipo == 'carcel' && !acierto) skipNext = true;
    if (tipo == 'calavera' && !acierto) posFinal = 0;

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

    _msg(forzarSkip ? '⏱️ Se te acabó el tiempo.' : _mensajeTrivia(tipo, acierto));

    if (posFinal >= BoardEngine.meta) {
      await _manejarVictoria(jugadorId);
      return;
    }
    if ((tipo == 'carcel' && skipNext) || forzarSkip) {
      await _updateJugador(jugadorId, {'salta_turno': true});
      await _refreshJugadores();
    }
    await _terminarTurno(_tiposConTiroExtra.contains(tipo) && acierto && !forzarSkip);
  }

  String _mensajeTrivia(String tipo, bool acierto) {
    switch (tipo) {
      case 'oca':
        return acierto ? '🪿 ¡Bien! Tirás de nuevo.' : '🪿 No acertaste, seguís en la misma casilla.';
      case 'carcel':
        return acierto ? '⛓️ ¡Te salvaste de la cárcel!' : '⛓️ Caíste preso y perdés el próximo turno.';
      case 'calavera':
        return acierto ? '💀 Trivia difícil superada, te quedás en esta casilla.' : '💀 No la supiste y volvés a la salida.';
      default:
        return '';
    }
  }

  // ---------------------------------------------------------------------
  // Minijuegos
  // ---------------------------------------------------------------------
  void _mostrarMinijuegoCasilla(int posActual, String jugadorId) {
    minijuegoTipo = Random().nextBool() ? 'reflejos' : 'memoria';
    overlay = MpOverlay.minijuego;
    _onMinijuegoResuelto = (exito) async {
      overlay = MpOverlay.none;
      notifyListeners();
      await _aplicarResultadoMinijuego(jugadorId, posActual, exito);
    };
    notifyListeners();
  }

  void resolverMinijuegoActual(bool exito) {
    final cb = _onMinijuegoResuelto;
    _onMinijuegoResuelto = null;
    cb?.call(exito);
  }

  Future<void> _aplicarResultadoMinijuego(String jugadorId, int posActual, bool exito) async {
    final nuevaPos = exito ? min(posActual + 2, BoardEngine.meta) : posActual;
    await _updateJugador(jugadorId, {'posicion': nuevaPos});
    await _refreshJugadores();
    _msg(exito ? '🎮 ¡Superaste el minijuego! Avanza 2 casillas extra.' : '🎮 No superaste el minijuego esta vez.');
    if (nuevaPos >= BoardEngine.meta) {
      await _manejarVictoria(jugadorId);
      return;
    }
    if (!exito) {
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
      final actual = jugadorEnTurno;
      if (actual != null && actual.comodinPendiente == 'tirada_extra_activa') {
        usarExtra = true;
        await _updateJugador(actual.id, {'comodin_pendiente': null});
        _msg(actual.id == myPlayerId ? '🎁 ¡Tirada extra! Tirá de nuevo.' : '🎁 ¡${actual.nombre} tiene tirada extra!');
      }
    }
    final siguiente = usarExtra ? partida!.turnoActual : (partida!.turnoActual + 1) % jugadores.length;
    await _updatePartida({'turno_actual': siguiente, 'estado_turno': null, 'turno_vence_ts': _calcularNuevoVencimiento().toIso8601String()});
    await _refreshJugadores();
  }

  // ---------------------------------------------------------------------
  // Victoria de una partida de la tanda
  // ---------------------------------------------------------------------
  Future<void> _manejarVictoria(String jugadorGanadorId) async {
    if (jugadorGanadorId == myPlayerId) AudioService.win();
    final ganador = jugadores.firstWhere((j) => j.id == jugadorGanadorId);
    final rachaPrevia = partida!.rachaGanador;
    final nuevaRacha = partida!.ultimoGanadorId == jugadorGanadorId ? rachaPrevia + 1 : 1;
    final nuevasVictorias = ganador.victorias + 1;

    await _updateJugador(jugadorGanadorId, {'victorias': nuevasVictorias});
    await _updatePartida({'estado': 'finalizada', 'estado_turno': null, 'ultimo_ganador_id': jugadorGanadorId, 'racha_ganador': nuevaRacha});

    // El ganador de la etapa tira el mini-juego + ruleta para su propio
    // comodín; es cosmético y no bloquea al resto de la sala, que ya ve
    // el marcador normal (fin de partida) al mismo tiempo.
    if (esCampanaGrupal && jugadorGanadorId == myPlayerId) {
      _mostrarTransicionPremioGanador();
    }
  }

  void _mostrarTransicionPremioGanador() {
    minijuegoTipo = Random().nextBool() ? 'reflejos' : 'memoria';
    overlay = MpOverlay.transicionMinijuego;
    _onMinijuegoResuelto = (_) => _irAFaseRuletaGanador();
    notifyListeners();
  }

  int? wheelPremioIdx;

  void _irAFaseRuletaGanador() {
    wheelResultLabel = '';
    wheelGirando = false;
    wheelListaParaContinuar = false;
    wheelPremioIdx = null;
    overlay = MpOverlay.transicionRuleta;
    notifyListeners();
  }

  Future<void> girarRuletaGanador() async {
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
    if (premio['id'] != 'nada' && myPlayerId != null) {
      await _updateJugador(myPlayerId!, {'comodin_pendiente': premio['id']});
    }
    notifyListeners();
  }

  void cerrarRuletaGanador() {
    overlay = MpOverlay.none;
    notifyListeners();
  }

  void _mostrarFinDePartida() {
    if (partida == null || jugadores.isEmpty) return;
    final ganadorRonda = jugadores.where((j) => j.id == partida!.ultimoGanadorId).firstOrNull;
    final ronda = partida!.rondaActual;
    final rachaTermina = partida!.rachaGanador >= 2;
    final grupal = esCampanaGrupal;
    final nombreCompeticion = grupal ? 'CAMPAÑA GRUPAL' : 'TANDA';

    finMostrarJugarOtra = true;

    if (rachaTermina) {
      finLabelRevancha = '';
      finMostrarRevancha = false;
      finMostrarNuevaTanda = soyHost;
      finMensaje = '🏆🏆 ¡${ganadorRonda?.nombre} gana la $nombreCompeticion! ($marcadorTexto)';
      notifyListeners();
      return;
    }

    if (ronda < _totalRondas) {
      finMensaje = '🏆 ¡Ganó ${ganadorRonda?.nombre} la $_palabraRonda $ronda! ($marcadorTexto)';
      finLabelRevancha = grupal ? '▶️ Siguiente etapa' : '▶️ Siguiente partida de la tanda';
      finMostrarRevancha = soyHost;
      finMostrarNuevaTanda = false;
      notifyListeners();
      return;
    }

    final maxVictorias = jugadores.map((j) => j.victorias).reduce(max);
    final empatados = jugadores.where((j) => j.victorias == maxVictorias).toList();

    if (empatados.length == 1) {
      finMensaje = '🏆🏆 ¡${empatados.first.nombre} gana la $nombreCompeticion! ($marcadorTexto)';
      finMostrarRevancha = false;
      finMostrarNuevaTanda = soyHost;
      notifyListeners();
      return;
    }

    if (ronda == _totalRondas) {
      finMensaje = '🤝 Empate entre ${empatados.map((j) => j.nombre).join(", ")} tras $_totalRondas ${_palabraRonda}s. Se juega una más para definir.';
      finLabelRevancha = grupal ? '▶️ Etapa extra de desempate' : '▶️ Partida extra de desempate';
      finMostrarRevancha = soyHost;
      finMostrarNuevaTanda = false;
      notifyListeners();
      return;
    }

    finMensaje = '🎯 Sigue el empate entre ${empatados.map((j) => j.nombre).join(", ")}. ¡Desempate por trivia!';
    finMostrarRevancha = false;
    finMostrarNuevaTanda = false;
    notifyListeners();
    if (soyHost && partida!.estado != 'desempate') {
      _iniciarDesempatePorTrivia(empatados.map((j) => j.id).toList());
    }
  }

  // ---------------------------------------------------------------------
  // Desempate directo por Cuestionados (eliminación de a uno)
  // ---------------------------------------------------------------------
  Future<void> _iniciarDesempatePorTrivia(List<String> idsEmpatados) async {
    await _updatePartida({'estado': 'desempate', 'desempate_pendientes': idsEmpatados, 'desempate_turno_idx': 0});
  }

  void _actualizarPanelDesempate() {
    final pendientes = partida!.desempatePendientes;
    if (pendientes.isEmpty) return;
    final idx = partida!.desempateTurnoIdx % pendientes.length;
    final jugadorTurnoId = pendientes[idx];
    if (jugadorTurnoId == myPlayerId && !_desempateTriviaMostrada) {
      _desempateTriviaMostrada = true;
      _mostrarTriviaDesempate(jugadorTurnoId, pendientes);
    }
    notifyListeners();
  }

  void _mostrarTriviaDesempate(String jugadorId, List<String> pendientes) {
    final bank = TriviaBank.bancoDificil(myEdadBracket);
    triviaActual = (bank..shuffle()).first;
    triviaTipo = null;
    _esDesempateTrivia = true;
    _triviaCallbackJugador = jugadorId;
    triviaSegundosRestantes = _tiempoLimiteTriviaTanda;
    overlay = MpOverlay.trivia;
    notifyListeners();
    _iniciarTimerTrivia();
  }

  Future<void> _resolverDesempate(String jugadorId, bool acierto, List<String> pendientesActuales) async {
    _desempateTriviaMostrada = false;
    final nuevos = List<String>.from(pendientesActuales);
    final idxJugador = nuevos.indexOf(jugadorId);

    if (!acierto) {
      nuevos.removeAt(idxJugador);
      _msg(jugadorId == myPlayerId ? '❌ Perdiste el desempate y quedás eliminado.' : '❌ Perdió el desempate y queda eliminado.');
    } else {
      _msg(jugadorId == myPlayerId ? '✅ Acertaste y seguís en el desempate.' : '✅ Acertó y sigue en el desempate.');
    }

    if (nuevos.length == 1) {
      await _finalizarTanda(nuevos.first);
      return;
    }

    final siguienteIdx = acierto ? (idxJugador + 1) % nuevos.length : idxJugador % nuevos.length;
    await _updatePartida({'desempate_pendientes': nuevos, 'desempate_turno_idx': siguienteIdx});
  }

  Future<void> _finalizarTanda(String jugadorGanadorId) async {
    await _updatePartida({'ganador_tanda_id': jugadorGanadorId, 'estado': 'finalizada'});
  }

  // ---------------------------------------------------------------------
  // Botones de host: siguiente partida / nueva tanda
  // ---------------------------------------------------------------------
  Future<void> btnRevanchaOSiguientePartida() async {
    await _reiniciarYArrancarDirecto(rondaExtra: 1, resetVictorias: false);
  }

  Future<void> btnNuevaTanda() async {
    await _reiniciarYArrancarDirecto(rondaExtra: 0, resetVictorias: true, nuevaRondaFija: 1);
  }

  Future<void> _reiniciarYArrancarDirecto({required int rondaExtra, required bool resetVictorias, int? nuevaRondaFija}) async {
    final layout = BoardEngine.generarLayoutAleatorio();
    final grupal = esCampanaGrupal;
    final ganadorId = partida!.ultimoGanadorId;
    final ganador = grupal ? jugadores.where((j) => j.id == ganadorId).firstOrNull : null;
    final comodinGanador = ganador?.comodinPendiente;

    await SupabaseService.from('jugadores_partida').update({
      'posicion': 0,
      'salta_turno': false,
      'comodin_pendiente': null,
      if (resetVictorias) 'victorias': 0,
    }).eq('partida_id', partida!.id);

    var mensajeComodin = '';
    if (grupal && ganadorId != null && comodinGanador != null) {
      switch (comodinGanador) {
        case 'ventaja3':
          await _updateJugador(ganadorId, {'posicion': 3});
          mensajeComodin = ' 🎁 ${ganador!.nombre} arranca con 3 casillas de ventaja.';
          break;
        case 'tirada_extra':
          await _updateJugador(ganadorId, {'comodin_pendiente': 'tirada_extra_activa'});
          mensajeComodin = ' 🎁 ${ganador!.nombre} tiene tirada extra en su primer turno.';
          break;
        case 'inmunidad':
          await _updateJugador(ganadorId, {'comodin_pendiente': 'inmunidad'});
          mensajeComodin = ' 🛡️ ${ganador!.nombre} tiene inmunidad para la próxima trampa.';
          break;
        case 'doble_tiempo':
          await _updateJugador(ganadorId, {'comodin_pendiente': 'doble_tiempo'});
          mensajeComodin = ' ⏳ ${ganador!.nombre} tiene doble tiempo en su próxima Cuestionados.';
          break;
      }
    }

    final nuevaRonda = nuevaRondaFija ?? (partida!.rondaActual + rondaExtra);
    final updates = <String, dynamic>{
      'estado': 'en_curso',
      'turno_actual': 0,
      'estado_turno': null,
      'desempate_pendientes': <String>[],
      'desempate_turno_idx': 0,
      'ronda_actual': nuevaRonda,
      if (resetVictorias) 'ultimo_ganador_id': null,
      if (resetVictorias) 'racha_ganador': 0,
      if (resetVictorias) 'ganador_tanda_id': null,
      'layout_casillas': layout.layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
      'layout_puentes': layout.layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
    };
    if (grupal) {
      final nuevaEtapa = min(nuevaRonda, 10);
      updates['etapa_actual'] = nuevaEtapa;
      etapaConfig = Campana.generarConfigEtapa(nuevaEtapa);
    }
    await _updatePartida(updates);
    finMensaje = null;
    finMostrarRevancha = false;
    finMostrarNuevaTanda = false;
    finMostrarJugarOtra = false;
    if (mensajeComodin.isNotEmpty) _msg(mensajeComodin.trim());
    await _refreshJugadores();
    await _sortearTurnoInicial();
  }

  Future<void> salir() async {
    _pollTimer?.cancel();
    if (_channel != null) {
      await SupabaseService.client.removeChannel(_channel!);
    }
    if (partida != null) await SessionService.borrar(partida!.id);
  }

  @override
  void dispose() {
    _triviaTimer?.cancel();
    _pollTimer?.cancel();
    if (_channel != null) {
      SupabaseService.client.removeChannel(_channel!);
    }
    super.dispose();
  }
}
