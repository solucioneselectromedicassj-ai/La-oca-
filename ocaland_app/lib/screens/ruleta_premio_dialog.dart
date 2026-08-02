import 'dart:math';

import 'package:flutter/material.dart';

import '../game/campana/comodin_ruleta.dart';
import '../widgets/ruleta/ruleta_widget.dart';

/// Ruleta de premio entre etapas (sección 9): da un comodín real al
/// arrancar la próxima etapa.
class RuletaPremioDialog extends StatefulWidget {
  const RuletaPremioDialog({super.key});

  static Future<PremioRuleta> mostrar(BuildContext context) async {
    final resultado = await showDialog<PremioRuleta>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RuletaPremioDialog(),
    );
    return resultado ?? RuletaPremios.segmentos.last;
  }

  @override
  State<RuletaPremioDialog> createState() => _RuletaPremioDialogState();
}

class _RuletaPremioDialogState extends State<RuletaPremioDialog> {
  late final int _indiceGanador = Random().nextInt(RuletaPremios.segmentos.length);
  bool _terminado = false;

  PremioRuleta get _premio => RuletaPremios.segmentos[_indiceGanador];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¡Ruleta de premio!'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RuletaWidget(
              indiceObjetivo: _indiceGanador,
              totalSegmentos: RuletaPremios.segmentos.length,
              tamano: 220,
              onTerminarGiro: () {
                if (mounted) setState(() => _terminado = true);
              },
            ),
            const SizedBox(height: 12),
            if (_terminado) ...[
              Text(
                _premio.nombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_premio),
                child: const Text('Continuar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
