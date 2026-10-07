import 'package:flutter/material.dart';
import '../../models/tetris_eleccion_desafio.dart';
import '../../theme/app_colors.dart';

/// UI reusable para el mini-desafío de Tetris ("¿en qué columna encaja?")
/// en el medidor y el chequeo de turno.
class TetrisEleccionWidget extends StatelessWidget {
  final TetrisEleccionDesafio desafio;
  final int segundos;
  final ValueChanged<int> onResponder;
  final bool compacto;
  const TetrisEleccionWidget({super.key, required this.desafio, required this.segundos, required this.onResponder, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final colorTexto = compacto ? Colors.white : AppColors.fuchsia;
    final lado = compacto ? 26.0 : 40.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('⏱️ ${segundos}s', style: TextStyle(color: colorTexto, fontSize: compacto ? 11 : 14, fontWeight: FontWeight.bold)),
        SizedBox(height: compacto ? 4 : 10),
        Text('🧱 ¿Dónde encaja la pieza?', style: TextStyle(fontSize: compacto ? 11 : 14, fontWeight: FontWeight.bold, color: compacto ? Colors.white : AppColors.violetDark)),
        SizedBox(height: compacto ? 6 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < TetrisEleccionDesafio.ancho; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              SizedBox(
                width: lado,
                height: lado,
                child: i == desafio.columnaHueco
                    ? DecoratedBox(
                        decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2, style: BorderStyle.solid), borderRadius: BorderRadius.circular(6)),
                      )
                    : DecoratedBox(decoration: BoxDecoration(color: AppColors.violet, borderRadius: BorderRadius.circular(6))),
              ),
            ],
          ],
        ),
        SizedBox(height: compacto ? 8 : 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < TetrisEleccionDesafio.ancho; i++)
              SizedBox(
                width: lado,
                height: lado,
                child: Material(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onResponder(i),
                    child: Center(child: Text('${i + 1}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: compacto ? 13 : 16))),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
