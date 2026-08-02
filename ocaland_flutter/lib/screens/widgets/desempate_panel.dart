import 'package:flutter/material.dart';
import '../../models/jugador.dart';
import '../../theme/app_colors.dart';

class DesempatePanel extends StatelessWidget {
  final List<String> pendientesIds;
  final List<JugadorPartida> jugadores;

  const DesempatePanel({super.key, required this.pendientesIds, required this.jugadores});

  @override
  Widget build(BuildContext context) {
    final nombres = pendientesIds.map((id) {
      final match = jugadores.where((j) => j.id == id);
      return match.isEmpty ? '?' : match.first.nombre;
    }).join(', ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Text('🎯 Desempate entre: $nombres', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w600)),
    );
  }
}
