import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../app_config.dart';
import '../models/usuario.dart';
import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../services/pending_rewards_service.dart';
import '../services/sala_game_controller.dart';
import '../services/solo_game_controller.dart';
import '../theme/app_colors.dart';
import 'desafio_grupal_screen.dart';
import 'edad_screen.dart';
import 'game_screen_solo.dart';
import 'join_sala_screen.dart';
import 'mis_partidas_screen.dart';
import 'pais_screen.dart';
import 'perfil_screen.dart';
import 'ranking_screen.dart';
import 'tanda_cuestionados_screen.dart';
import 'waiting_room_screen.dart';
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
  int _tab = 0;
  String? _edadBracket;
  String? _pais;
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    _edadBracket = widget.edadBracket;
    _pais = widget.pais;
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

  Future<void> _compartirApp() async {
    await Share.share('🎲 ¡Probá Ocaland conmigo! El juego de la oca con Cuestionados y minijuegos.\n${AppConfig.appUrl}');
    try {
      final r = await EconomyService.recompensaPorCompartir(widget.usuario.id);
      if (!mounted || r == null || r.yaReclamado) return;
      AudioService.coin();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+${r.monedasGanadas} 🪙 por compartir Ocaland')));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
        child: Stack(
          children: [
            const _FondoDecorado(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      const _TituloDecorado(),
                      const SizedBox(height: 4),
                      Text('👋 ¡Hola de nuevo, $_nombre!', style: const TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _tabButton('🎲 Jugar', 0),
                          const SizedBox(width: 6),
                          _tabButton('🎁 Bonus', 1),
                          const SizedBox(width: 6),
                          _tabButton('👤 Cuenta', 2),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _tabContent()),
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

  Widget _tabButton(String label, int idx) {
    final active = _tab == idx;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? AppColors.violet : Colors.white,
          foregroundColor: active ? Colors.white : AppColors.violetDark,
          side: const BorderSide(color: AppColors.violet, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: () => setState(() => _tab = idx),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0:
        return _panelAcciones([
          _AccionRow(label: '🤖 Jugar solo (contra la bot)', emoji: '🤖', onTap: _jugarSolo),
          _AccionRow(label: 'Crear sala nueva (tanda)', emoji: '🏆', destacado: true, onTap: _crearSala),
          _AccionRow(label: '¿Ya tenés un código? Unirme', emoji: '🔑', onTap: _unirseSala),
          _AccionRow(label: '🏆 Crear campaña grupal (10 etapas, en vivo)', emoji: '🥇', onTap: _crearCampanaGrupal),
          _AccionRow(label: '🎯 Desafío grupal (campañas por separado)', emoji: '🔄', onTap: _desafioGrupal),
        ]);
      case 1:
        return _panelAcciones([
          _AccionRow(label: '🎰 Ruleta de bonus diaria (multiplicador)', emoji: '🎰', onTap: _girarRuletaBonus),
          _AccionRow(label: '📲 Compartir Ocaland (+15 🪙 hoy)', emoji: '📲', onTap: _compartirApp),
          _AccionRow(label: '🎯 Tanda de cuestionados (ganá sellos)', emoji: '🎖️', destacado: true, onTap: _tandaCuestionados),
        ]);
      default:
        return _panelAcciones([
          _AccionRow(label: '📊 Mi perfil', emoji: '📊', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilScreen(usuario: widget.usuario)))),
          _AccionRow(label: '🏆 Ranking', emoji: '🏆', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RankingScreen(usuario: widget.usuario)))),
          _AccionRow(label: '🎮 Mis partidas', emoji: '🎮', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MisPartidasScreen(usuario: widget.usuario)))),
        ]);
    }
  }

  /// Panel único con borde redondeado que agrupa todas las acciones de la
  /// pestaña actual (antes era una `Card` separada por botón).
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
