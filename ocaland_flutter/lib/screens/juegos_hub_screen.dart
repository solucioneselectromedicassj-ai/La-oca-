import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ahorcado_screen.dart';
import 'sudoku_screen.dart';
import 'tateti_screen.dart';

class _JuegoInfo {
  final String emoji;
  final String nombre;
  final Color color;
  final bool textoOscuro;
  final WidgetBuilder? builder;
  const _JuegoInfo(this.emoji, this.nombre, this.color, {this.textoOscuro = false, this.builder});
}

/// Zona de juegos: reemplaza a los minijuegos de reflejos/memoria del
/// tablero como actividad de "Jugar con ella" — un puñado de juegos
/// clásicos bien distintos entre sí, con más variedad que solo dos
/// minijuegos repetidos. Se va a ir completando de a uno; los que
/// todavía no están armados se muestran atenuados como "Próximamente".
class JuegosHubScreen extends StatelessWidget {
  final String usuarioId;
  final String nivel;
  const JuegosHubScreen({super.key, required this.usuarioId, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final juegos = [
      _JuegoInfo('❌⭕', 'Ta-Te-Ti', AppColors.turquoise, builder: (_) => TatetiScreen(usuarioId: usuarioId)),
      _JuegoInfo('🔤', 'Ahorcado', AppColors.coral, builder: (_) => AhorcadoScreen(usuarioId: usuarioId, nivel: nivel)),
      _JuegoInfo('🔢', 'Sudoku', AppColors.indigo, builder: (_) => SudokuScreen(usuarioId: usuarioId, nivel: nivel)),
      _JuegoInfo('🧩', 'Rompecabezas', AppColors.magenta),
      _JuegoInfo('💣', 'Buscaminas', AppColors.gold, textoOscuro: true),
      _JuegoInfo('🎯', '2048', AppColors.sky),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🎮 Zona de juegos')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [for (final j in juegos) _JuegoCard(info: j)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JuegoCard extends StatelessWidget {
  final _JuegoInfo info;
  const _JuegoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final disponible = info.builder != null;
    final textColor = info.textoOscuro ? AppColors.violetDark : Colors.white;
    return Material(
      color: disponible ? info.color : info.color.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (disponible) {
            Navigator.of(context).push(MaterialPageRoute(builder: info.builder!));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚧 Lo estamos armando — ¡ya llega!')));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(info.nombre, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              if (!disponible) ...[
                const SizedBox(height: 4),
                Text('Próximamente', style: TextStyle(fontSize: 10.5, color: textColor.withValues(alpha: 0.85))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
