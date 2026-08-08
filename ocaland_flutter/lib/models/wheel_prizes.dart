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
