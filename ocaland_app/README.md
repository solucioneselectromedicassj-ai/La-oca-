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
  20/30 trampa repartidas 6 oca / 6 minijuego / 3 puente / 3 cárcel /
  2 calavera), motor de movimiento con la regla de rebote real
  (`game_engine.dart`), animación de caminata casilla por casilla,
  Cuestionados con timer y banco chico por franja de edad
  (`game/cuestionados/`), minijuego de Reflejos, puentes con avance
  automático, bot con dificultad creciente por etapa
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
  puente/cárcel/calavera/minijuego, y animación de vuelo real para la
  oca. Ícono de la app actualizado en Android/iOS/web.

### Simplificaciones de este corte (a mejorar después)

- El tablero se dibuja en trazado de serpiente (fila por fila), no en
  espiral real — el orden lógico de casillas es el mismo, solo cambia la
  disposición visual.
- Cuestionados todavía no está segmentado por país (Argentina / Chile /
  Internacional) ni tiene pantalla de selección de edad/país — usa
  `adultos` fijo por ahora.
- No están: pistas, reintentar-con-video-o-monedas, comodines (doble
  tiempo / inmunidad), ruleta de premio entre etapas, ni sonido.
- Los accesorios (gorro, anteojos, bufanda, corona) todavía no tienen
  arte real — se muestran con un ícono de Material Design.
- El bot no tiene personalización propia todavía: usa un color fijo
  para verse distinto del jugador.
- **Inconsistencia de estilo pendiente de resolver**: los íconos de
  casillas de trampa y el vuelo de la oca tienen un estilo "cristal/gema
  brillante" bien distinto al cartoon plano de los avatares, y la
  calavera en particular es más intensa (ojos rojos brillantes) de lo
  que pide el tono "nunca oscuro/tétrico" del documento visual. Ver
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
