import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/usuario.dart';
import '../services/economy_service.dart';
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
import 'waiting_room_screen.dart';
import 'widgets/ruleta_bonus_dialog.dart';

/// Lobby: todos los modos (solo, sala normal, campaña grupal en vivo,
/// desafío grupal) y toda la cuenta/economía ya están activos.
class LobbyScreen extends StatefulWidget {
  final Usuario usuario;
  final String? nombre;
  final String? edadBracket;
  final String? pais;

  const LobbyScreen({super.key, required this.usuario, this.nombre, this.edadBracket, this.pais});

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
    // Recompensa por tiempo activo en la app (hitos a los 5/15/30 min), igual que el prototipo.
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) async {
      try {
        final r = await EconomyService.registrarMinutoActivo(widget.usuario.id);
        if (mounted && r != null && r.huboPremio) {
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

  Future<void> _compartirApp() async {
    await Share.share('🎲 ¡Probá Ocaland conmigo! El juego de la oca con Cuestionados y minijuegos.');
    try {
      final r = await EconomyService.recompensaPorCompartir(widget.usuario.id);
      if (!mounted || r == null || r.yaReclamado) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+${r.monedasGanadas} 🪙 por compartir Ocaland')));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Ocaland', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
                  Text('👋 ¡Hola de nuevo, $_nombre!', style: const TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _tabButton('🎲 Jugar', 0),
                      const SizedBox(width: 6),
                      _tabButton('🎰 Bonus', 1),
                      const SizedBox(width: 6),
                      _tabButton('👤 Cuenta', 2),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: _tabContent()),
                ],
              ),
            ),
          ),
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
        ),
        onPressed: () => setState(() => _tab = idx),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: _jugarSolo, child: const Text('🤖 Jugar solo (contra la bot)')),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _crearSala, child: const Text('Crear sala nueva (tanda)'))),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _unirseSala, child: const Text('¿Ya tenés un código? Unirme'))),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _crearCampanaGrupal, child: const Text('🏆 Crear campaña grupal (10 etapas, en vivo)'))),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _desafioGrupal, child: const Text('🎯 Desafío grupal (campañas por separado)'))),
                ),
              ),
            ],
          ),
        );
      case 1:
        return SingleChildScrollView(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _girarRuletaBonus, child: const Text('🎰 Ruleta de bonus diaria (multiplicador)'))),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _compartirApp, child: const Text('📲 Compartir Ocaland (+15 🪙 hoy)'))),
                ],
              ),
            ),
          ),
        );
      default:
        return SingleChildScrollView(
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilScreen(usuario: widget.usuario))), child: const Text('📊 Mi perfil'))),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RankingScreen(usuario: widget.usuario))), child: const Text('🏆 Ranking'))),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MisPartidasScreen(usuario: widget.usuario))), child: const Text('🎮 Mis partidas'))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

}
