import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EdadScreen extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const EdadScreen({super.key, required this.onSelected});

  static const _brackets = [
    ('ninos', '7 a 12 años'),
    ('adolescentes', '13 a 17 años'),
    ('jovenes', '18 a 25 años'),
    ('adultos', '26 a 45 años'),
    ('adultos_plus', '46 a 59 años'),
    ('mayores', '60 años o más'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
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
                      const Text('¿Qué edad tenés? Así ajustamos las preguntas de trivia.'),
                      const SizedBox(height: 12),
                      for (final b in _brackets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => onSelected(b.$1),
                              child: Align(alignment: Alignment.centerLeft, child: Text(b.$2)),
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
    );
  }
}
