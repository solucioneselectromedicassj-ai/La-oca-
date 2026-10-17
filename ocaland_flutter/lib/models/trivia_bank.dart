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
        TriviaQuestion('¿Cuántos dedos tenés en una mano?', ['3', '4', '5', '6'], 2),
        TriviaQuestion('¿Qué fruta es amarilla y curva?', ['Manzana', 'Banana', 'Uva', 'Pera'], 1),
        TriviaQuestion('¿Cuál es el opuesto de "grande"?', ['Alto', 'Chico', 'Ancho', 'Largo'], 1),
        TriviaQuestion('¿Qué día viene después del lunes?', ['Domingo', 'Martes', 'Miércoles', 'Jueves'], 1),
        TriviaQuestion('¿De qué color es una frutilla madura?', ['Verde', 'Amarillo', 'Rojo', 'Azul'], 2),
        TriviaQuestion('¿Cuántas ruedas tiene una bicicleta?', ['1', '2', '3', '4'], 1),
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
        TriviaQuestion('¿Cuál es el país más chico del mundo?', ['Mónaco', 'Vaticano', 'San Marino', 'Liechtenstein'], 1),
        TriviaQuestion('¿Cuántos jugadores tiene un equipo de fútbol en cancha?', ['9', '10', '11', '12'], 2),
        TriviaQuestion('¿Cuál es el metal líquido a temperatura ambiente?', ['Hierro', 'Mercurio', 'Plomo', 'Cobre'], 1),
        TriviaQuestion('¿Qué instrumento tiene 88 teclas?', ['Guitarra', 'Piano', 'Violín', 'Arpa'], 1),
        TriviaQuestion('¿Cuál es la capital de Uruguay?', ['Punta del Este', 'Montevideo', 'Salto', 'Colonia'], 1),
        TriviaQuestion('¿Cuánto es 9 al cuadrado?', ['72', '81', '90', '99'], 1),
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
        TriviaQuestion('¿Quién fue el primer argentino en ganar un premio Nobel?', ['Juan Domingo Perón', 'Bernardo Houssay', 'Adolfo Pérez Esquivel', 'César Milstein'], 1),
        TriviaQuestion('¿En qué año se firmó el Tratado de Maastricht (Unión Europea)?', ['1989', '1992', '1995', '2000'], 1),
        TriviaQuestion('¿Cuál es el idioma oficial de Brasil?', ['Español', 'Portugués', 'Inglés', 'Francés'], 1),
        TriviaQuestion('¿Qué elemento químico tiene el símbolo "Au"?', ['Plata', 'Aluminio', 'Oro', 'Argón'], 2),
        TriviaQuestion('¿Cuál es el río más caudaloso del mundo?', ['Nilo', 'Amazonas', 'Misisipi', 'Yangtsé'], 1),
        TriviaQuestion('¿Cuántos huesos tiene la mano humana (con muñeca)?', ['21', '27', '32', '36'], 1),
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
        TriviaQuestion('¿En qué año se creó la bandera argentina?', ['1810', '1812', '1816', '1820'], 1),
        TriviaQuestion('¿Quién escribió el "Martín Fierro"?', ['Sarmiento', 'José Hernández', 'Leopoldo Lugones', 'Bartolomé Mitre'], 1),
        TriviaQuestion('¿Cómo se llamaba la moneda argentina anterior al peso actual?', ['Austral', 'Real', 'Peso Ley', 'Peso Moneda Nacional'], 0),
        TriviaQuestion('¿En qué año Argentina ganó su primer Mundial de fútbol?', ['1974', '1978', '1982', '1986'], 1),
        TriviaQuestion('¿Qué fue Eva Perón de Juan Domingo Perón?', ['Hermana', 'Esposa', 'Hija', 'Prima'], 1),
        TriviaQuestion('¿Cuál es la ciudad más austral de la Argentina continental?', ['Río Gallegos', 'Ushuaia', 'Comodoro Rivadavia', 'El Calafate'], 1),
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
        TriviaQuestion('¿Cuántos dedos tenés en una mano?', ['3', '4', '5', '6'], 2),
        TriviaQuestion('¿Qué fruta es amarilla y curva?', ['Manzana', 'Banana', 'Uva', 'Pera'], 1),
        TriviaQuestion('¿Qué día viene después del lunes?', ['Domingo', 'Martes', 'Miércoles', 'Jueves'], 1),
        TriviaQuestion('¿De qué color es el sol?', ['Verde', 'Azul', 'Amarillo', 'Negro'], 2),
        TriviaQuestion('¿Cuántas patas tiene una vaca?', ['2', '4', '6', '8'], 1),
        TriviaQuestion('¿Cuál es la capital de la región de Valparaíso?', ['Santiago', 'Valparaíso', 'Viña del Mar', 'Quillota'], 1),
        // Latinoamérica en general — no nos quedamos encerrados en Chile.
        TriviaQuestion('¿Cuál es la capital de Perú?', ['Lima', 'Quito', 'Bogotá', 'La Paz'], 0),
        TriviaQuestion('¿Cuál es la capital de México?', ['Guadalajara', 'Ciudad de México', 'Cancún', 'Monterrey'], 1),
        TriviaQuestion('¿Cuál es la capital de Colombia?', ['Medellín', 'Cali', 'Bogotá', 'Cartagena'], 2),
        TriviaQuestion('¿Qué cordillera recorre gran parte de Sudamérica de norte a sur?', ['Los Alpes', 'Los Andes', 'El Himalaya', 'Las Rocosas'], 1),
        TriviaQuestion('¿Qué idioma hablan la mayoría de los países de Latinoamérica?', ['Portugués', 'Español', 'Inglés', 'Francés'], 1),
        TriviaQuestion('¿En qué país de Sudamérica se habla portugués?', ['Argentina', 'Chile', 'Brasil', 'Perú'], 2),
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
        TriviaQuestion('¿Cuál es el volcán más activo de Chile?', ['Villarrica', 'Osorno', 'Llaima', 'Chaitén'], 0),
        TriviaQuestion('¿Cuál es la moneda de Argentina?', ['Real', 'Peso', 'Sol', 'Bolívar'], 1),
        TriviaQuestion('¿Cuántos jugadores tiene un equipo de fútbol en cancha?', ['9', '10', '11', '12'], 2),
        TriviaQuestion('¿En qué año fue el gran terremoto de Chile de magnitud 8.8?', ['2005', '2010', '2015', '2020'], 1),
        TriviaQuestion('¿Cuál es el lago más grande de Chile?', ['Llanquihue', 'General Carrera', 'Villarrica', 'Ranco'], 1),
        TriviaQuestion('¿Cuánto es 9 al cuadrado?', ['72', '81', '90', '99'], 1),
        // Latinoamérica en general — no nos quedamos encerrados en Chile.
        TriviaQuestion('¿Cuál es el lago navegable más alto del mundo, compartido por Perú y Bolivia?', ['Lago Titicaca', 'Lago Nahuel Huapi', 'Lago General Carrera', 'Lago Maracaibo'], 0),
        TriviaQuestion('¿Qué civilización precolombina construyó Machu Picchu, en Perú?', ['Maya', 'Azteca', 'Inca', 'Mapuche'], 2),
        TriviaQuestion('¿Cuál es la moneda oficial de México?', ['Peso mexicano', 'Dólar', 'Real', 'Sol'], 0),
        TriviaQuestion('¿Qué país centroamericano conecta el océano Atlántico con el Pacífico a través de un canal?', ['Costa Rica', 'Panamá', 'Nicaragua', 'Honduras'], 1),
        TriviaQuestion('¿Cuál es el volcán más alto del mundo, ubicado entre Argentina y Chile?', ['Aconcagua', 'Ojos del Salado', 'Chimborazo', 'Cotopaxi'], 1),
        TriviaQuestion('¿Qué país sudamericano no tiene salida al mar?', ['Paraguay', 'Uruguay', 'Ecuador', 'Venezuela'], 0),
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
        TriviaQuestion('¿Quién fue Premio Nobel de Literatura chilena en 1945?', ['Gabriela Mistral', 'Pablo Neruda', 'Isabel Allende', 'Vicente Huidobro'], 0),
        TriviaQuestion('¿Cuál es el desierto más seco del mundo?', ['Sahara', 'Atacama', 'Gobi', 'Kalahari'], 1),
        TriviaQuestion('¿En qué año comenzó la dictadura de Pinochet?', ['1970', '1973', '1976', '1980'], 1),
        TriviaQuestion('¿Cuál es el punto más alto de Chile?', ['Ojos del Salado', 'Aconcagua', 'Tupungato', 'Llullaillaco'], 0),
        TriviaQuestion('¿Qué elemento químico, muy exportado por Chile, tiene el símbolo "Cu"?', ['Carbono', 'Cobre', 'Cinc', 'Cromo'], 1),
        TriviaQuestion('¿Cuál es la región más al norte de Chile?', ['Antofagasta', 'Tarapacá', 'Arica y Parinacota', 'Atacama'], 2),
        // Latinoamérica en general — no nos quedamos encerrados en Chile.
        TriviaQuestion('¿Qué imperio precolombino dominó gran parte de los Andes antes de la conquista española?', ['Imperio Azteca', 'Imperio Inca', 'Imperio Maya', 'Imperio Tolteca'], 1),
        TriviaQuestion('¿Cuál es el país más poblado de Sudamérica?', ['Argentina', 'Colombia', 'Brasil', 'Perú'], 2),
        TriviaQuestion('¿Qué escritor colombiano ganó el Premio Nobel de Literatura en 1982?', ['Mario Vargas Llosa', 'Gabriel García Márquez', 'Pablo Neruda', 'Octavio Paz'], 1),
        TriviaQuestion('¿Qué país latinoamericano tiene la mayor selva tropical del mundo en su territorio?', ['Perú', 'Colombia', 'Brasil', 'Ecuador'], 2),
        TriviaQuestion('¿Cómo se llama el pasaje que separa Sudamérica de la Antártida?', ['Estrecho de Magallanes', 'Pasaje de Drake', 'Canal de Beagle', 'Estrecho de Gibraltar'], 1),
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
        TriviaQuestion('¿En qué año se fundó Santiago?', ['1541', '1553', '1568', '1600'], 0),
        TriviaQuestion('¿Cuál fue la principal exportación de Chile durante el "ciclo del salitre"?', ['Cobre', 'Salitre', 'Carbón', 'Trigo'], 1),
        TriviaQuestion('¿En qué guerra Chile ganó territorio norteño a Perú y Bolivia?', ['Guerra del Pacífico', 'Guerra Civil de 1891', 'Guerra contra España', 'Guerra de Arauco'], 0),
        TriviaQuestion('¿Cómo se llama el estrecho que separa el continente de Tierra del Fuego?', ['Estrecho de Magallanes', 'Canal Beagle', 'Golfo de Penas', 'Paso Drake'], 0),
        TriviaQuestion('¿Quién escribió la letra del himno nacional de Chile?', ['Eusebio Lillo', 'Ramón Carnicer', "Bernardo O'Higgins", 'Andrés Bello'], 0),
        TriviaQuestion('¿En qué año Chile abolió la esclavitud?', ['1811', '1823', '1840', '1850'], 1),
        // Latinoamérica en general — no nos quedamos encerrados en Chile.
        TriviaQuestion('¿Qué libertador luchó por la independencia de Venezuela, Colombia, Ecuador, Perú y Bolivia?', ['José de San Martín', 'Simón Bolívar', "Bernardo O'Higgins", 'Antonio José de Sucre'], 1),
        TriviaQuestion('¿Qué antigua civilización mesoamericana es famosa por su calendario y sus pirámides en México?', ['Inca', 'Maya', 'Mapuche', 'Guaraní'], 1),
        TriviaQuestion('¿Cuál es el canal artificial que une el Atlántico y el Pacífico en Centroamérica?', ['Canal de Suez', 'Canal de Panamá', 'Canal de Corinto', 'Canal de la Mancha'], 1),
        TriviaQuestion('¿Qué cultura precolombina habitó el sur de Chile y Argentina y resistió por siglos a la conquista?', ['Inca', 'Mapuche', 'Azteca', 'Maya'], 1),
        TriviaQuestion('¿Cuál es el lago más grande de Sudamérica por superficie?', ['Titicaca', 'Maracaibo', 'Nahuel Huapi', 'General Carrera'], 1),
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
        TriviaQuestion('¿Cuántos dedos tenés en una mano?', ['3', '4', '5', '6'], 2),
        TriviaQuestion('¿Qué fruta es amarilla y curva?', ['Manzana', 'Banana', 'Uva', 'Pera'], 1),
        TriviaQuestion('¿De qué color es el pasto?', ['Azul', 'Verde', 'Rojo', 'Negro'], 1),
        TriviaQuestion('¿Cuántas patas tiene una vaca?', ['2', '4', '6', '8'], 1),
        TriviaQuestion('¿Qué día viene después del lunes?', ['Domingo', 'Martes', 'Miércoles', 'Jueves'], 1),
        TriviaQuestion('¿Cuántas ruedas tiene una bicicleta?', ['1', '2', '3', '4'], 1),
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
        TriviaQuestion('¿Cuál es el país más chico del mundo?', ['Mónaco', 'Vaticano', 'San Marino', 'Liechtenstein'], 1),
        TriviaQuestion('¿Cuántos jugadores tiene un equipo de fútbol en cancha?', ['9', '10', '11', '12'], 2),
        TriviaQuestion('¿Cuál es el metal líquido a temperatura ambiente?', ['Hierro', 'Mercurio', 'Plomo', 'Cobre'], 1),
        TriviaQuestion('¿Qué instrumento tiene 88 teclas?', ['Guitarra', 'Piano', 'Violín', 'Arpa'], 1),
        TriviaQuestion('¿Cuánto es 9 al cuadrado?', ['72', '81', '90', '99'], 1),
        TriviaQuestion('¿Qué gas usamos principalmente para respirar?', ['Nitrógeno', 'Oxígeno', 'Dióxido de carbono', 'Hidrógeno'], 1),
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
        TriviaQuestion('¿Cuál es el idioma oficial de Brasil?', ['Español', 'Portugués', 'Inglés', 'Francés'], 1),
        TriviaQuestion('¿Qué elemento químico tiene el símbolo "Au"?', ['Plata', 'Aluminio', 'Oro', 'Argón'], 2),
        TriviaQuestion('¿Cuál es el río más caudaloso del mundo?', ['Nilo', 'Amazonas', 'Misisipi', 'Yangtsé'], 1),
        TriviaQuestion('¿En qué año se firmó el Tratado de Maastricht (Unión Europea)?', ['1989', '1992', '1995', '2000'], 1),
        TriviaQuestion('¿Cuántos huesos tiene la mano humana (con muñeca)?', ['21', '27', '32', '36'], 1),
        TriviaQuestion('¿Quién pintó "La noche estrellada"?', ['Monet', 'Van Gogh', 'Renoir', 'Cézanne'], 1),
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
        TriviaQuestion('¿En qué año cayó Constantinopla?', ['1354', '1453', '1521', '1600'], 1),
        TriviaQuestion('¿Quién fue el primer hombre en el espacio?', ['Neil Armstrong', 'Yuri Gagarin', 'John Glenn', 'Buzz Aldrin'], 1),
        TriviaQuestion('¿En qué año se considera que comenzó la Guerra Fría?', ['1939', '1945', '1947', '1955'], 2),
        TriviaQuestion('¿Quién pintó "La última cena"?', ['Miguel Ángel', 'Da Vinci', 'Rafael', 'Botticelli'], 1),
        TriviaQuestion('¿Cuál es el metal más abundante en el núcleo terrestre?', ['Aluminio', 'Hierro', 'Níquel', 'Cobre'], 1),
        TriviaQuestion('¿Cuál es la raíz cuadrada de 169?', ['11', '12', '13', '14'], 2),
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
      TriviaQuestion('¿Cuántos lados tiene un octágono?', ['6', '7', '8', '9'], 2),
      TriviaQuestion('¿Cómo se llama el satélite natural de la Tierra?', ['El Sol', 'La Luna', 'Marte', 'Venus'], 1),
      TriviaQuestion('¿Cuánto es 7 x 7?', ['42', '47', '49', '56'], 2),
    ],
    'adolescentes': [
      TriviaQuestion('¿Cuál es la capital de Canadá?', ['Toronto', 'Ottawa', 'Vancouver', 'Montreal'], 1),
      TriviaQuestion('¿Quién escribió "Romeo y Julieta"?', ['Shakespeare', 'Cervantes', 'Dante', 'Molière'], 0),
      TriviaQuestion('¿Cuál es el hueso más largo del cuerpo humano?', ['Húmero', 'Fémur', 'Tibia', 'Radio'], 1),
      TriviaQuestion('¿Cuánto es 15% de 200?', ['20', '25', '30', '35'], 2),
      TriviaQuestion('¿En qué año comenzó la Primera Guerra Mundial?', ['1910', '1914', '1918', '1920'], 1),
      TriviaQuestion('¿Cuál es el idioma más hablado del mundo como lengua materna?', ['Inglés', 'Español', 'Mandarín', 'Hindi'], 2),
      TriviaQuestion('¿En qué año llegó Colón a América?', ['1490', '1492', '1500', '1510'], 1),
      TriviaQuestion('¿Cuál es la capital de Egipto?', ['Alejandría', 'El Cairo', 'Luxor', 'Giza'], 1),
      TriviaQuestion('¿Cuánto es 13 x 7?', ['81', '91', '96', '101'], 1),
    ],
    'adultos': [
      TriviaQuestion('¿En qué año cayó el Muro de Berlín?', ['1985', '1989', '1991', '1993'], 1),
      TriviaQuestion('¿Cuál es la velocidad aproximada de la luz?', ['300.000 km/s', '150.000 km/s', '1.000.000 km/s', '30.000 km/s'], 0),
      TriviaQuestion('¿Quién formuló la teoría de la relatividad?', ['Newton', 'Einstein', 'Bohr', 'Tesla'], 1),
      TriviaQuestion('¿Cuál es la capital de Kazajistán?', ['Almatý', 'Astaná', 'Bishkek', 'Tashkent'], 1),
      TriviaQuestion('¿Quién compuso "La novena sinfonía"?', ['Mozart', 'Bach', 'Beethoven', 'Chopin'], 2),
      TriviaQuestion('¿Cuánto es la raíz cuadrada de 225?', ['13', '14', '15', '16'], 2),
      TriviaQuestion('¿Quién descubrió la penicilina?', ['Pasteur', 'Fleming', 'Koch', 'Curie'], 1),
      TriviaQuestion('¿Cuál es la capital de Turquía?', ['Estambul', 'Ankara', 'Izmir', 'Bursa'], 1),
      TriviaQuestion('¿En qué año se lanzó el primer satélite artificial (Sputnik)?', ['1955', '1957', '1961', '1965'], 1),
    ],
    'mayores': [
      TriviaQuestion('¿En qué año terminó la Segunda Guerra Mundial?', ['1943', '1945', '1947', '1950'], 1),
      TriviaQuestion('¿Quién pintó "Guernica"?', ['Dalí', 'Picasso', 'Miró', 'Goya'], 1),
      TriviaQuestion('¿Cuál era la capital del Imperio Romano de Oriente?', ['Roma', 'Atenas', 'Constantinopla', 'Alejandría'], 2),
      TriviaQuestion('¿En qué año asumió la primera democracia post-dictadura en Argentina?', ['1981', '1983', '1985', '1989'], 1),
      TriviaQuestion('¿Quién escribió "El Quijote"?', ['Lope de Vega', 'Cervantes', 'Calderón', 'Góngora'], 1),
      TriviaQuestion('¿Cuál es la capital de Bolivia (sede de gobierno)?', ['Sucre', 'La Paz', 'Cochabamba', 'Santa Cruz'], 1),
      TriviaQuestion('¿En qué año comenzó la Guerra Civil española?', ['1931', '1936', '1939', '1945'], 1),
      TriviaQuestion('¿Quién fue el líder de la independencia de la India?', ['Nehru', 'Gandhi', 'Bose', 'Patel'], 1),
      TriviaQuestion('¿Cuál era la capital del Imperio Inca?', ['Machu Picchu', 'Cusco', 'Lima', 'Quito'], 1),
    ],
  };

  /// Banco "universal": física, matemática, geografía e historia general,
  /// sin anclar a ningún país — preguntas simples y de poca lógica (la
  /// idea es la fluidez, no trabarse pensando). Se combina automáticamente
  /// con el banco regional de cada país en [bancoPorPais], así no hace
  /// falta escribir el mismo contenido genérico tres veces (una por país).
  static const Map<String, List<TriviaQuestion>> universal = {
    'ninos': [
      TriviaQuestion('¿Qué forma tiene la Tierra?', ['Cuadrada', 'Redonda', 'Triangular', 'Plana'], 1),
      TriviaQuestion('¿Cuál es el planeta más grande del sistema solar?', ['Marte', 'Júpiter', 'Venus', 'Mercurio'], 1),
      TriviaQuestion('¿Cuántos colores tiene el arcoíris?', ['5', '6', '7', '8'], 2),
      TriviaQuestion('¿Qué astro es el centro de nuestro sistema solar?', ['La Luna', 'El Sol', 'Una estrella lejana', 'Un cometa'], 1),
      TriviaQuestion('¿Cuánto es 4 + 4?', ['6', '7', '8', '9'], 2),
      TriviaQuestion('¿Cuánto es 6 - 2?', ['2', '3', '4', '5'], 2),
      TriviaQuestion('¿Cuánto es 3 x 3?', ['6', '9', '12', '3'], 1),
      TriviaQuestion('¿Cuántos lados tiene un cuadrado?', ['3', '4', '5', '6'], 1),
      TriviaQuestion('¿Qué forma tiene una pelota de fútbol?', ['Cuadrada', 'Esférica (redonda)', 'Triangular', 'Plana'], 1),
      TriviaQuestion('¿Qué usamos para ver las estrellas de cerca?', ['Microscopio', 'Telescopio', 'Binoculares de agua', 'Una lupa gigante'], 1),
      TriviaQuestion('¿Qué parte del cuerpo usamos para escuchar?', ['Los ojos', 'Los oídos', 'La nariz', 'La boca'], 1),
      TriviaQuestion('¿Qué instrumento sirve para dibujar un círculo perfecto?', ['Regla', 'Compás', 'Escuadra', 'Transportador'], 1),
      TriviaQuestion('¿Cuántas patas tiene una gallina?', ['2', '4', '6', '8'], 0),
      TriviaQuestion('¿Qué usamos para medir cuánto pesa algo?', ['Termómetro', 'Balanza', 'Reloj', 'Regla'], 1),
      TriviaQuestion('¿Cuál es el órgano que bombea la sangre?', ['El cerebro', 'El corazón', 'El estómago', 'El pulmón'], 1),
      TriviaQuestion('¿Qué estación del año es la más fría?', ['Verano', 'Otoño', 'Invierno', 'Primavera'], 2),
      TriviaQuestion('¿Qué animal pone huevos y tiene plumas?', ['El perro', 'El gato', 'La gallina', 'El caballo'], 2),
      TriviaQuestion('¿Cuánto es 10 dividido 2?', ['3', '4', '5', '6'], 2),
    ],
    'adolescentes': [
      TriviaQuestion('¿Cuál es la fórmula química del agua?', ['CO2', 'H2O', 'O2', 'NaCl'], 1),
      TriviaQuestion('¿Cuál es la unidad básica de la vida?', ['El átomo', 'La célula', 'La molécula', 'El tejido'], 1),
      TriviaQuestion('¿Qué parte de la célula contiene la información genética?', ['La membrana', 'El núcleo', 'El citoplasma', 'La mitocondria'], 1),
      TriviaQuestion('¿Cuánto es 15 x 4?', ['45', '50', '60', '65'], 2),
      TriviaQuestion('¿Cuál es la capital de Francia?', ['Madrid', 'Roma', 'París', 'Berlín'], 2),
      TriviaQuestion('¿Qué planeta es conocido como "el planeta rojo"?', ['Venus', 'Marte', 'Júpiter', 'Saturno'], 1),
      TriviaQuestion('¿Cuántos grados tiene un ángulo recto?', ['45', '90', '180', '360'], 1),
      TriviaQuestion('¿Cuál es el río más largo de Sudamérica?', ['Paraná', 'Amazonas', 'Orinoco', 'Magdalena'], 1),
      TriviaQuestion('¿Qué científico propuso la teoría de la evolución?', ['Einstein', 'Darwin', 'Newton', 'Mendel'], 1),
      TriviaQuestion('¿Cuánto es la raíz cuadrada de 81?', ['7', '8', '9', '10'], 2),
      TriviaQuestion('¿En qué estado de la materia el agua se llama "vapor"?', ['Sólido', 'Líquido', 'Gaseoso', 'Plasma'], 2),
      TriviaQuestion('¿Cuál es el continente más poblado del mundo?', ['África', 'Asia', 'Europa', 'América'], 1),
      TriviaQuestion('¿Qué invento de Gutenberg cambió la historia de la lectura?', ['El telescopio', 'La imprenta', 'La brújula', 'El papel'], 1),
      TriviaQuestion('¿Cuántos planetas tiene el sistema solar?', ['7', '8', '9', '10'], 1),
      TriviaQuestion('¿Cuál es la capital de Japón?', ['Pekín', 'Seúl', 'Tokio', 'Bangkok'], 2),
      TriviaQuestion('¿Qué unidad se usa para medir la temperatura en la mayoría de los países?', ['Fahrenheit', 'Celsius', 'Kelvin', 'Rankine'], 1),
      TriviaQuestion('¿Cuánto es 7 x 8?', ['54', '56', '58', '64'], 1),
      TriviaQuestion('¿Qué imperio construyó el Coliseo?', ['Griego', 'Romano', 'Egipcio', 'Persa'], 1),
    ],
    'adultos': [
      TriviaQuestion('¿Quién formuló las leyes clásicas del movimiento y la gravedad?', ['Einstein', 'Newton', 'Galileo', 'Kepler'], 1),
      TriviaQuestion('¿Cuántos elementos tiene la tabla periódica, aproximadamente?', ['92', '118', '150', '200'], 1),
      TriviaQuestion('¿Cuál es el desierto cálido más grande del mundo?', ['Atacama', 'Sahara', 'Gobi', 'Kalahari'], 1),
      TriviaQuestion('¿Qué tratado puso fin a la Primera Guerra Mundial?', ['Tratado de Versalles', 'Tratado de Tordesillas', 'Tratado de Utrecht', 'Tratado de Westfalia'], 0),
      TriviaQuestion('¿Qué filósofo griego fue maestro de Alejandro Magno?', ['Sócrates', 'Platón', 'Aristóteles', 'Pitágoras'], 2),
      TriviaQuestion('¿Qué civilización construyó Machu Picchu?', ['Maya', 'Azteca', 'Inca', 'Olmeca'], 2),
      TriviaQuestion('¿Cuánto es el 30% de 90?', ['24', '27', '30', '33'], 1),
      TriviaQuestion('¿Qué elemento químico tiene el símbolo "Fe"?', ['Flúor', 'Hierro', 'Fósforo', 'Francio'], 1),
      TriviaQuestion('¿En qué siglo cayó el Imperio Romano de Occidente?', ['Siglo III', 'Siglo V', 'Siglo VII', 'Siglo X'], 1),
      TriviaQuestion('¿Qué científica descubrió la radiactividad junto a su esposo?', ['Rosalind Franklin', 'Marie Curie', 'Ada Lovelace', 'Lise Meitner'], 1),
      TriviaQuestion('¿Cuál es la capital de Sudáfrica (sede del gobierno)?', ['Johannesburgo', 'Ciudad del Cabo', 'Pretoria', 'Durban'], 2),
      TriviaQuestion('¿Qué proceso convierte el agua líquida en vapor?', ['Condensación', 'Evaporación', 'Solidificación', 'Sublimación'], 1),
      TriviaQuestion('¿Cuál es la moneda oficial de la Unión Europea?', ['Franco', 'Euro', 'Libra', 'Marco'], 1),
      TriviaQuestion('¿Quién esculpió el "David"?', ['Da Vinci', 'Miguel Ángel', 'Donatello', 'Rafael'], 1),
      TriviaQuestion('¿Cuánto es 144 dividido 12?', ['11', '12', '13', '14'], 1),
      TriviaQuestion('¿Qué país tiene forma de bota en el mapa?', ['España', 'Italia', 'Grecia', 'Portugal'], 1),
      TriviaQuestion('¿Cuál es el gas noble más liviano?', ['Neón', 'Helio', 'Argón', 'Xenón'], 1),
      TriviaQuestion('¿Qué dinastía gobernó China por más tiempo en la historia?', ['Ming', 'Qing', 'Zhou', 'Han'], 2),
    ],
    'mayores': [
      TriviaQuestion('¿En qué país se originó la Revolución Industrial?', ['Francia', 'Alemania', 'Inglaterra', 'Estados Unidos'], 2),
      TriviaQuestion('¿Qué antiguo pueblo construyó las pirámides de Guiza?', ['Mayas', 'Egipcios', 'Aztecas', 'Fenicios'], 1),
      TriviaQuestion('¿Qué antigua civilización fue de las primeras en usar la rueda?', ['Egipcia', 'Mesopotámica', 'China', 'Romana'], 1),
      TriviaQuestion('¿Qué nombre recibía el imperio gobernado por los incas?', ['Tahuantinsuyo', 'Anáhuac', 'Tenochtitlán', 'Yucatán'], 0),
      TriviaQuestion('¿Cuál es el océano que separa América de Europa y África?', ['Pacífico', 'Atlántico', 'Índico', 'Ártico'], 1),
      TriviaQuestion('¿Qué expedición es reconocida por completar la primera vuelta al mundo?', ['Cristóbal Colón', 'Vasco da Gama', 'Magallanes-Elcano', 'Marco Polo'], 2),
      TriviaQuestion('¿Cuánto es la mitad de 100?', ['40', '45', '50', '55'], 2),
      TriviaQuestion('¿Qué instrumento musical tiene cuerdas y se toca con arco?', ['Guitarra', 'Violín', 'Piano', 'Flauta'], 1),
      TriviaQuestion('¿Qué guerra de la antigua Grecia enfrentó a Esparta y Atenas?', ['Guerra Médica', 'Guerra del Peloponeso', 'Guerra Púnica', 'Guerra de Troya'], 1),
      TriviaQuestion('¿Cuál es la capital de Portugal?', ['Oporto', 'Lisboa', 'Faro', 'Coimbra'], 1),
      TriviaQuestion('¿Cuánto es 9 x 9?', ['72', '81', '90', '99'], 1),
      TriviaQuestion('¿Qué famoso barco se hundió en 1912?', ['Lusitania', 'Titanic', 'Britannic', 'Queen Mary'], 1),
      TriviaQuestion('¿Cuál es la capital de Austria?', ['Berna', 'Viena', 'Praga', 'Budapest'], 1),
      TriviaQuestion('¿Qué antiguo pueblo usaba jeroglíficos como escritura?', ['Griegos', 'Romanos', 'Egipcios', 'Persas'], 2),
      TriviaQuestion('¿Cuántas cuerdas tiene una guitarra clásica estándar?', ['4', '5', '6', '7'], 2),
      TriviaQuestion('¿Cuál es la capital de Irlanda?', ['Belfast', 'Dublín', 'Cork', 'Galway'], 1),
      TriviaQuestion('¿Qué astro causa las mareas junto con el Sol?', ['Marte', 'La Luna', 'Venus', 'Una estrella lejana'], 1),
      TriviaQuestion('¿Cuál es el idioma oficial de Egipto?', ['Árabe', 'Francés', 'Inglés', 'Hebreo'], 0),
    ],
  };

  /// Banco exclusivo de la "tanda de cuestionados" de Bonus: preguntas
  /// nuevas que no aparecen en el resto del juego, para que esa actividad
  /// no se sienta repetida con lo que ya se jugó en el tablero. No está
  /// segmentado por país (es una actividad rápida de bonus, no ligada a
  /// una partida en particular), solo por bracket de edad.
  static const Map<String, List<TriviaQuestion>> bonus = {
    'ninos': [
      TriviaQuestion('¿Qué usás para escribir en el pizarrón?', ['Lápiz', 'Tiza', 'Pincel', 'Marcador'], 1),
      TriviaQuestion('¿Cuántas letras tiene el abecedario en español (aprox.)?', ['24', '27', '30', '33'], 1),
      TriviaQuestion('¿Qué animal tiene el cuello más largo?', ['Elefante', 'Jirafa', 'Cebra', 'León'], 1),
      TriviaQuestion('¿De qué color es una banana madura?', ['Verde', 'Amarilla', 'Roja', 'Azul'], 1),
      TriviaQuestion('¿Cuántos ojos tenés?', ['1', '2', '3', '4'], 1),
      TriviaQuestion('¿Cuál de estas cosas comés en el desayuno?', ['Una piedra', 'Leche con cereales', 'Arena', 'Un papel'], 1),
      TriviaQuestion('¿Qué animal dice "guau"?', ['Gato', 'Perro', 'Vaca', 'Pato'], 1),
      TriviaQuestion('¿Cuánto es 3 + 3?', ['5', '6', '7', '8'], 1),
      TriviaQuestion('¿Qué usás para ver de noche en tu cuarto?', ['El sol', 'Una linterna', 'Un paraguas', 'Guantes'], 1),
      TriviaQuestion('¿Cuántas patas tiene una araña?', ['4', '6', '8', '10'], 2),
    ],
    'adolescentes': [
      TriviaQuestion('¿Cuál es la sustancia más dura del cuerpo humano?', ['El fémur', 'El cráneo', 'El esmalte dental', 'La mandíbula'], 2),
      TriviaQuestion('¿Qué planeta es conocido por sus anillos?', ['Marte', 'Saturno', 'Venus', 'Mercurio'], 1),
      TriviaQuestion('¿Cuál es la moneda de Japón?', ['Yuan', 'Yen', 'Won', 'Rupia'], 1),
      TriviaQuestion('¿Cuánto es 6 x 9?', ['45', '52', '54', '56'], 2),
      TriviaQuestion('¿Qué gas liberan las plantas durante la fotosíntesis?', ['Dióxido de carbono', 'Oxígeno', 'Nitrógeno', 'Hidrógeno'], 1),
      TriviaQuestion('¿Cuál es el continente más grande?', ['África', 'Asia', 'América', 'Europa'], 1),
      TriviaQuestion('¿Quién escribió la saga de "Harry Potter"?', ['J.R.R. Tolkien', 'J.K. Rowling', 'C.S. Lewis', 'Suzanne Collins'], 1),
      TriviaQuestion('¿Cuál es el animal terrestre más rápido?', ['León', 'Guepardo', 'Caballo', 'Antílope'], 1),
      TriviaQuestion('¿Cuántos minutos tiene una hora?', ['30', '45', '60', '90'], 2),
      TriviaQuestion('¿Cuál es el elemento químico más liviano?', ['Helio', 'Hidrógeno', 'Oxígeno', 'Carbono'], 1),
    ],
    'adultos': [
      TriviaQuestion('¿Cuál es la capital de Canadá?', ['Toronto', 'Ottawa', 'Vancouver', 'Montreal'], 1),
      TriviaQuestion('¿Quién pintó "La noche estrellada"?', ['Monet', 'Van Gogh', 'Renoir', 'Dalí'], 1),
      TriviaQuestion('¿Cuál es el país con más habitantes de habla hispana?', ['España', 'Argentina', 'México', 'Colombia'], 2),
      TriviaQuestion('¿En qué año terminó la Primera Guerra Mundial?', ['1914', '1917', '1918', '1920'], 2),
      TriviaQuestion('¿Cuál es el hueso más largo del cuerpo humano?', ['Húmero', 'Fémur', 'Tibia', 'Radio'], 1),
      TriviaQuestion('¿Qué órgano produce la insulina?', ['Hígado', 'Páncreas', 'Riñón', 'Bazo'], 1),
      TriviaQuestion('¿Cuál es la capital de Rusia?', ['San Petersburgo', 'Moscú', 'Kiev', 'Minsk'], 1),
      TriviaQuestion('¿Cuánto es el 15% de 300?', ['30', '35', '45', '60'], 2),
      TriviaQuestion('¿Quién fue el primer emperador romano?', ['Julio César', 'Augusto', 'Nerón', 'Trajano'], 1),
      TriviaQuestion('¿Cuál de estos metales suele ser el más caro?', ['Oro', 'Platino', 'Plata', 'Cobre'], 1),
    ],
    'mayores': [
      TriviaQuestion('¿En qué año comenzó la Revolución Francesa?', ['1776', '1789', '1799', '1804'], 1),
      TriviaQuestion('¿Quién fue el primer hombre en pisar la Luna?', ['Buzz Aldrin', 'Neil Armstrong', 'Yuri Gagarin', 'John Glenn'], 1),
      TriviaQuestion('¿Cuál era la capital del Imperio Bizantino?', ['Roma', 'Atenas', 'Constantinopla', 'Alejandría'], 2),
      TriviaQuestion('¿En qué año se fundó la Cruz Roja?', ['1859', '1863', '1901', '1914'], 1),
      TriviaQuestion('¿Quién escribió "Don Quijote de la Mancha"?', ['Lope de Vega', 'Cervantes', 'Góngora', 'Calderón'], 1),
      TriviaQuestion('¿Qué potencia envió al primer ser humano al espacio?', ['Estados Unidos', 'Unión Soviética', 'China', 'Francia'], 1),
      TriviaQuestion('¿En qué década se inventó la televisión?', ['1900s', '1920s', '1950s', '1970s'], 1),
      TriviaQuestion('¿Cuál es la capital de Grecia?', ['Atenas', 'Esparta', 'Tesalónica', 'Corinto'], 0),
      TriviaQuestion('¿Quién compuso "Las cuatro estaciones"?', ['Mozart', 'Vivaldi', 'Bach', 'Beethoven'], 1),
      TriviaQuestion('¿En qué año terminó la Guerra de Malvinas?', ['1980', '1982', '1985', '1990'], 1),
    ],
  };

  /// Brackets sin banco propio (jovenes, adultos_plus) heredan "adultos".
  static const Map<String, String> _herencia = {
    'jovenes': 'adultos',
    'adultos_plus': 'adultos',
  };

  static String _resolverBracket(String bracket) => _herencia[bracket] ?? bracket;

  // Devuelven una copia (List.of) en vez de la lista const original: los
  // que llaman a estos métodos le hacen .shuffle() al resultado, y una
  // lista const es inmutable — sin la copia, .shuffle() tira una excepción
  // (silenciosa en release) y la Cuestionados nunca llega a mostrarse.
  /// Combina el banco "universal" (física/matemática/historia general, el
  /// mismo para todos) con el regional del país — así el universal se
  /// escribe una sola vez y se aprovecha en los tres países, y el pool
  /// real de cada partida es más grande (menos chance de repetir).
  static List<TriviaQuestion> bancoPorPais(String pais, String bracket) {
    final set = porPais[pais] ?? porPais['otros']!;
    final b = _resolverBracket(bracket);
    final regional = set[b] ?? set['adultos']!;
    final general = universal[b] ?? universal['adultos']!;
    return [...general, ...regional];
  }

  static List<TriviaQuestion> bancoDificil(String bracket) {
    final b = _resolverBracket(bracket);
    return List.of(dificil[b] ?? dificil['adultos']!);
  }

  static List<TriviaQuestion> bancoBonus(String bracket) {
    final b = _resolverBracket(bracket);
    return List.of(bonus[b] ?? bonus['adultos']!);
  }
}
