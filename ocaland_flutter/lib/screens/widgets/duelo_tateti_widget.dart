import 'package:flutter/material.dart';
import '../../services/sala_game_controller.dart';
import '../../theme/app_colors.dart';

/// Duelo 1 contra 1 de Ta-Te-Ti entre los dos jugadores que están
/// esperando su turno del tablero — pedido explícito del usuario:
/// "cuando a uno le toca esperar, salte un juego uno contra uno...
/// no dependa de cuántos jueguen". Se arma solo entre los dos primeros
/// en espera; si hay más jugadores esperando, los demás lo ven como
/// espectadores (y pasan a jugarlo cuando les toque esperar a ellos).
class DueloTatetiWidget extends StatelessWidget {
  final SalaGameController controller;
  const DueloTatetiWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (!c.dueloVisible) return const SizedBox.shrink();
    final jx = c.dueloJugadorX!;
    final jo = c.dueloJugadorO!;
    final soyParte = c.soyDueloX || c.soyDueloO;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('⚔️ Duelo mientras esperan: ❌ ${jx.nombre} vs ⭕ ${jo.nombre}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(_textoEstado(c), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SizedBox(
            width: 150,
            height: 150,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (var i = 0; i < 9; i++) _celda(c, i)],
              ),
            ),
          ),
          if (c.dueloGanador != null && soyParte) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: c.reiniciarDuelo,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: const Text('🔁 Revancha', style: TextStyle(fontSize: 11.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _textoEstado(SalaGameController c) {
    if (c.dueloGanador == 'empate') return '🤝 ¡Empate!';
    if (c.dueloGanador == 'X') return '🎉 ¡Ganó ${c.dueloJugadorX!.nombre}!';
    if (c.dueloGanador == 'O') return '🎉 ¡Ganó ${c.dueloJugadorO!.nombre}!';
    if (c.dueloEsMiTurno) return 'Tu jugada';
    final quien = c.dueloTurnoX ? c.dueloJugadorX!.nombre : c.dueloJugadorO!.nombre;
    return 'Turno de $quien';
  }

  Widget _celda(SalaGameController c, int i) {
    final valor = c.dueloCeldas[i];
    final destacada = c.dueloLineaGanadora?.contains(i) ?? false;
    return GestureDetector(
      onTap: () => c.tocarDuelo(i),
      child: Container(
        decoration: BoxDecoration(
          color: destacada ? AppColors.gold.withValues(alpha: 0.4) : AppColors.parchmentDark,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          valor ?? '',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valor == 'X' ? AppColors.violetDark : AppColors.coral),
        ),
      ),
    );
  }
}
