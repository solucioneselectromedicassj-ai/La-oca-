import 'package:flutter/material.dart';

enum TipoItemPersonalizacion { silueta, color, accesorio }

TipoItemPersonalizacion tipoItemFromDb(String value) {
  switch (value) {
    case 'color':
      return TipoItemPersonalizacion.color;
    case 'accesorio':
      return TipoItemPersonalizacion.accesorio;
    default:
      return TipoItemPersonalizacion.silueta;
  }
}

/// Espeja una fila de `la_vuelta.personalizacion_catalogo`.
class ItemPersonalizacion {
  const ItemPersonalizacion({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.precio,
    required this.gratis,
    this.colorHex,
    this.siluetaId,
  });

  final String id;
  final TipoItemPersonalizacion tipo;
  final String nombre;
  final int precio;
  final bool gratis;
  final String? colorHex;

  /// Solo para tipo `color`: a qué silueta pertenece este skin (los
  /// colores son variantes de arte completo por silueta, no un tinte
  /// universal — ver docs/SPEC_VISUAL_V2.md sección 9).
  final String? siluetaId;

  Color? get color {
    if (colorHex == null) return null;
    return Color(int.parse('FF$colorHex', radix: 16));
  }

  factory ItemPersonalizacion.fromMap(Map<String, dynamic> map) {
    return ItemPersonalizacion(
      id: map['id'] as String,
      tipo: tipoItemFromDb(map['tipo'] as String),
      nombre: map['nombre'] as String,
      precio: map['precio'] as int? ?? 0,
      gratis: map['gratis'] as bool? ?? false,
      colorHex: map['color_hex'] as String?,
      siluetaId: map['silueta_id'] as String?,
    );
  }
}
