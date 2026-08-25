import 'package:flutter/material.dart';
import '../../models/jugador.dart';
import '../../theme/app_colors.dart';

/// Panel de sorteo de turno: muestra la tirada de dado de cada jugador
/// y corona al ganador. Se queda visible varios segundos (Pacing.sorteoDisplay)
/// para que se pueda seguir, a pedido del usuario.
class SorteoPanel extends StatelessWidget {
  final List<JugadorPartida> jugadores;
  final Map<String, int> tiradas;
  final String? ganadorId;

  /// Si no es null, ese jugador tiene que tocar su fila para tirar su
  /// propio dado (en vez de que el sorteo salga ya resuelto) — pedido del
  /// usuario para que el sorteo sea más entretenido.
  final String? esperandoTapDeId;
  final VoidCallback? onTirar;

  const SorteoPanel({super.key, required this.jugadores, required this.tiradas, required this.ganadorId, this.esperandoTapDeId, this.onTirar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]),
      child: Column(
        children: [
          const Text('🎲 Sorteo de turno', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 6),
          for (final j in jugadores)
            if (j.id == esperandoTapDeId)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.violetDark),
                    onPressed: onTirar,
                    child: Text('🎲 ¡Tocá para tirar tu dado, ${j.nombre}!'),
                  ),
                ),
              )
            else
              Text(
                '${j.id == ganadorId ? "👑" : "🎲"} ${j.nombre}: ${tiradas[j.id] ?? "..."} ${j.id == ganadorId ? "¡empieza!" : ""}',
                style: TextStyle(fontWeight: j.id == ganadorId ? FontWeight.bold : FontWeight.normal),
              ),
        ],
      ),
    );
  }
}
