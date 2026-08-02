import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'memoria_widget.dart';
import 'reflejos_widget.dart';
import 'trivia_overlay.dart';

class MinijuegoOverlay extends StatelessWidget {
  final String titulo;
  final String tipo; // 'reflejos' | 'memoria'
  final ValueChanged<bool> onDone;

  const MinijuegoOverlay({super.key, required this.titulo, required this.tipo, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 10),
          if (tipo == 'reflejos') ReflejosWidget(onDone: onDone) else MemoriaWidget(onDone: onDone),
        ],
      ),
    );
  }
}
