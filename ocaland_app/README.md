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
  2 calavera — sin cárcel en las etapas 7-10, ver más abajo), motor de
  movimiento con la regla de rebote real
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
  decoraciones bajó (95-165px → 60-105px → 40-70px, en dos pedidos
  seguidos) para que no se sienta vacía.
- **Nubes sueltas afuera**: el usuario pidió sacar directamente las
  nubes decorativas (`nube1`/`nube2`) que seguían apareciendo pegadas
  al cartel de INICIO — se sacaron del todo, queda solo el sol.
- **Nuevo arte de trampa: calavera, minijuego y cárcel**: el usuario
  marcó que el estilo "gema brillante" de esas 3 trampas no era el que
  quería (mandó ese estilo por error/como prueba) y mandó reemplazos:
  calavera amigable con ojitos grandes, estrella con cara para
  minijuego, y una torre de piedra con celda para cárcel. Los 3 venían
  con fondo tipo casillero de transparencia "quemado" en el RGB (sin
  canal alfa real) en vez de checkerboard prolijo — se procesaron con
  un flood-fill desde el borde que solo avanza por píxeles acromáticos
  dentro del rango de brillo del casillero (evita comerse el color
  cálido de la piedra/hueso real). La calavera pasó de 3 frames
  animados (mandíbula) a una sola imagen estática — no llegó un set de
  frames nuevo, así que se sacó la animación especial y ahora usa el
  mismo camino que cárcel/minijuego/trampolín (`iconoEstatico`). El
  puente/trampolín sigue con el arte anterior (no llegó reemplazo
  todavía).
- **Trampolín real + cárcel más colorida**: llegó el reemplazo del
  trampolín (un trampolín de juegos de verdad, con red y colchoneta
  estampada) — se recortó la parte de arriba (red/postes) porque
  quedaba un patrón de casillero sin limpiar entre los hilos de la red
  y a esta escala de casilla no se distingue de todos modos; con el
  colchón+patas alcanza para reconocerlo. La cárcel se reemplazó por
  una versión a color de la misma torre (más "presencia" junto al
  resto de casillas coloridas, como pidió el usuario) en vez de la
  versión gris/oscura de antes.
- **Los trampolines nunca se encadenan**: el usuario marcó que, como el
  trampolín adelanta 2-4 casillas de entrada, dos trampolines nunca
  deberían quedar tan cerca como para que caer en uno te mande derecho
  a otro — no tendría lógica de juego. `board_layout.dart` ahora
  reintenta el sorteo del layout (hasta 300 veces, casi siempre alcanza
  con 1-2) hasta que los 3 trampolines queden a 5 casillas de distancia
  como mínimo entre sí.
- **Sol contenido en su franja (de verdad esta vez)**: la causa real de
  que "el sol siga en el pasto" no era su posición X/Y sino su tamaño:
  el halo brilloso medía 130px fijos, pensado para cuando la franja de
  imagen real medía ~213-355px; al recortar los fondos esa franja bajó
  a 44-78px y el halo se desbordaba ~90px hacia el pasto de abajo sin
  que la posición del ícono se moviera. Ahora el sol (ícono + halo) se
  calcula en proporción a `altoImagen` (o al 10% de alto del cielo
  genérico cuando no hay imagen real), así que siempre queda contenido
  adentro sin importar cuán baja sea esa franja.
- **El doble de decoración, en los codos del sendero**: además de la
  decoración pegada a los bordes del canvas, ahora `fondo_candy.dart`
  recibe el camino real y detecta cada "codo" (donde el sendero cambia
  de dirección) para poner 2 elementos ahí — arbusto/flor/roca +
  una oca de adorno — del lado de afuera de la curva (el espacio verde
  que deja el giro), no solo en los bordes.
