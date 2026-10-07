import 'package:flutter/material.dart';
import '../../models/flecha_desafio.dart';
import '../../theme/app_colors.dart';

/// UI reusable para el desafío de "sacar la flecha" — pedido explícito
/// para reemplazar Cuestionados (y reflejos/memoria) en los juegos de
/// espera, así no es siempre lo mismo: una flecha grande apuntando a una
/// dirección al azar, con 4 botones para responder. Se usa tanto en el
/// panel chico del medidor (dentro del tablero) como en el chequeo de
/// turno (overlay de pantalla completa).
class FlechaDesafioWidget extends StatelessWidget {
  final FlechaDesafio desafio;
  final int segundos;
  final ValueChanged<Direccion> onResponder;
  final bool compacto;
  const FlechaDesafioWidget({super.key, required this.desafio, required this.segundos, required this.onResponder, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final tamanoFlecha = compacto ? 26.0 : 52.0;
    final tamanoBoton = compacto ? 32.0 : 50.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('⏱️ ${segundos}s', style: TextStyle(color: compacto ? Colors.white : AppColors.fuchsia, fontSize: compacto ? 11 : 14, fontWeight: FontWeight.bold)),
        SizedBox(height: compacto ? 4 : 10),
        Text(desafio.emoji, style: TextStyle(fontSize: tamanoFlecha)),
        SizedBox(height: compacto ? 6 : 14),
        _botones(tamanoBoton),
      ],
    );
  }

  Widget _botones(double tamano) {
    Widget boton(Direccion d, IconData icono) => SizedBox(
          width: tamano,
          height: tamano,
          child: Material(
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onResponder(d),
              child: Icon(icono, color: Colors.white, size: tamano * 0.55),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        boton(Direccion.arriba, Icons.keyboard_arrow_up),
        SizedBox(height: tamano * 0.15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            boton(Direccion.izquierda, Icons.keyboard_arrow_left),
            SizedBox(width: tamano * 0.15),
            boton(Direccion.abajo, Icons.keyboard_arrow_down),
            SizedBox(width: tamano * 0.15),
            boton(Direccion.derecha, Icons.keyboard_arrow_right),
          ],
        ),
      ],
    );
  }
}
