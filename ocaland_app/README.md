# Ocaland (Flutter)

Reescritura en Flutter del prototipo HTML de Ocaland. Usa el mismo backend
de Supabase (proyecto `ejobycpstnbzkjnlebrd`, schema `la_vuelta`) que
`../index.html`. La especificación completa está en `../docs/SPEC.md`.

## Requisitos

- Flutter 3.44+ (canal stable)
- Para compilar Android: Android Studio / Android SDK
- Para compilar iOS: Xcode (solo en macOS)

## Cómo correrlo

```bash
cd ocaland_app
flutter pub get
flutter run            # en un emulador/dispositivo conectado
flutter run -d chrome  # en el navegador, para probar rápido
```

## Estado actual

- Conexión a Supabase (`lib/services/supabase_service.dart`) apuntando al
  schema `la_vuelta`, con wrappers para las funciones RPC del servidor
  (monedas, stats, recompensa diaria, etc.).
- Modelos (`lib/models/`) calcados 1 a 1 del esquema real de la base
  (`usuarios`, `partidas`, `jugadores_partida`, `desafios_grupales`,
  `desafios_resultados`).
- Identidad persistente por dispositivo (`lib/services/session_service.dart`)
  usando `shared_preferences`, igual que el `localStorage` del prototipo.
- Pantalla de nombre para usuarios nuevos + reconocimiento automático al
  volver a abrir la app.
- Menú principal con las 3 pestañas (Jugar / Bonus / Cuenta) y tema visual
  "Candy Crush" (`lib/theme/ocaland_theme.dart`).
- **Campaña Solo jugable** (`lib/screens/board_screen.dart`, `lib/game/`):
  tablero de 30 casillas con layout aleatorio por etapa (`board_layout.dart`,
  20/30 trampa repartidas 6 oca / 6 minijuego / 3 trampolín / 3 cárcel /
  2 calavera), motor de movimiento con la regla de rebote real
  (`game_engine.dart`), animación de caminata casilla por casilla,
  Cuestionados con timer y banco chico por franja de edad
  (`game/cuestionados/`), minijuego de Reflejos, trampolines con avance
  automático (2-4 casillas), bot con dificultad creciente por etapa
  (`game/campana/config_etapa.dart`), las 10 etapas con nombre y lore
  (`game/campana/etapa.dart`), y el flujo de "Reintentar" / "Responder 3
  Cuestionados para pasar igual" al perder una etapa.
- **Identidad visual v2** (`docs/SPEC_VISUAL_V2.md`): paletas por bloque de
  etapas (`lib/theme/paleta_bloque.dart`), casillas de trampa más grandes
  con animación de reposo (`lib/widgets/board/casilla_trampa_animada.dart`),
  y efectos de feedback — destello de estrellas, sacudida+rojo, confeti,
  monedas flotantes (`lib/widgets/effects/`).
- **Personalización de avatar** (`lib/screens/mi_avatar_screen.dart`):
  catálogo de siluetas/colores/accesorios en Supabase
  (`personalizacion_catalogo`), desbloqueables con monedas vía RPC
  (`comprar_item_personalizacion`, `equipar_personalizacion`, ambas
  `SECURITY DEFINER` — el precio y la pertenencia silueta↔color se validan
  del lado del servidor, nunca se confía en el cliente).
- **Arte real de avatares y casillas** (`assets/avatars/`, `assets/casillas/`):
  3 personajes jugables con ciclo de caminata, festejo y reacción al
  fallar (`lib/game/avatares/avatar_sprites.dart`), usados en la ficha del
  tablero y en los efectos de festejo/reacción. Íconos reales para
  trampolín/cárcel/calavera/minijuego, y animación de vuelo real para la
  oca. Ícono de la app actualizado en Android/iOS/web.
- **Tablero como camino serpenteante** (`lib/widgets/board/camino_tablero.dart`,
  `tablero_widget.dart`): las 30 casillas se ubican sobre una curva
  paramétrica (no una grilla), tipo mapa de Candy Crush, con casillas de
  trampa más grandes que las normales y un camino pintado debajo
  conectándolas.
- **Dado con arte real y sensación de movimiento** (`lib/widgets/board/dado_widget.dart`,
  `lib/game/dado_iconos.dart`): al tirar, cicla por los frames de
  motion-blur antes de asentarse en la cara final con el resultado real.
