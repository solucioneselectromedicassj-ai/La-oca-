/// Fila de `grupos`: un grupo de amigos consolidado para invitar de una
/// sola vez a un desafío grupal.
class Grupo {
  final String id;
  final String nombre;

  const Grupo({required this.id, required this.nombre});

  factory Grupo.fromJson(Map<String, dynamic> j) => Grupo(id: j['id'] as String, nombre: j['nombre'] as String);
}

/// Fila de `grupo_miembros`.
class GrupoMiembro {
  final String id;
  final String amigoUsuarioId;
  final String apodo;

  const GrupoMiembro({required this.id, required this.amigoUsuarioId, required this.apodo});

  factory GrupoMiembro.fromJson(Map<String, dynamic> j) => GrupoMiembro(
        id: j['id'] as String,
        amigoUsuarioId: j['amigo_usuario_id'] as String,
        apodo: j['apodo'] as String,
      );
}
