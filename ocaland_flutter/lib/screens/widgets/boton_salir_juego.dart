import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Botón fijo (no dentro del scroll) para salir de la partida — antes
/// vivía al final de una columna larga con el tablero y quedaba
/// prácticamente invisible salvo que se scrolleara hasta el fondo.
class BotonSalirJuego extends StatelessWidget {
  final VoidCallback onTap;
  const BotonSalirJuego({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.close, color: AppColors.violetDark, size: 22),
        ),
      ),
    );
  }
}
