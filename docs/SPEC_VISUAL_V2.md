# Ocaland — Especificación visual v2 (con animación y paletas por etapa)

Instrucción para vos, Claude Code: esto reemplaza la especificación visual anterior. Los cambios clave: la paleta de colores **cambia según el bloque de etapas** (no es una única paleta fija todo el juego), las casillas de trampa son **más grandes y animadas**, y los avatares/eventos del juego tienen **animación real en pantalla**, no solo íconos estáticos. Si algo acá es ambiguo, preguntame antes de decidir por tu cuenta — no inventes de más.

---

## 1. Paletas por bloque de etapas (NO una sola paleta fija)

El juego tiene 10 etapas con nombre propio. Se agrupan en 4 bloques visuales, y el tablero/fondo/iluminación general cambia de paleta en cada bloque — así cada tramo de la campaña se **ve distinto**, no siempre el mismo esquema de colores.

| Bloque | Etapas | Tema | Paleta sugerida |
|---|---|---|---|
| **1. Comienzo** | 1-3 (El Nido Inicial, El Estanque Sereno, El Bosque de las Dudas) | Natural, cálido, amigable | Verdes frescos, amarillos suaves, celeste cielo — sensación de mañana soleada |
| **2. Desafío** | 4-6 (La Colina Ventosa, El Valle de los Espejismos, La Cueva Oscura) | Más misterioso, aire fresco | Violetas, azules profundos, turquesa — sensación de atardecer/viento |
| **3. Tensión** | 7-9 (El Puente Colgante, La Montaña Helada, El Desfiladero Final) | Intenso, exigente | Rojos/naranjas cálidos combinados con blanco hielo — sensación de peligro controlado, nunca oscuro/tétrico |
| **4. Cima** | 10 (La Cima de Ocaland) | Épico, celebratorio | Dorado + toques de todos los colores anteriores (arcoíris sutil) — sensación de gran final |

Los **avatares de jugador y los íconos de casillas especiales mantienen su forma y diseño igual en todo el juego** (para que se reconozcan siempre) — lo que cambia por bloque es el fondo del tablero, la iluminación ambiente, y detalles decorativos del camino (vegetación, clima, texturas). No rediseñar personajes ni casillas por bloque, solo el entorno.

---

## 2. Estilo general (se mantiene en todos los bloques)

- Ilustración plana tipo cartoon (flat design / vector), NO 3D, NO fotorrealista.
- Formas redondeadas, contorno grueso y limpio.
- Nada tenebroso de verdad, incluso en el bloque "Tensión" — referencia de tono: Candy Crush Saga, Ludo King.
- Que se note **rico visualmente, no simplón**: usar degradés suaves, sombras chicas debajo de los elementos, brillitos/destellos donde corresponda — no colores lisos sin ningún detalle.
- Fondo transparente en los recursos individuales (personajes, íconos de casilla).

---

## 3. Avatares — con animación

No alcanza con una imagen fija parada. Necesito, por cada uno de los 6 personajes base:

- **Ciclo de caminata** (varios cuadros/frames: al menos 4 poses — pie izquierdo adelante, medio, pie derecho adelante, medio — para animar el paso por el tablero).
- **Animación de festejo/salto al ganar** (2-3 cuadros: agachado, en el aire con brazos arriba, aterrizaje) — se dispara cuando el jugador gana una etapa o partida.
- **Animación de reacción al fallar** (1-2 cuadros: cara de sorpresa/susto leve, nunca de sufrimiento real) — se dispara al fallar Cuestionados en una casilla de trampa.

Mismo prompt base que antes para el diseño del personaje (aire a Roblox pero plano, ojos grandes, contorno grueso), pero ahora pedido como **secuencia de poses**, no una sola imagen.

---

## 4. Casillas de trampa — más grandes y animadas

Las casillas de trampa (oca, puente, cárcel, calavera, minijuego) tienen que verse **más grandes que las casillas normales** (sobresalir un poco del cuadrado de la casilla, como si "flotaran" encima del tablero) y tener una **animación de reposo** (idle, en loop mientras nadie la toca) para que el tablero se sienta vivo:

| Casilla | Animación de reposo sugerida |
|---|---|
| 🪿 Oca | Aletea suavemente y ladea la cabeza cada tanto |
| 🌉 Puente | Se balancea levemente, como con viento |
| ⛓️ Cárcel | Las rejas vibran/tintinean cada tanto |
| 💀 Calavera/fantasma | Flota arriba/abajo suavemente |
| 🎮 Minijuego (cofre) | Se abre y cierra un poquito, con brillitos parpadeando |

---

## 5. Animaciones de eventos en pantalla (feedback visual)

Cuando pasa algo importante, tiene que notarse en toda la pantalla, no solo en el ícono puntual:

- **Respuesta correcta en Cuestionados**: destello de estrellas/brillos alrededor de la pregunta.
- **Respuesta incorrecta**: sacudida de pantalla breve + destello rojo (esto ya lo teníamos en el prototipo HTML, hay que llevarlo a Flutter).
- **Ganar una etapa/partida**: confeti cayendo + el avatar hace su animación de salto/festejo.
- **Ganar monedas**: las monedas "vuelan" hacia el contador de arriba con un efecto de brillo, y el número sube animado (no salta directo al valor final).
- **Caer en una trampa**: pequeño efecto de impacto (ondas/sacudida) en el momento del aterrizaje, antes de la animación de sufrimiento del avatar.

---

## 6. Nota técnica para la implementación en Flutter

Generar imágenes estáticas para cada pose/frame es el primer paso, pero **la animación en sí se arma en Flutter**, no en la herramienta de generación de imágenes (que normalmente solo genera imágenes fijas, no anima). Opciones recomendadas para implementarlo:

- **Rive** (`rive.app`): permite armar animaciones vectoriales livianas con estados (caminar, saltar, reposo) controlables desde el código — es lo más recomendable para los avatares y casillas animadas.
- **Lottie**: alternativa si se consigue o exporta una animación ya hecha en ese formato.
- **Sprite sheet + `AnimationController`**: si no se usa Rive/Lottie, se pueden generar varias imágenes fijas (los frames de arriba) y Flutter las alterna en secuencia — más simple pero menos fluido.

Decisión sugerida: usar **Rive** para avatares y casillas de trampa (necesitan loop de reposo + transiciones), y efectos simples de partículas en código Flutter directo (confeti, brillos, monedas) sin necesidad de asset gráfico especial.

---

## 7. Qué NO hacer

- No usar una sola paleta de colores para todo el juego — tiene que cambiar por bloque de etapas como se especifica en la sección 1.
- No rediseñar la forma de los personajes o de los íconos de casilla entre bloques — solo cambia el entorno/fondo.
- No dejar los eventos importantes (ganar, fallar, monedas) sin ningún feedback visual en pantalla.
- No hacer que las casillas de trampa se vean del mismo tamaño que las casillas normales.
- No usar tonos oscuros/tétricos incluso en el bloque "Tensión".
- Si la herramienta de generación de imágenes no puede producir animación, avisar y proponer generar los frames/poses fijos por separado para animarlos después en Flutter — no reemplazar la animación por una imagen fija sin avisar.

---

## 8. Estado de implementación (Flutter)

- ✅ Paletas por bloque (sección 1): `lib/theme/paleta_bloque.dart`, aplicadas en `board_screen.dart` (fondo con gradiente + AppBar).
- ✅ Casillas de trampa más grandes y animadas (sección 4): `lib/widgets/board/casilla_trampa_animada.dart`.
- ✅ Efectos de feedback (sección 5, salvo la parte de avatar): `lib/widgets/effects/` — destello de estrellas, sacudida+rojo, confeti, monedas flotantes.
- ✅ Avatares animados (sección 3): el usuario generó el arte externamente y se integró en `assets/avatars/` — ciclo de caminata (4 frames), festejo (3 frames) y reacción al fallar (2 frames), para 4 combinaciones silueta+color: `masculino_azul`, `masculino_verde`, `androgino_azul`, `femenino_azul` (`lib/game/avatares/avatar_sprites.dart`). Se usan en la ficha del tablero (`tablero_widget.dart`, con animación de caminata real paso a paso), en el festejo al ganar etapa y en la reacción al fallar Cuestionados en una trampa (`board_screen.dart` + `lib/widgets/effects/ciclo_sprite_overlay.dart`). El bot usa un color fijo (no tiene personalización propia todavía).
- ✅ Íconos reales de casillas de trampa: `icono_puente/carcel/minijuego` (`assets/casillas/`) reemplazan los emojis, y la oca y la calavera tienen animación propia de varios frames (`ciclo_icono_animado.dart`) en vez de emoji+transform genérico.
- ✅ Ícono de la app actualizado en Android/iOS/web y en el prototipo HTML (`assets/branding/icono_app_ocaland.png`, recortado del arte generado).
- ✅ **Estilo confirmado por el usuario**: el look "cristal/gema brillante" de las casillas de trampa es intencional (es el estilo Candy Crush que se pidió), no un error — se mantiene tal cual. La calavera se reemplazó por una versión más amigable (ojos de gema celeste en vez de rojos, 3 frames de mandíbula moviéndose) que el usuario proveyó específicamente para resolver el choque con la sección 7 ("nunca oscuro/tétrico").
- ✅ **Tablero como camino serpenteante**: a pedido explícito, el tablero dejó de ser una grilla y pasó a un camino curvo (`lib/game/camino_tablero.dart` + `tablero_widget.dart`), que además varía de forma en cada etapa (no siempre la misma curva), igual que el layout de trampas.
- **Corrección acordada en el chat**: la sección 3 habla de "6 personajes base" fijos; se decidió en cambio un catálogo abierto y creciente de siluetas (no un número fijo), para que muchos jugadores puedan tener looks distintos. Ver sección 9.
- ✅ **Dado, ruleta de premio y minijuegos con arte real**: el usuario proveyó arte de dado (caras estáticas + frames de motion-blur), disco de ruleta y gemas/orbe para minijuegos, generados "para Candy Crush" en el mismo estilo. Integrado en `lib/widgets/board/dado_widget.dart`, `lib/widgets/ruleta/ruleta_widget.dart` y los minijuegos de Memoria/Reflejos. La ruleta reparte comodines reales (ver sección 9.1) en vez de ser solo decorativa.
- ✅ **Paisaje del tablero con arte real**: el usuario compartió dos referencias de estilo (un mockup "Ocaland: The Goose Adventure" con camino de tierra y fichas numeradas de madera, y un mapa pintado de montaña) — la dirección elegida fue el estilo plano vector consistente con el resto del arte, no el pintado/semi-realista. Se integró arte real de árboles, arbustos, flores, rocas, nubes, sol y un puente que cruza agua real en cada casilla de trampolín (`lib/widgets/board/fondo_candy.dart`, `assets/paisaje/`).
- ✅ **Casillas espaciadas + trampa sin disco de fondo**: el usuario marcó que las casillas quedaban "pegadas/superpuestas" y que "la trampa es la casilla" (no un ícono metido en un círculo genérico). Se resolvió con un tablero desplazable (más alto que la pantalla, con auto-scroll a la ficha activa) y casillas de trampa mostrando su arte a tamaño completo sin disco de fondo (`tablero_widget.dart`).
- ✅ **"Puente" renombrado a "trampolín"**: el usuario notó que la mecánica real (lanzar +2/+4 casillas) se parece a un trampolín, no a un cruce — se renombró en todo el código de juego (`TipoCasilla.trampolin`, `InfoTrampolin`), sin tocar la columna de Supabase (`layout_puentes`, fuera de alcance) ni el nombre de la etapa 7 ("El Puente Colgante", que es lore, no la mecánica).