- **3 formas de sendero + bloques "sin sendero" + fondos nuevos**: el
  usuario pidió que el tablero varíe bastante más entre bloques de
  etapas:
  - **Etapas 1-6 (Comienzo + Desafío) con sendero**: `camino_tablero.dart`
    ahora genera 3 formas distintas (`FormaCamino`) en vez de solo la
    serpiente — interrogación (un gancho arriba + tallo ondulado hacia
    abajo) y espiral (radio creciente + varias vueltas, como un resorte
    visto de costado) — y rota por etapa (`FormaCamino.deEtapa`: 1
    serpiente, 2 interrogación, 3 espiral, 4 serpiente, ...). El fondo
    del bloque Desafío (etapas 4-6) pasó de `fondo_jardin.png` a
    `fondo_valle.png` (montañas, río, monedas, cristales) que mandó el
    usuario — a diferencia de bosque/castillo, no tiene franja de
    relleno plano que recortar, así que se usa completa.
  - **Etapas 7-10 (Tensión + Cima) sin sendero**: no hay camino de
    tierra dibujado — las 30 casillas quedan sueltas/flotando
    (`lib/game/tablero_flotante.dart`, `TableroWidget.sinSendero`),
    reordenadas en cada etapa con una separación mínima real en
    píxeles para que no se superpongan (no arman una curva continua
    como `CaminoTablero`). Ninguna de estas etapas tiene cárcel
    (`BoardLayout.generar(sinCarcel: true)` reparte esas 3 casillas
    entre oca/minijuego/trampolín). Tensión (7-9) sigue sin fondo de
    escena real — ahora usa un gradiente oscuro/volcánico + rocas de
    lava sueltas como decoración (`fondo_candy.dart`,
    `_decoracionLava`) en vez del pasto genérico. Cima (etapa 10) pasó
    de `fondo_castillo.png` a `fondo_carnaval.png` (calle de carnaval
    con fuegos artificiales y comparsa) que mandó el usuario.
  - Los bloques "sin sendero" tampoco muestran sol ni ocas volando de
    fondo (no tiene sentido un cielo soleado en una cueva de lava o de
    noche en el carnaval), y se saltean la decoración de "codos" (no
    hay curva de la que tomar el lado de afuera).
- **Ronda de ajustes sobre lo anterior, etapa por etapa** (el usuario
  probó las 10 etapas y marcó qué servía y qué no):
  - **Interrogación sin cruzarse**: la primera versión barría ~260°
    (casi una vuelta completa) y con el ancho real del camino pintado
    se veía "un rulo que se entrecruza" — el usuario lo marcó como "no
    sirve". Se rediseñó a un arco de exactamente 180° (medio círculo,
    de un lado al otro pasando por arriba) que geométricamente no
    puede volver a pasar por donde ya pasó, seguido del tallo hacia
    abajo como antes.
  - **Valle ocupa mucho más del tablero**: el usuario pidió "ocupar
    todo el fondo" en vez del ~34% de franja que ocupaba. Se agregó
    `PaletaBloque.fondoAlturaMinima` (0.55 para Desafío): agranda el
    recuadro de la imagen más allá de su alto natural y usa
    `BoxFit.cover` para llenarlo (recorta un poco los costados, no
    estira), dejando ~35% igual para la decoración de abajo que
    también pidió.
  - **Tablero flotante con "sentido de sendero invisible"**: en los
    bloques sin camino dibujado, cada casilla ahora camina un paso
    acotado en X desde la casilla anterior (en vez de sortear X
    totalmente al azar) para que 1→2→3... se sienta consecutivo, como
    si seguyera un sendero invisible — pedido explícito del usuario.
  - **Más trampas en las etapas 8-9 de Tensión**: el usuario pidió que
    esas etapas tengan más trampas que la 7 — `BoardLayout.generar`
    ahora acepta `trampasIntensas` (24 de 28 casillas, en vez de 20,
    todavía sin cárcel) para las etapas 8 y 9.
  - **Etapa 10 sigue el camino de mosaico ya pintado en la imagen**:
    el usuario notó que `fondo_carnaval.png` ya trae un sendero de
    mosaico dibujado y pidió usar ESE camino para ubicar las 30
    casillas reales, terminando junto al escenario con los fuegos
    artificiales ("que dé sensación de terminación"). Se agregó
    `lib/game/tablero_carnaval.dart`: puntos de control medidos a mano
    sobre la imagen (con una grilla superpuesta) siguiendo el centro
    del mosaico, repartidos por longitud de arco igual que
    `CaminoTablero`. También se subió `fondoAlturaMinima` de Cima a
    0.85 para que ese camino tenga lugar real para 30 casillas
    espaciadas.
  - **Etapa 4 con fondo de bosque**: el usuario reportó que la etapa 4
    seguía mostrando el bosque en vez del valle. Se verificó
    `PaletaBloque.deEtapa(4)` directamente (test manual) y devuelve
    `fondo_valle.png` correctamente — bloqueDeEtapa no cambió sus
    límites (1-3/4-6/7-9/10) en ningún momento de esta sesión. Es
    probable que haya sido una build vieja en la pantalla que estaba
    probando.