- **Ruleta de premio entre etapas con comodines reales** (`lib/widgets/ruleta/ruleta_widget.dart`,
  `lib/screens/ruleta_premio_dialog.dart`, `lib/game/campana/comodin_ruleta.dart`):
  al ganar una etapa (salvo la última), gira una ruleta de 6 gajos con el
  arte real del usuario antes de arrancar la etapa siguiente. Los premios
  son `+3 casillas` (avanza de entrada en la nueva etapa), `inmunidad`
  (perdona el próximo fallo en Cuestionados), `tirada extra` (vuelve a
  tirar sin pasar el turno) y `doble tiempo` (duplica el timer de la
  próxima pregunta), más 2 gajos "sin premio". El ángulo de cada gajo se
  midió a mano sobre `assets/ruleta/disco.png` porque el arte no divide
  el círculo en sextos parejos (ver comentario en `ruleta_widget.dart`).
- **Minijuego de Memoria** (`lib/screens/minijuego_memoria_dialog.dart`)
  con el arte real de gemas (`assets/minijuegos/gema_*.png`): el jugador
  repite una secuencia de 3 gemas iluminadas. Al caer en una casilla de
  minijuego, el juego elige al azar entre Memoria y Reflejos.
- **Reflejos con arte real** (`lib/screens/minijuego_reflejos_dialog.dart`):
  reskin con el orbe rojo (`assets/minijuegos/orbe_reflejos.png`) en vez
  del círculo de color liso.
- **Paisaje del tablero con arte real** (`lib/widgets/board/fondo_candy.dart`,
  `assets/paisaje/`): árboles (2 tipos), arbustos, flores, rocas, nubes,
  sol y un puente real que cruza un charco de agua en cada casilla de
  trampolín (anclado a la posición real de esa casilla vía
  `_trampolinesPx`), reemplazando el fondo dibujado en código.
- **Tablero desplazable con casillas espaciadas** (`tablero_widget.dart`):
  las 30 casillas quedaban pegadas/superpuestas entre sí — el tablero
  ahora es bastante más alto que la pantalla (`SingleChildScrollView`
  vertical, con auto-scroll a la ficha activa) para darles aire real,
  y `camino_tablero.dart` reparte los 30 puntos por longitud de arco
  en vez de por parámetro `t` parejo.
- **Casillas de trampa sin disco de fondo**: antes eran un círculo de
  color con el ícono de la trampa metido adentro; ahora la trampa se
  muestra directamente a tamaño completo (sin círculo genérico atrás)
  — la trampa ES la casilla. Las normales/salida/meta siguen siendo un
  disco tipo ficha con número.
- **"Puente" renombrado a "trampolín"**: la mecánica real de esa
  casilla es lanzar al jugador +2/+4 casillas de entrada, no un cruce
  — se renombró en todo el código (`TipoCasilla.trampolin`,
  `InfoTrampolin`) para que el nombre no confunda con la mecánica.

### Simplificaciones de este corte (a mejorar después)

- El camino serpenteante es una curva paramétrica genérica (seno), no un
  trazado dibujado a mano — funciona para cualquier cantidad de casillas
  pero no imita un mapa puntual.
- Cuestionados todavía no está segmentado por país (Argentina / Chile /
  Internacional) ni tiene pantalla de selección de edad/país — usa
  `adultos` fijo por ahora.
- No están: pistas, reintentar-con-video-o-monedas, ni sonido.
- Los accesorios (gorro, anteojos, bufanda, corona) todavía no tienen
  arte real — se muestran con un ícono de Material Design.
- El bot no tiene personalización propia todavía: usa un color fijo
  para verse distinto del jugador.
- El estilo "cristal/gema brillante" de las casillas de trampa está
  confirmado como intencional por el usuario (no es una inconsistencia
  a corregir). La calavera se reemplazó por una versión más amigable
  (ojos celestes en vez de rojos, con animación de mandíbula). Ver
  sección 8 de `docs/SPEC_VISUAL_V2.md`.

Todavía **no** están implementados: multijugador en tiempo real (sala,
campaña grupal, desafío grupal), economía de monedas visible en pantalla,
sonido, ni notificaciones push. Eso es el próximo tramo de trabajo (ver
sección 16 de la especificación para lo pendiente de más largo plazo).

## Notas

- La clave `anon` de Supabase embebida en `lib/config/supabase_config.dart`
  es pública por diseño (igual que en `index.html`): la seguridad real la da
  RLS + las funciones `SECURITY DEFINER` del lado del servidor, no el
  secreto de esa clave.
