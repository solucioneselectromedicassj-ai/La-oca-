/// Cuestionados: mismos bancos de preguntas del prototipo HTML,
/// segmentados por país (argentina/chile/otros) y por bracket de edad.
/// Los brackets sin banco propio (jovenes, adultos_plus) heredan el de
/// "adultos" automáticamente, igual que en el prototipo.
class TriviaQuestion {
  final String q;
  final List<String> options;
  final int correct;
  const TriviaQuestion(this.q, this.options, this.correct);
}

class TriviaBank {
  TriviaBank._();

  static const List<String> paises = ['argentina', 'chile', 'otros'];

  static const Map<String, Map<String, List<TriviaQuestion>>> porPais = {
    'argentina': {
      'ninos': [
        TriviaQuestion('¿Cuántos días tiene una semana?', ['5', '6', '7', '8'], 2),
        TriviaQuestion('¿De qué color es el cielo en un día despejado?', ['Verde', 'Azul', 'Rojo', 'Negro'], 1),
        TriviaQuestion('¿Cuántas patas tiene un perro?', ['2', '4', '6', '8'], 1),
        TriviaQuestion('¿Qué animal dice "muu"?', ['Perro', 'Gato', 'Vaca', 'Pato'], 2),
        TriviaQuestion('¿Cuánto es 2 + 2?', ['3', '4', '5', '22'], 1),
        TriviaQuestion('¿De qué color es el pasto?', ['Azul', 'Verde', 'Rojo', 'Negro'], 1),
        TriviaQuestion('¿Cuántos meses tiene el año?', ['10', '11', '12', '13'], 2),
        TriviaQuestion('¿Cuánto es 5 + 3?', ['7', '8', '9', '10'], 1),
        TriviaQuestion('¿Cuánto es 10 menos 4?', ['5', '6', '7', '8'], 1),
        TriviaQuestion('¿Cuál es el planeta donde vivimos?', ['Marte', 'Venus', 'Tierra', 'Júpiter'], 2),
        TriviaQuestion('¿Qué astro nos da luz de día?', ['La Luna', 'El Sol', 'Una estrella lejana', 'Un cometa'], 1),
        TriviaQuestion('¿Cuál es el continente donde está Argentina?', ['África', 'América', 'Asia', 'Europa'], 1),
        TriviaQuestion('¿Cuál es la capital de Argentina?', ['Córdoba', 'Rosario', 'Buenos Aires', 'Mendoza'], 2),
        TriviaQuestion('¿Cuántos lados tiene un triángulo?', ['2', '3', '4', '5'], 1),
        TriviaQuestion('¿Qué animal es el más grande del mundo?', ['Elefante', 'Ballena azul', 'Jirafa', 'Tiburón'], 1),
        TriviaQuestion('¿De qué están hechas las nubes?', ['Algodón', 'Humo', 'Agua', 'Arena'], 2),
        TriviaQuestion('¿Cuántas estaciones del año hay?', ['2', '3', '4', '5'], 2),
      ],
      'adolescentes': [
        TriviaQuestion('¿Cuál es el río más largo del mundo?', ['Nilo', 'Amazonas', 'Paraná', 'Danubio'], 1),
        TriviaQuestion('¿En qué continente está Egipto?', ['Asia', 'África', 'Europa', 'Oceanía'], 1),
        TriviaQuestion('¿Cuántos huesos tiene el cuerpo humano adulto?', ['186', '206', '256', '300'], 1),
        TriviaQuestion('¿Quién pintó la Mona Lisa?', ['Van Gogh', 'Picasso', 'Da Vinci', 'Miguel Ángel'], 2),
        TriviaQuestion('¿Cuál es el planeta más cercano al Sol?', ['Venus', 'Mercurio', 'Marte', 'Tierra'], 1),
        TriviaQuestion('¿Cuál es el océano más grande del mundo?', ['Atlántico', 'Índico', 'Pacífico', 'Ártico'], 2),
        TriviaQuestion('¿Cuánto es 12 x 8?', ['86', '96', '106', '108'], 1),
        TriviaQuestion('¿Cuál es la raíz cuadrada de 144?', ['11', '12', '13', '14'], 1),
        TriviaQuestion('¿En qué año comenzó la Revolución de Mayo en Argentina?', ['1806', '1810', '1816', '1820'], 1),
        TriviaQuestion('¿Cuál es el país más grande del mundo por superficie?', ['China', 'Canadá', 'Rusia', 'Brasil'], 2),
        TriviaQuestion('¿Qué gas necesitan las plantas para hacer fotosíntesis?', ['Oxígeno', 'Dióxido de carbono', 'Nitrógeno', 'Hidrógeno'], 1),
        TriviaQuestion('¿Cuál es el hueso más pequeño del cuerpo humano?', ['Estribo (oído)', 'Falange', 'Rótula', 'Clavícula'], 0),
        TriviaQuestion('¿Cuál es la cordillera más larga del mundo?', ['Himalaya', 'Andes', 'Alpes', 'Rocosas'], 1),
        TriviaQuestion('¿Quién escribió "Romeo y Julieta"?', ['Cervantes', 'Shakespeare', 'Molière', 'Dante'], 1),
      ],
      'adultos': [
        TriviaQuestion('¿En qué año llegó el hombre a la Luna?', ['1965', '1969', '1972', '1958'], 1),
        TriviaQuestion('¿Cuál es la capital de Australia?', ['Sídney', 'Melbourne', 'Canberra', 'Perth'], 2),
        TriviaQuestion('¿Quién escribió "Cien años de soledad"?', ['Borges', 'García Márquez', 'Cortázar', 'Neruda'], 1),
        TriviaQuestion('¿Qué gas es el más abundante en la atmósfera terrestre?', ['Oxígeno', 'Dióxido de carbono', 'Nitrógeno', 'Hidrógeno'], 2),
        TriviaQuestion('¿Cuántos continentes hay?', ['5', '6', '7', '8'], 2),
        TriviaQuestion('¿En qué país está la Torre Eiffel?', ['Italia', 'España', 'Francia', 'Alemania'], 2),
        TriviaQuestion('¿Cuánto es el 20% de 150?', ['20', '25', '30', '35'], 2),
        TriviaQuestion('¿Cuál es el resultado de 7²?', ['14', '35', '49', '56'], 2),
        TriviaQuestion('¿En qué año terminó la Segunda Guerra Mundial?', ['1943', '1945', '1947', '1950'], 1),
        TriviaQuestion('¿Quién pintó "Las Meninas"?', ['Velázquez', 'Goya', 'El Greco', 'Dalí'], 0),
        TriviaQuestion('¿Cuál es el metal más abundante en la corteza terrestre?', ['Hierro', 'Aluminio', 'Cobre', 'Oro'], 1),
        TriviaQuestion('¿Cuál es el país más poblado del mundo?', ['China', 'India', 'Estados Unidos', 'Indonesia'], 1),
        TriviaQuestion('¿Qué órgano bombea la sangre en el cuerpo humano?', ['Pulmón', 'Hígado', 'Corazón', 'Riñón'], 2),
        TriviaQuestion('¿En qué año se fundó la ONU?', ['1919', '1945', '1950', '1960'], 1),
      ],
      'mayores': [
        TriviaQuestion('¿En qué década comenzó la Segunda Guerra Mundial?', ['1920s', '1930s', '1940s', '1950s'], 1),
        TriviaQuestion('¿Quién fue el primer presidente constitucional argentino?', ['San Martín', 'Rivadavia', 'Belgrano', 'Sarmiento'], 1),
        TriviaQuestion('¿Qué instrumento mide la temperatura?', ['Barómetro', 'Termómetro', 'Altímetro', 'Manómetro'], 1),
        TriviaQuestion('¿Cuál es la moneda de Brasil?', ['Peso', 'Real', 'Sol', 'Bolívar'], 1),
        TriviaQuestion('¿En qué año se independizó Argentina?', ['1810', '1816', '1820', '1853'], 1),
        TriviaQuestion('¿Cuánto es la mitad de 88?', ['44', '40', '48', '42'], 0),
        TriviaQuestion('¿Quién fue el general que cruzó los Andes?', ['Belgrano', 'San Martín', 'Güemes', 'Alvear'], 1),
        TriviaQuestion('¿Cuál es la capital de Perú?', ['Bogotá', 'Quito', 'Lima', 'La Paz'], 2),
        TriviaQuestion('¿Qué científico formuló la ley de la gravedad?', ['Einstein', 'Galileo', 'Newton', 'Darwin'], 2),
        TriviaQuestion('¿En qué año cayó el Muro de Berlín?', ['1985', '1989', '1991', '1993'], 1),
        TriviaQuestion('¿Cuál es el país vecino más grande de Argentina?', ['Chile', 'Brasil', 'Bolivia', 'Uruguay'], 1),
        TriviaQuestion('¿Cuántos días tiene un año bisiesto?', ['364', '365', '366', '367'], 2),
      ],
    },
    'chile': {
      'ninos': [
        TriviaQuestion('¿Cuál es la capital de Chile?', ['Valparaíso', 'Santiago', 'Concepción', 'Antofagasta'], 1),
        TriviaQuestion('¿Qué cordillera está al lado de Chile?', ['Los Alpes', 'Los Andes', 'El Himalaya', 'Las Rocosas'], 1),
        TriviaQuestion('¿Cuántos días tiene una semana?', ['5', '6', '7', '8'], 2),
        TriviaQuestion('¿Qué animal dice "muu"?', ['Perro', 'Gato', 'Vaca', 'Pato'], 2),
        TriviaQuestion('¿Cuánto es 2 + 2?', ['3', '4', '5', '22'], 1),
        TriviaQuestion('¿De qué color es el pasto?', ['Azul', 'Verde', 'Rojo', 'Negro'], 1),
        TriviaQuestion('¿Cuál es el desierto más famoso de Chile?', ['Sahara', 'Atacama', 'Gobi', 'Kalahari'], 1),
        TriviaQuestion('¿Cuántos lados tiene un triángulo?', ['2', '3', '4', '5'], 1),
        TriviaQuestion('¿Qué océano toca la costa de Chile?', ['Atlántico', 'Pacífico', 'Índico', 'Ártico'], 1),
      ],
      'adolescentes': [
        TriviaQuestion('¿Quién es considerado el padre de la patria en Chile?', ["Bernardo O'Higgins", 'San Martín', 'Manuel Rodríguez', 'Diego Portales'], 0),
        TriviaQuestion('¿En qué año se independizó Chile?', ['1810', '1818', '1820', '1825'], 1),
        TriviaQuestion('¿Cuál es el río más largo del mundo?', ['Nilo', 'Amazonas', 'Paraná', 'Danubio'], 1),
        TriviaQuestion('¿Cuál es la isla chilena famosa por sus estatuas moái?', ['Chiloé', 'Isla de Pascua', 'Juan Fernández', 'Isla Grande'], 1),
        TriviaQuestion('¿Cuánto es 12 x 8?', ['86', '96', '106', '108'], 1),
        TriviaQuestion('¿Quién pintó la Mona Lisa?', ['Van Gogh', 'Picasso', 'Da Vinci', 'Miguel Ángel'], 2),
        TriviaQuestion('¿Cuál es el punto más austral de Chile continental?', ['Punta Arenas', 'Puerto Montt', 'Puerto Williams', 'Cabo de Hornos'], 3),
        TriviaQuestion('¿Cuál es el planeta más cercano al Sol?', ['Venus', 'Mercurio', 'Marte', 'Tierra'], 1),
      ],
      'adultos': [
        TriviaQuestion('¿Quién fue Premio Nobel de Literatura chileno en 1971?', ['Gabriela Mistral', 'Pablo Neruda', 'Isabel Allende', 'Nicanor Parra'], 1),
        TriviaQuestion('¿En qué año llegó el hombre a la Luna?', ['1965', '1969', '1972', '1958'], 1),
        TriviaQuestion('¿Cuál es la moneda oficial de Chile?', ['Peso chileno', 'Sol', 'Real', 'Bolívar'], 0),
        TriviaQuestion('¿Quién escribió "Cien años de soledad"?', ['Borges', 'García Márquez', 'Cortázar', 'Neruda'], 1),
        TriviaQuestion('¿Qué gas es el más abundante en la atmósfera terrestre?', ['Oxígeno', 'Dióxido de carbono', 'Nitrógeno', 'Hidrógeno'], 2),
        TriviaQuestion('¿En qué año retornó Chile a la democracia?', ['1988', '1990', '1993', '1995'], 1),
        TriviaQuestion('¿Cuál es el resultado de 7²?', ['14', '35', '49', '56'], 2),
        TriviaQuestion('¿Cuál es el país más poblado del mundo?', ['China', 'India', 'Estados Unidos', 'Indonesia'], 1),
      ],
      'mayores': [
        TriviaQuestion('¿En qué año fue el terremoto de Valdivia, el más fuerte registrado?', ['1939', '1960', '1985', '2010'], 1),
        TriviaQuestion('¿Quién fue el primer presidente de Chile?', ["Bernardo O'Higgins", 'Manuel Blanco Encalada', 'Diego Portales', 'José Miguel Carrera'], 1),
        TriviaQuestion('¿Qué instrumento mide la temperatura?', ['Barómetro', 'Termómetro', 'Altímetro', 'Manómetro'], 1),
        TriviaQuestion('¿Cuál es la capital de Perú?', ['Bogotá', 'Quito', 'Lima', 'La Paz'], 2),
        TriviaQuestion('¿En qué década comenzó la Segunda Guerra Mundial?', ['1920s', '1930s', '1940s', '1950s'], 1),
        TriviaQuestion('¿Qué científico formuló la ley de la gravedad?', ['Einstein', 'Galileo', 'Newton', 'Darwin'], 2),
        TriviaQuestion('¿Cuál es el país vecino más grande de Chile?', ['Perú', 'Argentina', 'Bolivia', 'Brasil'], 1),
        TriviaQuestion('¿Cuántos días tiene un año bisiesto?', ['364', '365', '366', '367'], 2),
      ],
    },
    'otros': {
      'ninos': [
        TriviaQuestion('¿Cuántos días tiene una semana?', ['5', '6', '7', '8'], 2),
        TriviaQuestion('¿De qué color es el cielo en un día despejado?', ['Verde', 'Azul', 'Rojo', 'Negro'], 1),
        TriviaQuestion('¿Cuántas patas tiene un perro?', ['2', '4', '6', '8'], 1),
        TriviaQuestion('¿Qué animal dice "muu"?', ['Perro', 'Gato', 'Vaca', 'Pato'], 2),
        TriviaQuestion('¿Cuánto es 2 + 2?', ['3', '4', '5', '22'], 1),
        TriviaQuestion('¿Cuántos meses tiene el año?', ['10', '11', '12', '13'], 2),
        TriviaQuestion('¿Cuál es el planeta donde vivimos?', ['Marte', 'Venus', 'Tierra', 'Júpiter'], 2),
        TriviaQuestion('¿Qué astro nos da luz de día?', ['La Luna', 'El Sol', 'Una estrella lejana', 'Un cometa'], 1),
        TriviaQuestion('¿Cuántos lados tiene un triángulo?', ['2', '3', '4', '5'], 1),
        TriviaQuestion('¿Qué animal es el más grande del mundo?', ['Elefante', 'Ballena azul', 'Jirafa', 'Tiburón'], 1),
      ],
      'adolescentes': [
        TriviaQuestion('¿Cuál es el río más largo del mundo?', ['Nilo', 'Amazonas', 'Paraná', 'Danubio'], 1),
        TriviaQuestion('¿En qué continente está Egipto?', ['Asia', 'África', 'Europa', 'Oceanía'], 1),
        TriviaQuestion('¿Cuántos huesos tiene el cuerpo humano adulto?', ['186', '206', '256', '300'], 1),
        TriviaQuestion('¿Quién pintó la Mona Lisa?', ['Van Gogh', 'Picasso', 'Da Vinci', 'Miguel Ángel'], 2),
        TriviaQuestion('¿Cuál es el planeta más cercano al Sol?', ['Venus', 'Mercurio', 'Marte', 'Tierra'], 1),
        TriviaQuestion('¿Cuál es el océano más grande del mundo?', ['Atlántico', 'Índico', 'Pacífico', 'Ártico'], 2),
        TriviaQuestion('¿Cuánto es 12 x 8?', ['86', '96', '106', '108'], 1),
        TriviaQuestion('¿Cuál es el país más grande del mundo por superficie?', ['China', 'Canadá', 'Rusia', 'Brasil'], 2),
      ],
      'adultos': [
        TriviaQuestion('¿En qué año llegó el hombre a la Luna?', ['1965', '1969', '1972', '1958'], 1),
        TriviaQuestion('¿Cuál es la capital de Australia?', ['Sídney', 'Melbourne', 'Canberra', 'Perth'], 2),
        TriviaQuestion('¿Quién escribió "Cien años de soledad"?', ['Borges', 'García Márquez', 'Cortázar', 'Neruda'], 1),
        TriviaQuestion('¿Qué gas es el más abundante en la atmósfera terrestre?', ['Oxígeno', 'Dióxido de carbono', 'Nitrógeno', 'Hidrógeno'], 2),
        TriviaQuestion('¿En qué país está la Torre Eiffel?', ['Italia', 'España', 'Francia', 'Alemania'], 2),
        TriviaQuestion('¿Cuál es el resultado de 7²?', ['14', '35', '49', '56'], 2),
        TriviaQuestion('¿Quién pintó "Las Meninas"?', ['Velázquez', 'Goya', 'El Greco', 'Dalí'], 0),
        TriviaQuestion('¿Cuál es el país más poblado del mundo?', ['China', 'India', 'Estados Unidos', 'Indonesia'], 1),
      ],
      'mayores': [
        TriviaQuestion('¿En qué década comenzó la Segunda Guerra Mundial?', ['1920s', '1930s', '1940s', '1950s'], 1),
        TriviaQuestion('¿Qué instrumento mide la temperatura?', ['Barómetro', 'Termómetro', 'Altímetro', 'Manómetro'], 1),
        TriviaQuestion('¿Cuál es la moneda de Brasil?', ['Peso', 'Real', 'Sol', 'Bolívar'], 1),
        TriviaQuestion('¿Quién fue el general que cruzó los Andes?', ['Belgrano', 'San Martín', 'Güemes', 'Alvear'], 1),
        TriviaQuestion('¿Cuál es la capital de Perú?', ['Bogotá', 'Quito', 'Lima', 'La Paz'], 2),
        TriviaQuestion('¿Qué científico formuló la ley de la gravedad?', ['Einstein', 'Galileo', 'Newton', 'Darwin'], 2),
        TriviaQuestion('¿En qué año cayó el Muro de Berlín?', ['1985', '1989', '1991', '1993'], 1),
        TriviaQuestion('¿Cuántos días tiene un año bisiesto?', ['364', '365', '366', '367'], 2),
      ],
    },
  };

