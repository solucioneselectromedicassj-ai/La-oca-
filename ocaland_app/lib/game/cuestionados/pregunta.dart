/// Una pregunta de Cuestionados (sección 4 de la especificación).
class Pregunta {
  const Pregunta({
    required this.texto,
    required this.opciones,
    required this.indiceCorrecta,
  });

  final String texto;
  final List<String> opciones;
  final int indiceCorrecta;

  String get respuestaCorrecta => opciones[indiceCorrecta];
}
