/// Campaña de 10 etapas del modo solo: nombre + lore de cada etapa,
/// y la configuración de dificultad progresiva del bot (idéntica al
/// prototipo: `generarConfigEtapa`).
class EtapaInfo {
  final String nombre;
  final String leyenda;
  const EtapaInfo(this.nombre, this.leyenda);
}

class EtapaConfig {
  final double botAciertoOca;
  final double botAciertoCarcel;
  final double botAciertoCalavera;
  final double botAciertoMinijuego;
  final bool ocaCarcelUsanBancoDificil;
  final int tiempoLimiteTrivia;
  const EtapaConfig({
    required this.botAciertoOca,
    required this.botAciertoCarcel,
    required this.botAciertoCalavera,
    required this.botAciertoMinijuego,
    required this.ocaCarcelUsanBancoDificil,
    required this.tiempoLimiteTrivia,
  });
}

class Campana {
  Campana._();

  static const Map<int, EtapaInfo> etapasInfo = {
    1: EtapaInfo('El Nido Inicial', 'Todo viaje empieza en el nido. Acá aprendés a caminar por el sendero y a conocer las primeras trampas de Ocaland.'),
    2: EtapaInfo('El Estanque Sereno', 'Las aguas se ven tranquilas, pero esconden más de una sorpresa bajo la superficie.'),
    3: EtapaInfo('El Bosque de las Dudas', 'Entre árboles retorcidos, hasta las preguntas más simples empiezan a parecer trampas.'),
    4: EtapaInfo('La Colina Ventosa', 'El viento sopla fuerte acá arriba. Un paso en falso y volvés más atrás de lo que pensás.'),
    5: EtapaInfo('El Valle de los Espejismos', 'Nada es lo que parece en este valle. La oca ya no perdona tan fácil.'),
    6: EtapaInfo('La Cueva Oscura', 'La oscuridad esconde secretos. Los Cuestionados se ponen serios a partir de acá.'),
    7: EtapaInfo('El Puente Colgante', 'Un solo paso mal dado y todo se derrumba. Hasta la oca y la cárcel exigen respuestas difíciles ahora.'),
    8: EtapaInfo('La Montaña Helada', 'El frío pone a prueba tu paciencia y tu memoria. Pocos llegan hasta acá sin tropezar.'),
    9: EtapaInfo('El Desfiladero Final', 'Ya casi no quedan casillas seguras. Solo los más preparados siguen de pie.'),
    10: EtapaInfo('La Cima de Ocaland', 'La cima. El desafío final. Acá se corona a quien de verdad se ganó el lugar.'),
  };

  static EtapaConfig generarConfigEtapa(int etapa) {
    final d = (etapa - 1) / 9; // 0 (etapa1) a 1 (etapa10)
    return EtapaConfig(
      botAciertoOca: 0.45 + d * 0.35,
      botAciertoCarcel: 0.45 + d * 0.35,
      botAciertoCalavera: 0.30 + d * 0.35,
      botAciertoMinijuego: 0.35 + d * 0.35,
      ocaCarcelUsanBancoDificil: etapa >= 7,
      tiempoLimiteTrivia: (15 - (d * 7).floor()).clamp(8, 15),
    );
  }
}
