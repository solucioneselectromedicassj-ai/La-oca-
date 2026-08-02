import 'package:flutter/material.dart';
import '../../models/jugador.dart';
import '../../theme/app_colors.dart';

class JugadoresStatusRow extends StatelessWidget {
  final List<JugadorPartida> jugadores;
  const JugadoresStatusRow({super.key, required this.jugadores});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < jugadores.length; i++)
          Builder(builder: (context) {
            final j = jugadores[i];
            final color = AppColors.tokenColors[i % AppColors.tokenColors.length];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.13), border: Border.all(color: color), borderRadius: BorderRadius.circular(12)),
              child: Text('${j.nombre}${j.saltaTurno ? " ⛓️" : ""} · #${j.posicion}', style: const TextStyle(fontSize: 11.5)),
            );
          }),
      ],
    );
  }
}
