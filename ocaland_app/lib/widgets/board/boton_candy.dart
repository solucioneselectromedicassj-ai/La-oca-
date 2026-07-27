import 'package:flutter/material.dart';

/// Botón "gomita" tipo Candy Crush: capa de sombra sólida debajo +
/// capa principal con degradé claro-oscuro y borde blanco, para que se
/// vea con relieve en vez de un botón Material plano.
class BotonCandy extends StatelessWidget {
  const BotonCandy({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.color,
    this.onPressed,
  });

  final IconData icono;
  final String etiqueta;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null;
    final base = habilitado ? color : Colors.grey.shade400;
    final hsl = HSLColor.fromColor(base);
    final sombra = hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
    final claro = hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0)).toColor();

    return Opacity(
      opacity: habilitado ? 1 : 0.6,
      child: SizedBox(
        width: 230,
        height: 62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: sombra,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [claro, base],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icono, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          etiqueta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