## 9. Personalización de avatar (acordado en el chat, no estaba en la v2 original)

Sistema de personalización combinable, pensado para que entre mucha gente y cada uno se vea distinto sin depender de un catálogo enorme de arte:

- **Siluetas**: catálogo abierto de personajes base (no 6 fijos), algunos gratis desde el arranque, otros desbloqueables con monedas. Se pueden seguir agregando con el tiempo. Hoy: `silueta_masculino`, `silueta_androgino`, `silueta_femenino` (las 3 gratis).
- **Color**: resultó ser, en la práctica, una variante de **arte completo** por silueta (no un tinte universal aplicable a cualquier personaje) — cada combinación silueta+color tiene su propio set de caminata/festejo/reacción. Por eso cada color queda "scoped" a una silueta puntual (columna `silueta_id`). Hoy: `masculino_azul` (gratis), `masculino_verde` (30 monedas), `androgino_azul` (gratis), `femenino_azul` (gratis).
- **Accesorio**: capa adicional (gorro, anteojos, bufanda, corona), todavía sin arte real — se muestra con un ícono de Material Design como placeholder.
- **Implementado**: tabla `la_vuelta.personalizacion_catalogo` (con `silueta_id` para los colores), columna `usuarios.personalizacion` (jsonb: equipado + desbloqueados), funciones `SECURITY DEFINER` `inicializar_personalizacion`, `comprar_item_personalizacion` y `equipar_personalizacion` (precio y pertenencia silueta↔color validados siempre del lado del servidor — nunca se confía en el cliente). Pantalla `lib/screens/mi_avatar_screen.dart` con grilla de compra/equipar, mostrando el arte real cuando existe. Todo probado en vivo contra la base real, incluidos los casos de error.
- **Pendiente**: arte de accesorios, más siluetas/colores, y que el bot use su propia personalización (hoy usa un color fijo).

## 9.1 Ruleta de premio entre etapas

Al ganar una etapa (y no ser la última), antes de arrancar la siguiente se
muestra una ruleta de 6 gajos (`assets/ruleta/disco.png`, arte real del
usuario). El comodín se guarda en `CampanaSoloController.comodinPendiente`
y se consume la próxima vez que corresponda:

| Gajo | Comodín | Efecto |
|---|---|---|
| Rojo | `+3 casillas` | Se aplica de entrada al arrancar la nueva etapa (`iniciarEtapa`). |
| Azul | Inmunidad | Perdona el próximo fallo en Cuestionados del jugador (una sola vez). |
| Verde | Tirada extra | Al pasar el turno, si está pendiente, el jugador vuelve a tirar en vez de pasarle el turno al bot. |
| Violeta | Doble tiempo | Duplica el timer de la próxima pregunta de Cuestionados. |
| Amarillo / Rosa | Sin premio | No hace nada — son los 2 gajos "vacíos" de la ruleta. |

El disco no divide el círculo en 6 partes exactamente iguales, así que el
ángulo de parada de cada gajo se midió empíricamente (centro de color real
en grados) en vez de asumir 60° parejos — ver el comentario en
`RuletaWidget.centrosGrados`.

---

*Este documento reemplaza la versión anterior (Ocaland-Estilo-Visual-Prompt.md). Es el criterio de aceptación visual actualizado para Ocaland.*
