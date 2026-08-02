import 'pregunta.dart';

/// Banco de preguntas de Cuestionados, segmentado por franja de edad
/// (sección 4). Es intencionalmente chico para este primer corte — la
/// especificación ya marca "banco mucho más grande, o generado
/// dinámicamente" como pendiente explícito para Flutter (sección 16.7).
/// Todavía no está segmentado por país (Argentina/Chile/Internacional);
/// eso también queda para una siguiente pasada.
class BancoPreguntas {
  BancoPreguntas._();

  /// Brackets sin banco propio heredan el de "adultos" (sección 4).
  static String _bracketEfectivo(String edadBracket) {
    switch (edadBracket) {
      case 'jovenes':
      case 'adultos_plus':
        return 'adultos';
      default:
        return edadBracket;
    }
  }

  /// Devuelve una copia modificable (los bancos internos son `const` para
  /// evitar mutaciones accidentales entre partidas; quien llama puede
  /// hacer `.shuffle()` sobre el resultado con seguridad).
  static List<Pregunta> preguntasPara(String edadBracket) {
    final bracket = _bracketEfectivo(edadBracket);
    return List.of(_bancos[bracket] ?? _bancos['adultos']!);
  }

  static List<Pregunta> get preguntasDificil => List.of(_dificil);

  static final Map<String, List<Pregunta>> _bancos = {
    'ninos': const [
      Pregunta(
        texto: '¿Cuántas patas tiene una araña?',
        opciones: ['6', '8', '10', '4'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿De qué color es el cielo en un día despejado?',
        opciones: ['Verde', 'Rojo', 'Celeste', 'Amarillo'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Cuál es el animal más grande del mundo?',
        opciones: ['El elefante', 'La ballena azul', 'La jirafa', 'El tiburón'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuántos días tiene una semana?',
        opciones: ['5', '6', '7', '8'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Qué animal dice "guau"?',
        opciones: ['El gato', 'El perro', 'La vaca', 'El pato'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es el planeta donde vivimos?',
        opciones: ['Marte', 'Venus', 'Tierra', 'Júpiter'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Con qué se hace la miel?',
        opciones: ['Hormigas', 'Abejas', 'Mariposas', 'Moscas'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuántos colores tiene el arcoíris?',
        opciones: ['5', '6', '7', '9'],
        indiceCorrecta: 2,
      ),
    ],
    'adolescentes': const [
      Pregunta(
        texto: '¿En qué continente está Egipto?',
        opciones: ['Asia', 'África', 'Europa', 'Oceanía'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es el hueso más largo del cuerpo humano?',
        opciones: ['El fémur', 'La tibia', 'El húmero', 'El radio'],
        indiceCorrecta: 0,
      ),
      Pregunta(
        texto: '¿Qué gas respiramos para vivir?',
        opciones: ['Dióxido de carbono', 'Oxígeno', 'Nitrógeno', 'Hidrógeno'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuántos jugadores tiene un equipo de fútbol en cancha?',
        opciones: ['9', '10', '11', '12'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Quién pintó la Mona Lisa?',
        opciones: ['Picasso', 'Leonardo da Vinci', 'Van Gogh', 'Miguel Ángel'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es el río más largo del mundo?',
        opciones: ['El Nilo', 'El Amazonas', 'El Misisipi', 'El Danubio'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿En qué año llegó el ser humano a la Luna?',
        opciones: ['1965', '1969', '1972', '1959'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es el metal líquido a temperatura ambiente?',
        opciones: ['Hierro', 'Mercurio', 'Plomo', 'Aluminio'],
        indiceCorrecta: 1,
      ),
    ],
    'adultos': const [
      Pregunta(
        texto: '¿Cuál es la capital de Francia?',
        opciones: ['Madrid', 'Roma', 'París', 'Berlín'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Quién escribió "Cien años de soledad"?',
        opciones: [
          'Mario Vargas Llosa',
          'Gabriel García Márquez',
          'Julio Cortázar',
          'Pablo Neruda',
        ],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿En qué año cayó el Muro de Berlín?',
        opciones: ['1987', '1989', '1991', '1993'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es el océano más grande del planeta?',
        opciones: ['Atlántico', 'Índico', 'Pacífico', 'Ártico'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Qué elemento químico tiene el símbolo "Fe"?',
        opciones: ['Flúor', 'Hierro', 'Fósforo', 'Francio'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuántos huesos tiene el cuerpo humano adulto?',
        opciones: ['186', '206', '226', '246'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Quién compuso la Novena Sinfonía?',
        opciones: ['Mozart', 'Bach', 'Beethoven', 'Chopin'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Cuál es la moneda oficial de Japón?',
        opciones: ['Yuan', 'Won', 'Yen', 'Rupia'],
        indiceCorrecta: 2,
      ),
    ],
    'mayores': const [
      Pregunta(
        texto: '¿Quién fue el primer presidente de Argentina?',
        opciones: [
          'Bernardino Rivadavia',
          'Domingo Sarmiento',
          'Justo José de Urquiza',
          'Julio Argentino Roca',
        ],
        indiceCorrecta: 0,
      ),
      Pregunta(
        texto: '¿En qué década terminó la Segunda Guerra Mundial?',
        opciones: ['1930', '1940', '1950', '1960'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es la capital de Chile?',
        opciones: ['Valparaíso', 'Santiago', 'Concepción', 'La Serena'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Qué instrumento se usa para medir la temperatura?',
        opciones: ['Barómetro', 'Termómetro', 'Higrómetro', 'Altímetro'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es el mes más corto del año?',
        opciones: ['Abril', 'Junio', 'Febrero', 'Septiembre'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Qué país tiene forma de bota?',
        opciones: ['España', 'Italia', 'Grecia', 'Portugal'],
        indiceCorrecta: 1,
      ),
      Pregunta(
        texto: '¿Cuál es el idioma más hablado del mundo?',
        opciones: ['Inglés', 'Español', 'Mandarín', 'Hindi'],
        indiceCorrecta: 2,
      ),
      Pregunta(
        texto: '¿Quién escribió "Don Quijote de la Mancha"?',
        opciones: [
          'Lope de Vega',
          'Miguel de Cervantes',
          'Federico García Lorca',
          'Calderón de la Barca',
        ],
        indiceCorrecta: 1,
      ),
    ],
  };

  static const List<Pregunta> _dificil = [
    Pregunta(
      texto: '¿Cuál es la partícula subatómica con carga negativa?',
      opciones: ['Protón', 'Neutrón', 'Electrón', 'Positrón'],
      indiceCorrecta: 2,
    ),
    Pregunta(
      texto: '¿Quién formuló la teoría de la relatividad general?',
      opciones: ['Newton', 'Einstein', 'Bohr', 'Planck'],
      indiceCorrecta: 1,
    ),
    Pregunta(
      texto: '¿En qué año se firmó el Tratado de Versalles?',
      opciones: ['1918', '1919', '1920', '1921'],
      indiceCorrecta: 1,
    ),
    Pregunta(
      texto: '¿Cuál es el hueso más pequeño del cuerpo humano?',
      opciones: ['Estribo', 'Yunque', 'Martillo', 'Rótula'],
      indiceCorrecta: 0,
    ),
    Pregunta(
      texto: '¿Qué filósofo escribió "Así habló Zaratustra"?',
      opciones: ['Kant', 'Nietzsche', 'Hegel', 'Schopenhauer'],
      indiceCorrecta: 1,
    ),
    Pregunta(
      texto: '¿Cuál es la capital de Kazajistán?',
      opciones: ['Almaty', 'Astaná', 'Bishkek', 'Tashkent'],
      indiceCorrecta: 1,
    ),
    Pregunta(
      texto: '¿Qué elemento tiene el número atómico 79?',
      opciones: ['Plata', 'Platino', 'Oro', 'Plomo'],
      indiceCorrecta: 2,
    ),
    Pregunta(
      texto: '¿Quién pintó "Las Meninas"?',
      opciones: ['Goya', 'Velázquez', 'El Greco', 'Dalí'],
      indiceCorrecta: 1,
    ),
  ];
}
