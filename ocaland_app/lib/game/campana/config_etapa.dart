/// Dificultad de cada etapa de la campaña Solo (sección 6.1):
/// el bot acierta más a medida que avanza la etapa, el tiempo de
/// respuesta baja de 15s a 8s, y desde la etapa 7 hasta oca/cárcel
/// usan el banco difícil (antes solo calavera lo usaba).
class ConfigEtapa {
  const ConfigEtapa({
    required this.etapa,
    required this.probabilidadAciertoBot,
    required this.segundosCuestionados,
    required this.usarBancoDificilEnOcaCarcel,
  });

  final int etapa;
  final double probabilidadAciertoBot;
  final int segundosCuestionados;
  final bool usarBancoDificilEnOcaCarcel;

  factory ConfigEtapa.generar(int etapa) {
    final etapaClamp = etapa.clamp(1, 10);
    // Etapa 1 -> 0.40 de acierto, etapa 10 -> 0.85 de acierto.
    final probabilidad = 0.40 + (etapaClamp - 1) * (0.45 / 9);
    // Etapa 1 -> 15s, etapa 10 -> 8s.
    final segundos = 15 - ((etapaClamp - 1) * (7 / 9)).round();
    return ConfigEtapa(
      etapa: etapaClamp,
      probabilidadAciertoBot: probabilidad,
      segundosCuestionados: segundos,
      usarBancoDificilEnOcaCarcel: etapaClamp >= 7,
    );
  }
}
