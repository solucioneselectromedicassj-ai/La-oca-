import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../theme/app_colors.dart';
import 'edad_screen.dart';
import 'game_screen_solo.dart';
import 'pais_screen.dart';

/// Lobby simplificado: el modo solo (campaña de 10 etapas vs bot) está
/// activo y jugable. Los modos multijugador (sala normal, campaña grupal,
/// desafío grupal) y las pestañas de Bonus/Cuenta todavía no están
/// conectados — quedan para las próximas fases (ver plan de trabajo).
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

  @override
  void initState() {
    super.initState();
    _edadBracket = widget.edadBracket;
    _pais = widget.pais;
  }

  String get _nombre => widget.nombre ?? widget.usuario.nombre;

  void _jugarSolo() {
    if (_edadBracket == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EdadScreen(onSelected: (b) {
        setState(() => _edadBracket = b);
        Navigator.of(context).pop();
        _jugarSolo();
      })));
      return;
    }
    if (_pais == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaisScreen(onSelected: (p) {
        setState(() => _pais = p);
        Navigator.of(context).pop();
        _jugarSolo();
      })));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreenSolo(usuario: widget.usuario, nombre: _nombre, edadBracket: _edadBracket!, pais: _pais!),
    ));
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
              _proximamente('Crear sala nueva (tanda)'),
              _proximamente('🏆 Crear campaña grupal (10 etapas, en vivo)'),
              _proximamente('Unirme con un código'),
              _proximamente('🎯 Desafío grupal (campañas por separado)'),
            ],
          ),
        );
      case 1:
        return const _ProximamentePanel(texto: 'La ruleta de bonus diaria y compartir la app llegan en la próxima fase.');
      default:
        return const _ProximamentePanel(texto: 'Perfil, ranking y "mis partidas" llegan en la próxima fase.');
    }
  }

  Widget _proximamente(String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.black45))),
            const Text('Próximamente', style: TextStyle(fontSize: 11, color: AppColors.magenta, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ProximamentePanel extends StatelessWidget {
  final String texto;
  const _ProximamentePanel({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(texto, textAlign: TextAlign.center)));
  }
}
