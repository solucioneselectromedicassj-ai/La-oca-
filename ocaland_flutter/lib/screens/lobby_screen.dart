import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../app_config.dart';
import '../models/usuario.dart';
import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../services/mascota_service.dart';
import '../services/mensajes_service.dart';
import '../services/pending_rewards_service.dart';
import '../services/push_service.dart';
import '../services/sala_game_controller.dart';
import '../services/solo_game_controller.dart';
import '../theme/app_colors.dart';
import 'amigos_screen.dart';
import 'buzon_screen.dart';
import 'desafio_grupal_screen.dart';
import 'edad_screen.dart';
import 'game_screen_solo.dart';
import 'join_sala_screen.dart';
import 'mascota_screen.dart';
import 'minijuegos_bonus_screen.dart';
import 'mis_partidas_screen.dart';
import 'pais_screen.dart';
import 'perfil_screen.dart';
import 'ranking_screen.dart';
import 'tanda_cuestionados_screen.dart';
import 'waiting_room_screen.dart';
import 'widgets/oca_face.dart';
import 'widgets/ruleta_bonus_dialog.dart';

/// Lobby: todos los modos (solo, sala normal, campaña grupal en vivo,
/// desafío grupal) y toda la cuenta/economía ya están activos.
class LobbyScreen extends StatefulWidget {
  final Usuario usuario;
  final String? nombre;
  final String? edadBracket;
  final String? pais;
  final bool offline;

  const LobbyScreen({super.key, required this.usuario, this.nombre, this.edadBracket, this.pais, this.offline = false});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String? _edadBracket;
  String? _pais;
  Timer? _heartbeat;
  EstadoMascota? _mascota;
  int _noLeidos = 0;

