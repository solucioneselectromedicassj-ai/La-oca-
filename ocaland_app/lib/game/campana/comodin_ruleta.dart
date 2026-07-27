import 'package:flutter/material.dart';

/// Comodines de la ruleta de premio entre etapas (sección 9 de la
/// especificación): 4 premios reales + "nada" (dos de los seis
/// segmentos, para que no siempre toque premio).
enum ComodinRuleta { ventaja3, inmunidad, tiradaExtra, dobleTiempo, nada }

class PremioRuleta {
  const PremioRuleta({
    required this.comodin,
    required this.nombre,
    required this.color,
  });

  final ComodinRuleta comodin;
  final String nombre;
  final Color color;
}

/// Los 6 segmentos de la ruleta, en el mismo orden (horario, arrancando
/// arriba) que los gajos del arte real de `assets/ruleta/disco.png`.
class RuletaPremios {
  RuletaPremios._();

  static final List<PremioRuleta> segmentos = [
    const PremioRuleta(
      comodin: ComodinRuleta.ventaja3,
      nombre: '+3 casillas',
      color: Color(0xFFE0433E), // rojo
    ),
    const PremioRuleta(
      comodin: ComodinRuleta.inmunidad,
      nombre: 'Inmunidad',
      color: Color(0xFF3E7DE0), // azul
    ),
    const PremioRuleta(
      comodin: ComodinRuleta.tiradaExtra,
      nombre: 'Tirada extra',
      color: Color(0xFF3EBF5C), // verde
    ),
    const PremioRuleta(
      comodin: ComodinRuleta.dobleTiempo,
      nombre: 'Doble tiempo',
      color: Color(0xFF9B4FE0), // violeta
    ),
    const PremioRuleta(
      comodin: ComodinRuleta.nada,
      nombre: 'Nada esta vez',
      color: Color(0xFFE0C13E), // amarillo
    ),
    const PremioRuleta(
      comodin: ComodinRuleta.nada,
      nombre: 'Nada esta vez',
      color: Color(0xFFE05CA8), // rosa
    ),
  ];
}
