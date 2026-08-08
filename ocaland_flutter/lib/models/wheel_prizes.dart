/// Premios de la ruleta que aparece al superar una etapa — compartidos
/// entre el modo solo y el multijugador, así la rueda (con sus 6
/// divisiones) puede dibujarse igual en los dos lados.
const wheelPrizes = <Map<String, String>>[
  {'id': 'ventaja3', 'icon': '⏩', 'label': '+3 casillas de ventaja'},
  {'id': 'doble_tiempo', 'icon': '⏳', 'label': 'Doble tiempo en tu próxima Cuestionados'},
  {'id': 'nada', 'icon': '❌', 'label': 'Nada esta vez'},
  {'id': 'tirada_extra', 'icon': '🎁', 'label': '+1 tirada extra al empezar'},
  {'id': 'inmunidad', 'icon': '🛡️', 'label': 'Inmunidad a una trampa'},
  {'id': 'nada', 'icon': '❌', 'label': 'Nada esta vez'},
];

/// Ícono + nombre corto de cada tipo de comodín, por id — para mostrar el
/// inventario (perfil) y el selector de "qué comodín usar" sin repetir la
/// lista de arriba (que además tiene entradas duplicadas de 'nada').
const comodinInfo = <String, (String, String)>{
  'ventaja3': ('⏩', '+3 casillas de ventaja'),
  'doble_tiempo': ('⏳', 'Doble tiempo en Cuestionados'),
  'tirada_extra': ('🎁', 'Tirada extra al empezar'),
  'inmunidad': ('🛡️', 'Inmunidad a una trampa'),
};
