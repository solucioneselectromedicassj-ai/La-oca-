import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pregunta simple (solo la primera vez) para saber qué tan difíciles
/// mostrar los juegos de la Zona de juegos — a propósito más sencilla que
/// la franja de edad de Cuestionados (pedido explícito: "creo que este es
/// más sencillo").
class NivelJuegosScreen extends StatelessWidget {
  const NivelJuegosScreen({super.key});

  static const _niveles = [
    ('menor', '🧒 Menor de 12 años'),
    ('adolescente', '🧑 Adolescente (13 a 17)'),
    ('adulto', '🧑‍🦱 Adulto (18 o más)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎮', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text(
                          '¿Qué edad tenés? Así te mostramos los juegos con la dificultad justa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.violetDark, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 14),
                        for (final n in _niveles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(n.$1),
                                child: Align(alignment: Alignment.centerLeft, child: Text(n.$2)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
