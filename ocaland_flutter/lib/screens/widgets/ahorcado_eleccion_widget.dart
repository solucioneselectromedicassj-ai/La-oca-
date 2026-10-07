import 'package:flutter/material.dart';
import '../../models/ahorcado_eleccion_desafio.dart';
import '../../theme/app_colors.dart';

/// UI reusable para el mini-desafío de Ahorcado ("¿cuál es la letra que
/// falta?") en el medidor y el chequeo de turno.
class AhorcadoEleccionWidget extends StatelessWidget {
  final AhorcadoEleccionDesafio desafio;
  final int segundos;
  final ValueChanged<String> onResponder;
  final bool compacto;
  const AhorcadoEleccionWidget({super.key, required this.desafio, required this.segundos, required this.onResponder, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final colorTexto = compacto ? Colors.white : AppColors.fuchsia;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('⏱️ ${segundos}s', style: TextStyle(color: colorTexto, fontSize: compacto ? 11 : 14, fontWeight: FontWeight.bold)),
        SizedBox(height: compacto ? 4 : 10),
        Text('🔤 ${desafio.textoConHueco}', style: TextStyle(fontSize: compacto ? 20 : 30, fontWeight: FontWeight.bold, letterSpacing: 3, color: compacto ? Colors.white : AppColors.violetDark)),
        SizedBox(height: compacto ? 6 : 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final letra in desafio.opciones)
              SizedBox(
                width: compacto ? 32 : 46,
                height: compacto ? 32 : 46,
                child: Material(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onResponder(letra),
                    child: Center(child: Text(letra, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: compacto ? 14 : 18))),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
