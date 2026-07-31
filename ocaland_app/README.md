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
- **Rediseño completo del tablero como paisaje continuo** (`lib/widgets/board/tablero_widget.dart`,
  `fondo_candy.dart`): el usuario marcó que la versión anterior no
  servía — casillas flotando como discos separados, íconos sueltos
  sobre color plano, sin marca de inicio/meta. Se rehizo de punta a
  punta:
  - **Sendero real**: el camino pasó de una línea fina pintada a un
    camino de tierra ancho (borde oscuro + cuerpo claro + centro
    pisado + piedritas de textura a los costados).
  - **Casillas incrustadas**: las normales son piedras redondas con
    el número, del mismo ancho que el camino, no discos flotando
    encima — se ven parte del sendero. Las de trampa siguen siendo su
    propio arte a tamaño completo (más grandes, sin disco de fondo).
  - **Paisaje continuo**: colina única con textura de pasto real
    (matitas dibujadas, no color liso) y árboles/arbustos/rocas/flores
    repartidos a intervalos regulares en TODA la altura del tablero
    (antes eran ~8 íconos sueltos en puntos fijos, se veían pegados;
    ahora la densidad escala con el alto real del tablero).
  - **Marcas de INICIO y META**: banderín + bandera al principio,
    banderín + trofeo + medallón dorado al final — antes solo eran
    íconos chicos genéricos.
  - **Avatar caminando de verdad**: la ficha se desliza animada
    (`AnimatedPositioned`) entre casilla y casilla en vez de saltar de
    golpe, sincronizado con el ciclo de caminata del sprite.
  - **Tablero desplazable con casillas espaciadas**: las 30 casillas
    quedaban pegadas/superpuestas entre sí — el tablero ahora es
    bastante más alto que la pantalla (`SingleChildScrollView` vertical,
    con auto-scroll a la ficha activa) para darles aire real, y
    `camino_tablero.dart` reparte los 30 puntos por longitud de arco en
    vez de por parámetro `t` parejo.
- **"Puente" renombrado a "trampolín"**: la mecánica real de esa
  casilla es lanzar al jugador +2/+4 casillas de entrada, no un cruce
  — se renombró en todo el código (`TipoCasilla.trampolin`,
  `InfoTrampolin`) para que el nombre no confunda con la mecánica. La
  casilla muestra solo su propio ícono, sin agua/puente decorativo
  alrededor (se probó esa decoración y el usuario pidió sacarla).
- **Fondo de escena real por bloque** (`lib/theme/paleta_bloque.dart`
  campos `fondoAsset`/`fondoAspectRatio`/`fondoColorPie`,
  `assets/paisaje/fondos/`): el usuario proveyó fondos ilustrados
  completos (no piezas sueltas) — bosque, jardín celestial y castillo
  flotante. Primero se probó estirar la imagen para cubrir todo el
  tablero alto (`BoxFit.cover`), pero eso desalineaba el cielo/sol/nube
  con el pasto y el camino "empezaba en el cielo y terminaba en
  cualquier lado". La versión final muestra la imagen **una sola vez, a
  su proporción natural, arriba del todo** (ahí van el cielo, el sol,
  las nubes y el INICIO), y el resto del tablero hacia abajo se pinta
  con el color muestreado del borde inferior de esa misma imagen +
  textura de pasto, para que la transición sea pareja. Mapeados por
  bloque de etapas: Comienzo → bosque, Desafío → jardín, Cima →
  castillo flotante. El bloque Tensión todavía usa el fondo genérico
  (colina + pasto dibujado) porque el arte que hay de ese bloque es
  roca volcánica suelta, no una escena completa.
- **Ajustes de legibilidad tras probar el tablero completo**: el
  usuario marcó (viendo el tablero de punta a punta, no solo lo que
  entra en una pantalla) que el sol/nubes quedaban tapados por el
  cartel de INICIO cuando el camino arrancaba hacia ese lado, que los
  arbustos/árboles quedaban montados sobre el camino en las curvas más
  amplias, que las trampas costaban distinguirse contra el fondo real,
  y que las fichas se veían chicas. Se corrigió: sol/nubes pegados al
  borde de arriba del todo (fuera del rango donde puede llegar el
  cartel de INICIO), decoración empujada a los bordes verdaderos del
  canvas, aura de color detrás de cada trampa (amarillo=oca,
  turquesa=trampolín, gris=cárcel, fucsia=calavera, celeste=minijuego)
  para que se distingan de un vistazo, fichas más grandes (30→42px), y
  el camino arranca un poco más abajo (deja aire para el cartel) con
  más amplitud/frecuencia de curva para que serpentee de forma más
  visible.
