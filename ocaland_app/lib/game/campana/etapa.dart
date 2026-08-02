/// Las 10 etapas de la campaña Solo, con nombre y lore (sección 6.1).
class Etapa {
  const Etapa({required this.numero, required this.nombre, required this.lore});

  final int numero;
  final String nombre;
  final String lore;

  static const List<Etapa> todas = [
    Etapa(
      numero: 1,
      nombre: 'El Nido Inicial',
      lore: 'Todo viaje empieza en un lugar seguro. Las primeras ocas de '
          'Ocaland te dan la bienvenida antes de que el camino se complique.',
    ),
    Etapa(
      numero: 2,
      nombre: 'El Estanque Sereno',
      lore: 'Las aguas calmas esconden preguntas más filosas de lo que '
          'parecen. No te confíes todavía.',
    ),
    Etapa(
      numero: 3,
      nombre: 'El Bosque de las Dudas',
      lore: 'Entre tanto árbol es fácil perder el rumbo — y las Cuestionados '
          'empiezan a pedir un poco más de memoria.',
    ),
    Etapa(
      numero: 4,
      nombre: 'La Colina Ventosa',
      lore: 'El viento empuja la ficha para cualquier lado. El bot también '
          'empieza a acertar más seguido.',
    ),
    Etapa(
      numero: 5,
      nombre: 'El Valle de los Espejismos',
      lore: 'Nada es lo que parece en este valle. Las trampas se disfrazan '
          'de casillas tranquilas.',
    ),
    Etapa(
      numero: 6,
      nombre: 'La Cueva Oscura',
      lore: 'A partir de acá el camino se pone serio: menos tiempo para '
          'pensar, más presión.',
    ),
    Etapa(
      numero: 7,
      nombre: 'El Puente Colgante',
      lore: 'Un paso en falso y todo se derrumba. Desde esta etapa, hasta la '
          'oca y la cárcel empiezan a exigir el banco difícil.',
    ),
    Etapa(
      numero: 8,
      nombre: 'La Montaña Helada',
      lore: 'El frío entumece los reflejos. El bot de esta altura casi no '
          'perdona un error.',
    ),
    Etapa(
      numero: 9,
      nombre: 'El Desfiladero Final',
      lore: 'Un paso más y Ocaland queda atrás. Esta es la última prueba '
          'antes de la cima.',
    ),
    Etapa(
      numero: 10,
      nombre: 'La Cima de Ocaland',
      lore: 'Llegaste hasta acá. Solo falta una última tirada de dado para '
          'coronarte campeón de Ocaland.',
    ),
  ];

  static Etapa deNumero(int numero) =>
      todas.firstWhere((e) => e.numero == numero);
}
