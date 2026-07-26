/// Espeja la tabla `la_vuelta.desafios_grupales`.
class DesafioGrupal {
  final String id;
  final String codigo;
  final DateTime creadoEn;

  const DesafioGrupal({
    required this.id,
    required this.codigo,
    required this.creadoEn,
  });

  factory DesafioGrupal.fromMap(Map<String, dynamic> map) {
    return DesafioGrupal(
      id: map['id'] as String,
      codigo: map['codigo'] as String,
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}

/// Espeja la tabla `la_vuelta.desafios_resultados`.
class DesafioResultado {
  final String id;
  final String desafioId;
  final String? usuarioId;
  final String nombre;
  final int etapasCompletadas;
  final int? msTotal;
  final DateTime completadoEn;

  const DesafioResultado({
    required this.id,
    required this.desafioId,
    required this.nombre,
    required this.etapasCompletadas,
    required this.completadoEn,
    this.usuarioId,
    this.msTotal,
  });

  factory DesafioResultado.fromMap(Map<String, dynamic> map) {
    return DesafioResultado(
      id: map['id'] as String,
      desafioId: map['desafio_id'] as String,
      usuarioId: map['usuario_id'] as String?,
      nombre: map['nombre'] as String,
      etapasCompletadas: map['etapas_completadas'] as int? ?? 0,
      msTotal: map['ms_total'] as int?,
      completadoEn: DateTime.parse(map['completado_en'] as String),
    );
  }
}