- **Segunda ronda etapa por etapa, con arte nuevo del usuario**:
  - **Interrogación más parecida a un "?" de verdad**: el arco de 180°
    de la ronda anterior no se cruzaba, pero al usuario le pareció
    poco parecido a un signo de pregunta real. Un círculo/arco no
    puede cruzarse a sí mismo sin importar cuánto barra (lo que se
    cruzaba antes era el tallo volviendo a pasar cerca del gancho, ya
    resuelto); aprovechando eso se agrandó el barrido a 235° — bastante
    más parecido al rulo real — sin volver a arriesgar el cruce.
  - **Sendero del valle angostado hacia el centro**: el usuario marcó
    que el sendero llegaba hasta las montañas de los bordes de la
    imagen ("quedaría lindo si camina al lado de la montaña... hay un
    valle que se puede usar"). `CaminoTablero.generar` ahora acepta
    `escalaHorizontal` (0.55 para el bloque Desafío) que angosta
    cualquier forma hacia el centro sin tocar su lógica — el sendero
    se queda en la franja verde abierta entre las montañas.
  - **Escena real de lava con las 30 casillas exactas del usuario**:
    el usuario mandó la escena de plataformas de roca flotante
    conectadas por grietas de lava — y, para no dejar lugar a
    interpretación, una segunda versión con los 30 números puestos a
    mano sobre cada piedra ("te ahorro el trabajo"). Se leyeron esas
    30 posiciones directamente de la imagen numerada (con una grilla
    superpuesta) y se armó `lib/game/tablero_lava.dart` con esos
    puntos fijos — a diferencia de `TableroCarnaval` (que interpola
    entre pocos puntos de control), acá son las 30 posiciones exactas
    que marcó el usuario. La imagen (`fondo_lava.png`) venía con fondo
    negro sólido (no checkerboard) — se le sacó con flood-fill desde
    el borde, misma técnica que las casillas de trampa. Reemplaza el
    gradiente oscuro genérico + rocas sueltas de la ronda anterior
    (`TableroFlotante` y esa decoración quedaron sin uso, se
    borraron).
  - El bloque "sin sendero" (Tensión + Cima) ahora también se saltea
    el sol, la decoración de árboles/flores/rocas y las ocas de fondo
    del paisaje "candy" genérico — esos dos bloques ya traen su propia
    escena completa (cueva de lava, calle de carnaval de noche) y esa
    decoración encima no pegaba.

### Simplificaciones de este corte (a mejorar después)

- Las 3 formas de sendero son curvas paramétricas genéricas, no un
  trazado dibujado a mano — funcionan para cualquier cantidad de
  casillas pero no imitan un mapa puntual.
- Solo la franja de arriba del tablero (bosque) es un recorte; en
  valle/carnaval/lava se usa la imagen completa, agrandada más allá de
  su alto natural con `fondoAlturaMinima` cuando hace falta. El resto
  del tablero hacia abajo (una franja chica, sobre todo en lava/
  carnaval) sigue siendo color liso + textura de pasto genérica.
- El angostado del sendero del valle (`escalaHorizontal`) es una
  aproximación pareja (más centrado en todo el recorrido) — no evita
  puntualmente cada saliente de montaña como sí hacen
  `TableroCarnaval`/`TableroLava` con sus puntos medidos a mano; si
  hace falta más precisión, el mismo truco de la imagen con números
  puestos a mano serviría acá también.
- Cuestionados todavía no está segmentado por país (Argentina / Chile /
  Internacional) ni tiene pantalla de selección de edad/país — usa
  `adultos` fijo por ahora.
- No están: pistas, reintentar-con-video-o-monedas, ni sonido.
- Los accesorios (gorro, anteojos, bufanda, corona) todavía no tienen
  arte real — se muestran con un ícono de Material Design.
- El bot no tiene personalización propia todavía: usa un color fijo
  para verse distinto del jugador.
- El estilo "cristal/gema brillante" original ya no queda en ninguna
  casilla de trampa: calavera, minijuego, cárcel y trampolín se
  reemplazaron todas por arte real que mandó el usuario (ver más
  arriba). Ver sección 8 de `docs/SPEC_VISUAL_V2.md` (desactualizada en
  este punto, todavía describe el estilo gema).

Todavía **no** están implementados: multijugador en tiempo real (sala,
campaña grupal, desafío grupal), economía de monedas visible en pantalla,
sonido, ni notificaciones push. Eso es el próximo tramo de trabajo (ver
sección 16 de la especificación para lo pendiente de más largo plazo).

## Notas

- La clave `anon` de Supabase embebida en `lib/config/supabase_config.dart`
  es pública por diseño (igual que en `index.html`): la seguridad real la da
  RLS + las funciones `SECURITY DEFINER` del lado del servidor, no el
  secreto de esa clave.
