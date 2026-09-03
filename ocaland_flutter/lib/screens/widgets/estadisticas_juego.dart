import 'package:flutter/material.dart';
import '../../services/preferencias_service.dart';

/// Fila compacta con el historial de un juego (partidas jugadas,
/// victorias y mejor tiempo si aplica) — pedido explícito: "historial de
/// juegos... que gustan tanto". Se vuelve a leer cada vez que cambia
/// `refresco` (subir un contador después de cada partida alcanza para
/// que se actualice sin tener que salir y volver a entrar).
class EstadisticasJuego extends StatelessWidget {
  final String juego;
  final int refresco;
  const EstadisticasJuego({super.key, required this.juego, this.refresco = 0});

  String _formatearTiempo(int segundos) {
    final m = segundos ~/ 60;
    final s = segundos % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(refresco),
      future: PreferenciasService.obtenerEstadisticasJuego(juego),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const {};
        final jugadas = stats['jugadas'] as int? ?? 0;
        if (jugadas == 0) return const SizedBox.shrink();
        final victorias = stats['victorias'] as int? ?? 0;
        final mejorTiempo = stats['mejorTiempo'] as int?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              Text('🎮 $jugadas jugadas', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
              Text('🏆 $victorias ganadas', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
              if (mejorTiempo != null)
                Text('⏱️ mejor ${_formatearTiempo(mejorTiempo)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
            ],
          ),
        );
      },
    );
  }
}
