/// Espeja la columna jsonb `usuarios.personalizacion`: qué tiene
/// equipado el usuario y qué ítems desbloqueó.
class Personalizacion {
  const Personalizacion({
    required this.silueta,
    required this.color,
    required this.accesorio,
    required this.desbloqueados,
  });

  final String? silueta;
  final String? color;
  final String? accesorio;
  final Set<String> desbloqueados;

  bool estaDesbloqueado(String itemId) => desbloqueados.contains(itemId);

  factory Personalizacion.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const Personalizacion(
        silueta: null,
        color: null,
        accesorio: null,
        desbloqueados: {},
      );
    }
    return Personalizacion(
      silueta: map['silueta'] as String?,
      color: map['color'] as String?,
      accesorio: map['accesorio'] as String?,
      desbloqueados: (map['desbloqueados'] as List?)?.cast<String>().toSet() ?? {},
    );
  }
}