  static const Map<String, List<TriviaQuestion>> dificil = {
    'ninos': [
      TriviaQuestion('¿Cuántos lados tiene un hexágono?', ['5', '6', '7', '8'], 1),
      TriviaQuestion('¿Cómo se llama el planeta rojo?', ['Venus', 'Marte', 'Júpiter', 'Saturno'], 1),
      TriviaQuestion('¿Cuántas patas tiene una araña?', ['6', '8', '10', '4'], 1),
      TriviaQuestion('¿Cuánto es 9 + 6?', ['13', '14', '15', '16'], 2),
      TriviaQuestion('¿Qué río es el más largo de Argentina?', ['Paraná', 'Uruguay', 'Colorado', 'Negro'], 0),
      TriviaQuestion('¿Cuántos continentes hay en el mundo?', ['5', '6', '7', '8'], 2),
    ],
    'adolescentes': [
      TriviaQuestion('¿Cuál es la capital de Canadá?', ['Toronto', 'Ottawa', 'Vancouver', 'Montreal'], 1),
      TriviaQuestion('¿Quién escribió "Romeo y Julieta"?', ['Shakespeare', 'Cervantes', 'Dante', 'Molière'], 0),
      TriviaQuestion('¿Cuál es el hueso más largo del cuerpo humano?', ['Húmero', 'Fémur', 'Tibia', 'Radio'], 1),
      TriviaQuestion('¿Cuánto es 15% de 200?', ['20', '25', '30', '35'], 2),
      TriviaQuestion('¿En qué año comenzó la Primera Guerra Mundial?', ['1910', '1914', '1918', '1920'], 1),
      TriviaQuestion('¿Cuál es el idioma más hablado del mundo como lengua materna?', ['Inglés', 'Español', 'Mandarín', 'Hindi'], 2),
    ],
    'adultos': [
      TriviaQuestion('¿En qué año cayó el Muro de Berlín?', ['1985', '1989', '1991', '1993'], 1),
      TriviaQuestion('¿Cuál es la velocidad aproximada de la luz?', ['300.000 km/s', '150.000 km/s', '1.000.000 km/s', '30.000 km/s'], 0),
      TriviaQuestion('¿Quién formuló la teoría de la relatividad?', ['Newton', 'Einstein', 'Bohr', 'Tesla'], 1),
      TriviaQuestion('¿Cuál es la capital de Kazajistán?', ['Almatý', 'Astaná', 'Bishkek', 'Tashkent'], 1),
      TriviaQuestion('¿Quién compuso "La novena sinfonía"?', ['Mozart', 'Bach', 'Beethoven', 'Chopin'], 2),
      TriviaQuestion('¿Cuánto es la raíz cuadrada de 225?', ['13', '14', '15', '16'], 2),
    ],
    'mayores': [
      TriviaQuestion('¿En qué año terminó la Segunda Guerra Mundial?', ['1943', '1945', '1947', '1950'], 1),
      TriviaQuestion('¿Quién pintó "Guernica"?', ['Dalí', 'Picasso', 'Miró', 'Goya'], 1),
      TriviaQuestion('¿Cuál era la capital del Imperio Romano de Oriente?', ['Roma', 'Atenas', 'Constantinopla', 'Alejandría'], 2),
      TriviaQuestion('¿En qué año asumió la primera democracia post-dictadura en Argentina?', ['1981', '1983', '1985', '1989'], 1),
      TriviaQuestion('¿Quién escribió "El Quijote"?', ['Lope de Vega', 'Cervantes', 'Calderón', 'Góngora'], 1),
      TriviaQuestion('¿Cuál es la capital de Bolivia (sede de gobierno)?', ['Sucre', 'La Paz', 'Cochabamba', 'Santa Cruz'], 1),
    ],
  };

  /// Brackets sin banco propio (jovenes, adultos_plus) heredan "adultos".
  static const Map<String, String> _herencia = {
    'jovenes': 'adultos',
    'adultos_plus': 'adultos',
  };

  static String _resolverBracket(String bracket) => _herencia[bracket] ?? bracket;

  static List<TriviaQuestion> bancoPorPais(String pais, String bracket) {
    final set = porPais[pais] ?? porPais['otros']!;
    final b = _resolverBracket(bracket);
    return set[b] ?? set['adultos']!;
  }

  static List<TriviaQuestion> bancoDificil(String bracket) {
    final b = _resolverBracket(bracket);
    return dificil[b] ?? dificil['adultos']!;
  }
}
