import 'package:flutter/material.dart';

class FinPartidaPanel extends StatelessWidget {
  final String mensaje;
  final bool mostrarRevancha;
  final String labelRevancha;
  final VoidCallback onRevancha;
  final bool mostrarNuevaTanda;
  final VoidCallback onNuevaTanda;
  final bool mostrarJugarOtra;
  final VoidCallback onJugarOtra;

  const FinPartidaPanel({
    super.key,
    required this.mensaje,
    required this.mostrarRevancha,
    required this.labelRevancha,
    required this.onRevancha,
    required this.mostrarNuevaTanda,
    required this.onNuevaTanda,
    required this.mostrarJugarOtra,
    required this.onJugarOtra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]),
      child: Column(
        children: [
          Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (mostrarRevancha) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onRevancha, child: Text(labelRevancha))),
          if (mostrarNuevaTanda) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onNuevaTanda, child: const Text('🏁 Nueva tanda (0-0)'))),
          if (mostrarJugarOtra)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onJugarOtra, child: const Text('🔄 Jugar otra partida (sala nueva)'))),
            ),
        ],
      ),
    );
  }
}