  @override
  void initState() {
    super.initState();
    _edadBracket = widget.edadBracket;
    _pais = widget.pais;
    _cargarMascota();
    _cargarNoLeidos();
    PushService.iniciar(usuarioId: widget.usuario.id);
    // Si había recompensas de partidas jugadas offline, las sincroniza apenas hay red.
    PendingRewardsService.flush();
    if (widget.offline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('📡 Sin conexión: podés jugar el modo solo. Tus monedas y estadísticas se van a poner al día cuando vuelva internet.'),
          duration: Duration(seconds: 5),
        ));
      });
    }
    // Recompensa por tiempo activo en la app (hitos a los 5/15/30 min), igual que el prototipo.
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) async {
      try {
        final r = await EconomyService.registrarMinutoActivo(widget.usuario.id);
        if (mounted && r != null && r.huboPremio) {
          AudioService.coin();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+${r.monedasGanadas} 🪙 por seguir jugando (${r.minutosHoy} min hoy)')));
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  String get _nombre => widget.nombre ?? widget.usuario.nombre;

  Future<void> _cargarMascota() async {
    final e = await MascotaService.obtenerEstado(usuarioId: widget.usuario.id);
    if (mounted) setState(() => _mascota = e);
  }

  Future<void> _cargarNoLeidos() async {
    final n = await MensajesService.contarNoLeidos(widget.usuario.id);
    if (mounted) setState(() => _noLeidos = n);
  }

  void _abrirMascota() {
    _conEdadYPais(() async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MascotaScreen(usuario: widget.usuario, edadBracket: _edadBracket!, pais: _pais!)));
      _cargarMascota();
    });
  }

  void _abrirBuzon() {
    _conEdadYPais(() async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BuzonScreen(usuario: widget.usuario, edadBracket: _edadBracket!, pais: _pais!)));
      _cargarNoLeidos();
    });
  }

  /// Asegura tener edad/país elegidos (pidiéndolos si hace falta) y recién
  /// entonces ejecuta la acción real. Se reutiliza para solo, sala nueva y
  /// unirse, ya que las tres necesitan lo mismo antes de arrancar.
  void _conEdadYPais(VoidCallback then) {
    if (_edadBracket == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EdadScreen(onSelected: (b) {
        setState(() => _edadBracket = b);
        Navigator.of(context).pop();
        _conEdadYPais(then);
      })));
      return;
    }
    if (_pais == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaisScreen(onSelected: (p) {
        setState(() => _pais = p);
        Navigator.of(context).pop();
        _conEdadYPais(then);
      })));
      return;
    }
    then();
  }

  void _jugarSolo() {
    _conEdadYPais(() {
      final controller = SoloGameController(usuario: widget.usuario, myNombre: _nombre, myEdadBracket: _edadBracket!, myPais: _pais!);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreenSolo(controller: controller)));
    });
  }

  void _crearSala() {
    _conEdadYPais(() async {
      final controller = SalaGameController(usuario: widget.usuario, myNombre: _nombre, myEdadBracket: _edadBracket!, myPais: _pais!);
      try {
        await controller.crearSala();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos conectar con el servidor.')));
        return;
      }
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => WaitingRoomScreen(controller: controller)));
    });
  }

  void _unirseSala() {
    _conEdadYPais(() {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => JoinSalaScreen(usuario: widget.usuario, nombre: _nombre, edadBracket: _edadBracket!, pais: _pais!),
      ));
    });
  }

  void _crearCampanaGrupal() {
    _conEdadYPais(() async {
      final controller = SalaGameController(usuario: widget.usuario, myNombre: _nombre, myEdadBracket: _edadBracket!, myPais: _pais!);
      try {
        await controller.crearSalaCampanaGrupal();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos conectar con el servidor.')));
        return;
      }
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => WaitingRoomScreen(controller: controller)));
    });
  }

  void _desafioGrupal() {
    _conEdadYPais(() {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DesafioGrupalScreen(usuario: widget.usuario, nombre: _nombre, edadBracket: _edadBracket!, pais: _pais!),
      ));
    });
  }

  void _girarRuletaBonus() {
    showDialog(context: context, builder: (_) => RuletaBonusDialog(usuarioId: widget.usuario.id));
  }

  void _tandaCuestionados() {
    _conEdadYPais(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => TandaCuestionadosScreen(edadBracket: _edadBracket!)));
    });
  }

  void _minijuegosBonus() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MinijuegosBonusScreen(usuario: widget.usuario)));
  }

  Future<void> _compartirApp() async {
    await Share.share('🎲 ¡Probá Ocaland conmigo! El juego de la oca con Cuestionados y minijuegos.\n${AppConfig.appUrl}');
    try {
      final r = await EconomyService.recompensaPorCompartir(widget.usuario.id);
      if (!mounted || r == null || r.yaReclamado) return;
      AudioService.coin();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+${r.monedasGanadas} 🪙 por compartir Ocaland')));
    } catch (_) {}
  }

  void _abrirJugar() {
    _pushPanel('🎲 Jugar', [
      _AccionRow(label: '🤖 Jugar solo (contra la bot)', emoji: '🤖', onTap: _jugarSolo),
      _AccionRow(label: 'Crear sala nueva (tanda)', emoji: '🏆', destacado: true, onTap: _crearSala),
      _AccionRow(label: '¿Ya tenés un código? Unirme', emoji: '🔑', onTap: _unirseSala),
      _AccionRow(label: '🏆 Crear campaña grupal (10 etapas, en vivo)', emoji: '🥇', onTap: _crearCampanaGrupal),
      _AccionRow(label: '🎯 Desafío grupal (campañas por separado)', emoji: '🔄', onTap: _desafioGrupal),
    ]);
  }

  void _abrirBonus() {
    _pushPanel('🎁 Bonus', [
      _AccionRow(label: '🎰 Ruleta de bonus diaria (multiplicador)', emoji: '🎰', onTap: _girarRuletaBonus),
      _AccionRow(label: '📲 Compartir Ocaland (+15 🪙 hoy)', emoji: '📲', onTap: _compartirApp),
      _AccionRow(label: '🎯 Tanda de cuestionados (ganá sellos)', emoji: '🎖️', destacado: true, onTap: _tandaCuestionados),
      _AccionRow(label: '🎮 Minijuegos (ganá monedas)', emoji: '🪙', destacado: true, onTap: _minijuegosBonus),
    ]);
  }

  void _abrirCuenta() {
    _pushPanel('👤 Cuenta', [
      _AccionRow(label: '📊 Mi perfil', emoji: '📊', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilScreen(usuario: widget.usuario)))),
      _AccionRow(label: '👥 Mis amigos', emoji: '👥', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AmigosScreen(usuario: widget.usuario)))),
      _AccionRow(label: '🏆 Ranking', emoji: '🏆', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RankingScreen(usuario: widget.usuario)))),
      _AccionRow(label: '🎮 Mis partidas', emoji: '🎮', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MisPartidasScreen(usuario: widget.usuario)))),
    ]);
  }

  /// Empuja una pantalla chica con su propia AppBar (con botón de volver)
  /// mostrando el mismo panel de acciones que antes vivía en una pestaña.
  void _pushPanel(String titulo, List<Widget> filas) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: Text(titulo)),
        body: SafeArea(
          child: Stack(
            children: [
              const _FondoDecorado(),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _panelAcciones(filas),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
        child: Stack(
          children: [
            const _FondoDecorado(),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(icon: const Icon(Icons.mail_outline, color: AppColors.violetDark, size: 26), onPressed: _abrirBuzon),
                      if (_noLeidos > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                            child: Text('$_noLeidos', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.violetDark, size: 28),
                    onSelected: (v) {
                      if (v == 'bonus') _abrirBonus();
                      if (v == 'cuenta') _abrirCuenta();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'bonus', child: Text('🎁 Bonus')),
                      PopupMenuItem(value: 'cuenta', child: Text('👤 Cuenta')),
                    ],
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _TituloDecorado(),
                      const SizedBox(height: 4),
                      Text('👋 ¡Hola de nuevo, $_nombre!', style: const TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 18),
                      if (_mascota != null) _MascotaFaceCaption(estado: _mascota!, onTap: _abrirMascota),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violet,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _abrirJugar,
                          child: const Text('🎲 Jugar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel único con borde redondeado que agrupa todas las acciones de una
  /// sección (antes eran pestañas; ahora cada una es su propia pantalla).
  Widget _panelAcciones(List<Widget> filas) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.violet, width: 3),
        ),
        child: Column(children: filas),
      ),
    );
  }

}

