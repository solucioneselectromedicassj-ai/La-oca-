class DesafioResultado {
  final String nombre;
  final int etapasCompletadas;
  final int msTotal;

  const DesafioResultado({required this.nombre, required this.etapasCompletadas, required this.msTotal});

  factory DesafioResultado.fromJson(Map<String, dynamic> j) => DesafioResultado(
        nombre: j['nombre'] as String? ?? '?',
        etapasCompletadas: (j['etapas_completadas'] as num?)?.toInt() ?? 0,
        msTotal: (j['ms_total'] as num?)?.toInt() ?? 0,
      );
}
