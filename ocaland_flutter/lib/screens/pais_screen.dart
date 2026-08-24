import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PaisScreen extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const PaisScreen({super.key, required this.onSelected});

  static const _paises = [
    ('argentina', '🇦🇷 Argentina'),
    ('chile', '🇨🇱 Chile'),
    ('otros', '🌎 Otro / Internacional'),
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
                      const Text('¿De qué país sos? Así te tiramos preguntas de cultura local además de las generales.'),
                      const SizedBox(height: 12),
                      for (final p in _paises)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => onSelected(p.$1),
                              child: Align(alignment: Alignment.centerLeft, child: Text(p.$2)),
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
