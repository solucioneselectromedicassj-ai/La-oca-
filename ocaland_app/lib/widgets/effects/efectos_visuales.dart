import 'package:flutter/material.dart';

import 'ciclo_sprite_overlay.dart';
import 'confeti_overlay.dart';
import 'destello_estrellas.dart';
import 'monedas_ganadas_flotante.dart';

/// Punto de entrada único para disparar efectos de feedback visual
/// (spec visual v2, sección 5) sobre la pantalla actual, vía `Overlay`.
class EfectosVisuales {
  EfectosVisuales._();

  static void mostrarEstrellas(BuildContext context) {
    _mostrarOverlay(context, (remover) => DestelloEstrellas(onTerminado: remover));
  }

  static void mostrarConfeti(BuildContext context) {
    _mostrarOverlay(context, (remover) => ConfetiOverlay(onTerminado: remover));
  }

  static void mostrarMonedasGanadas(BuildContext context, int cantidad) {
    _mostrarOverlay(
      context,
      (remover) => MonedasGanadasFlotante(cantidad: cantidad, onTerminado: remover),
    );
  }

  /// Festejo/salto del avatar al ganar una etapa/partida (spec visual v2,
  /// sección 5). No hace nada si `frames` es null (silueta sin arte real).
  static void mostrarFestejo(BuildContext context, List<String>? frames) {
    if (frames == null || frames.isEmpty) return;
    _mostrarOverlay(
      context,
      (remover) => CicloSpriteOverlay(frames: frames, onTerminado: remover, alto: 180),
    );
  }

  /// Reacción de sorpresa/susto al fallar Cuestionados en una trampa.
  static void mostrarReaccion(BuildContext context, List<String>? frames) {
    if (frames == null || frames.isEmpty) return;
    _mostrarOverlay(
      context,
      (remover) => CicloSpriteOverlay(
        frames: frames,
        onTerminado: remover,
        alto: 140,
        porFrame: const Duration(milliseconds: 450),
      ),
    );
  }

  static void _mostrarOverlay(
    BuildContext context,
    Widget Function(VoidCallback remover) builder,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: builder(() {
          if (entry.mounted) entry.remove();
        }),
      ),
    );
    overlay.insert(entry);
  }
}