- **Tablero compactado a una sola pantalla**: el usuario marcó que la
  imagen completa "no entra en una pantalla de celular". El alto real
  del contenido del tablero dependía de `_aspectRatioContenido`
  (0.22, muy angosto/alto) — se subió a 0.62 y, para que las 30
  casillas no volvieran a superponerse en un tablero más bajo, el
  camino (`camino_tablero.dart`) pasó a tener muchas más
  curvas/vueltas (`frecuencia` 3.0-4.8 → 6.0-8.5) para acumular
  suficiente longitud de recorrido en menos alto. Resultado: INICIO y
  META entran juntos en una pantalla de celular normal, sin scroll.
  Como efecto colateral esto también resolvió el reclamo de "nubes en
  el pasto": al ocupar la imagen real una franja proporcionalmente
  mucho más grande del tablero compactado, el sol/las nubes quedan
  dentro de la escena ilustrada en vez de flotar sobre el pasto de
  relleno de abajo.
- **Dados con el arte nuevo**: el usuario subió un set de dados más
  nítido (fondo blanco, pips gris oscuro); se recortaron las 6 caras
  desde la grilla 3×2 (detectando los bordes reales por canal alfa,
  no por división pareja del ancho de imagen, porque el contenido no
  ocupaba todo el ancho) y reemplazaron `assets/dado/estatico_*.png`.
  No llegó un set nuevo de frames "con desenfoque de movimiento" a
  juego con este estilo, así que el ciclo rápido de tirada reutiliza
  las mismas 6 caras limpias en vez de mezclar dos estilos de arte.
- **Ocas volando de fondo**: unas pocas siluetas de la animación de
  vuelo de la oca, puramente decorativas (no son casillas), repartidas
  a lo largo del camino para darle más vida a la escena.
- **Leyenda al caer en una trampa**: antes el mensaje de la casilla
  solo aparecía después de resolver la trivia/minijuego. Ahora, al
  caer en oca/cárcel/calavera/minijuego, primero se muestra un aviso
  de llegada ("Caíste en la oca: ¡a responder!", etc.) y recién
  después se abre la trivia o el minijuego. El trampolín también
  muestra a qué casilla exacta salta ("¡Caíste en el trampolín!
  Saltás a la casilla 18.") en vez de solo el avance en casillas.
- **Fondos recortados: sin "nubes" falsas en el pasto**: la compactación
  de arriba no alcanzaba — el usuario seguía viendo manchas con forma de
  nube en la parte verde. La causa real: los 3 fondos (`fondo_bosque`,
  `fondo_jardin`, `fondo_castillo`) son ilustraciones completas de una
  escena (árboles/castillo/isla flotante) seguidas de una franja de
  "relleno" plano con manchones claros pintados a mano (parecen nubes)
  y, en dos de los tres, niebla/nubes recortadas justo en el borde
  inferior — se notaba apenas se mostraba más que la franja superior.
  Se recortaron los 3 PNG (`assets/paisaje/fondos/`) para quedarse solo
  con la franja de escena real (detectando dónde el detalle de la
  ilustración cae a una zona plana, por varianza de color por fila) y
  se actualizó `fondoAspectRatio`/`fondoColorPie` en `paleta_bloque.dart`
  acorde al nuevo recorte. Ahora esa franja real es angosta y el resto
  del tablero (pasto + decoración procedural) no tiene ninguna mancha
  rara.
- **INICIO y META ya no se cortan**: con el tablero compactado, el
  cartel de INICIO (96px de alto) se posicionaba con la punta arriba
  del borde superior del área scrolleable (fuera de rango, invisible)
  y el marcador de META quedaba pegado al borde inferior sin aire para
  distinguirse. `camino_tablero.dart` le da más margen arriba y abajo
  (`y = 0.14 + 0.76*t`, antes `0.11 + 0.85*t`) para que ambos entren
  completos.
- **Más densidad de flores y rocas**: el usuario pidió más variedad en
  la franja de pasto de relleno — la lista de decoración pondera más
  rocas/flores (antes un ítem cada una, ahora dos) y el intervalo entre
  decoraciones bajó (95-165px → 60-105px) para que no se sienta vacía.

### Simplificaciones de este corte (a mejorar después)

- El camino serpenteante es una curva paramétrica genérica (seno), no un
  trazado dibujado a mano — funciona para cualquier cantidad de casillas
  pero no imita un mapa puntual. El usuario confirmó que este estilo le
  gusta y pidió, como exploración futura (no urgente), probar otras
  formas de camino con la misma lógica de generación (circular, espiral)
  para comparar.
- El bloque "Tensión" (etapas 7-9) todavía no tiene fondo de escena real
  (usa colina + pasto dibujado) — falta conseguir/generar una escena
  volcánica completa como las otras 3, o adaptar el arte de roca/lava
  suelto que sí hay.
- Solo la franja de arriba del tablero es la imagen real; el resto es
  color liso + textura de pasto genérica — no es una ilustración de
  todo el tablero hecha a mano.
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
