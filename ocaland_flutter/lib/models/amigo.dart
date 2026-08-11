/// Fila de `amigos`: contacto guardado (lista propia, no hace falta que el
/// otro te agregue de vuelta — como una agenda).
class Amigo {
  final String id;
  final String amigoUsuarioId;
  final String apodo;

  const Amigo({required this.id, required this.amigoUsuarioId, required this.apodo});

  factory Amigo.fromJson(Map<String, dynamic> j) => Amigo(
        id: j['id'] as String,
        amigoUsuarioId: j['amigo_usuario_id'] as String,
        apodo: j['apodo'] as String,
      );
}