/// Fila de acción del lobby: texto a la izquierda, una "medallita" con
/// emoji decorativo a la derecha. [destacado] resalta la opción principal
/// de cada pestaña con relleno violeta sólido en vez de blanco con borde.
class _AccionRow extends StatelessWidget {
  final String label;
  final String emoji;
  final bool destacado;
  final VoidCallback onTap;
  const _AccionRow({required this.label, required this.emoji, required this.onTap, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: destacado ? AppColors.violet : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: destacado ? null : Border.all(color: AppColors.violet.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: destacado ? Colors.white : AppColors.violetDark),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: destacado ? Colors.white.withValues(alpha: 0.2) : AppColors.parchmentDark,
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 17)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Solo la cara de la Oca (sin caja ni barras) y, debajo, una leyenda
/// corta si necesita algo — nada si está contenta. Tocable para ir a su
/// pantalla completa (ver `mascota_service.dart`).
class _MascotaFaceCaption extends StatelessWidget {
  final EstadoMascota estado;
  final VoidCallback onTap;
  const _MascotaFaceCaption({required this.estado, required this.onTap});

  String? get _leyenda {
    final e = estado;
    if (e.secuestrada) return 'El cazador se la llevó 🏹';
    if (e.durmiendo) return 'Está durmiendo la siesta 💤';
    if (e.hambre < 30) return 'Tiene hambre 🍽️';
    if (e.diversion < 30) return 'Está aburrida 🎾';
    if (e.sueno < 30) return 'Tiene sueño 💤';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final leyenda = _leyenda;
    return InkWell(
      borderRadius: BorderRadius.circular(60),
      onTap: onTap,
      child: Column(
        children: [
          estado.secuestrada ? const Text('🏹', style: TextStyle(fontSize: 68)) : OcaFace(estado: estado, size: 88),
          if (leyenda != null) ...[
            const SizedBox(height: 4),
            Text(leyenda, style: const TextStyle(fontSize: 12.5, color: AppColors.violetDark, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

/// "Ocaland" con adornitos alrededor (dado, ficha, cintita, estrella) para
/// que la pantalla de entrada se sienta más festiva.
class _TituloDecorado extends StatelessWidget {
  const _TituloDecorado();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: const [
          Positioned(left: 4, top: 2, child: Text('🎲', style: TextStyle(fontSize: 20))),
          Positioned(right: 2, top: -4, child: Text('🏅', style: TextStyle(fontSize: 18))),
          Positioned(right: 26, bottom: -2, child: Text('⭐', style: TextStyle(fontSize: 14))),
          Positioned(left: 28, bottom: -4, child: Text('🎉', style: TextStyle(fontSize: 16))),
          Center(child: Text('Ocaland', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.violetDark))),
        ],
      ),
    );
  }
}

/// Elementos decorativos sueltos en las esquinas de la pantalla (dados,
/// fichas, confeti) para darle un marco más festivo al lobby, sin estorbar
/// el contenido — muy sutiles (opacidad baja) para no distraer.
class _FondoDecorado extends StatelessWidget {
  const _FondoDecorado();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.16,
        child: Stack(
          children: const [
            Positioned(left: -6, top: 40, child: Text('🎲', style: TextStyle(fontSize: 36))),
            Positioned(right: -4, top: 30, child: Text('🔺', style: TextStyle(fontSize: 30))),
            Positioned(left: 10, bottom: 90, child: Text('🎉', style: TextStyle(fontSize: 32))),
            Positioned(right: 14, bottom: 100, child: Text('♟️', style: TextStyle(fontSize: 34))),
          ],
        ),
      ),
    );
  }
}
