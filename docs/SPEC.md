# Ocaland — Especificación completa para migración a Flutter

Documento de referencia con todo lo diseñado y construido en el prototipo HTML/Supabase, para usar como base al reconstruir el juego en Flutter (vía Claude Code).

---

## 1. Visión del proyecto

Ocaland es una versión moderna del juego de la oca: tablero con casillas especiales + trivia ("Cuestionados") + minijuegos + progresión de campaña, con multijugador en tiempo real. Nace como "La Vuelta", se renombra a **Ocaland**. Objetivo final: publicarlo en Google Play Store.

**Diferenciador de mercado** (confirmado con investigación real): las apps de "oca" existentes son básicas y mal valoradas (reseñas se quejan de aburrimiento, mala UI, publicidad invasiva). Ninguna combina oca + trivia + progresión + multijugador moderno. Ocaland sí.

**Prototipo actual**: un único archivo HTML (`la-vuelta-multijugador-test.html`), vanilla JS, sin build ni frameworks, con Supabase como backend (Postgres + Realtime + Edge Functions vía pg_net). Cerca de 3000 líneas.

---

## 2. Stack

**Prototipo (HTML)**: HTML + CSS + JS vanilla en un solo archivo. Supabase (`ejobycpstnbzkjnlebrd`, schema `la_vuelta`, compartido con otras apps de Pablo como Charla). Vercel para deploy. OneSignal para push notifications vía trigger de Postgres + pg_net.

**Destino (Flutter)**: mismo backend de Supabase (reutilizar todo el schema `la_vuelta`), reescribir el cliente en Flutter/Dart. El motor de juego (reglas, cálculos) puede portarse casi 1 a 1 ya que la lógica está bien separada en funciones.

---

## 3. Mecánica del tablero

- 30 casillas en espiral, casilla 0 = salida, casilla 29 = meta.
- **El layout de casillas especiales es aleatorio y cambia en cada partida/etapa nueva** (no fijo), sincronizado entre todos los jugadores vía DB (columnas `layout_casillas` y `layout_puentes` en jsonb).
- 20 de las 30 casillas son "trampa" (antes eran ~14, se aumentó a pedido): reparto por partida = 6 oca, 6 minijuego, 3 puente, 3 cárcel, 2 calavera.
- **Regla de rebote real de la oca**: si el dado te pasa de la meta, rebotás hacia atrás la diferencia (`nuevaPos = 2*META - pos - dado`).
- Tipos de casilla:
  - 🪿 **Oca**: Cuestionados; acierto = tirás de nuevo; fallo = te quedás.
  - 🌉 **Puente**: avance directo garantizado de +2 a +4 casillas (sin trivia).
  - ⛓️ **Cárcel**: Cuestionados; acierto = a salvo; fallo = perdés el próximo turno.
  - 💀 **Calavera**: Cuestionados DIFÍCIL; acierto = te quedás; fallo = volvés a la casilla 0 (con animación de caminata de regreso).
  - 🎮 **Minijuego**: reflejos o memoria; éxito = +2 casillas extra; fallo = nada (con publicidad simulada opcional).
  - 🏆 **Meta**: gana quien llega.

**Animación de movimiento**: la ficha camina casilla por casilla (no salta instantáneo), con sonido de "tick" por paso. Mientras camina, un refresco automático (polling cada 3s) NO debe reconstruir los tokens (usar flag `caminataEnCurso`) para no interrumpir la animación — esto causó un bug real que se corrigió.

**Animaciones de "sufrimiento"**: al fallar calavera o cárcel, la ficha se sacude y destella en rojo (CSS keyframes), y mientras está presa en la cárcel muestra un ícono de cadenas ⛓️ persistente y un filtro grisáceo, visible también en un panel de estado de todos los jugadores arriba del tablero.

---

## 4. Cuestionados (trivia)

- Renombrado de "Trivia" a **"Cuestionados"** en toda la interfaz.
- Bancos de preguntas segmentados por:
  - **Edad**: niños (7-12), adolescentes (13-17), jóvenes (18-25), adultos (26-45), adultos_plus (46-59), mayores (60+). Los brackets sin banco propio (jóvenes, adultos_plus) heredan el de "adultos" automáticamente.
  - **País**: Argentina, Chile, Otro/Internacional — cada uno con preguntas de cultura general + preguntas locales específicas (historia, geografía, personajes). Se elige en una pantalla nueva después de la edad.
  - Banco "difícil" separado (para calavera y, desde la etapa 7 en la campaña, también oca/cárcel) — este no está segmentado por país todavía.
- **Limitación conocida**: el banco es chico (armado a mano), las preguntas se repiten en partidas largas. **Pendiente para Flutter**: banco mucho más grande o generado dinámicamente.
- Mecánicas alrededor de la trivia:
  - Timer visual, con cuenta regresiva.
  - Los espectadores (otros jugadores esperando su turno) ven la misma pregunta en un recuadro punteado, sin opciones ni respuesta, "para pensarla también".
  - **Reintentar trivia fallada**: al fallar, se ofrece "Mirar video (gratis) o gastar 15 monedas" para responder una pregunta nueva antes de aplicar la penitencia.
  - **Pedir pista** (10 monedas o video): elimina una opción incorrecta.
  - **Comodín de doble tiempo**: si el jugador lo tiene pendiente (ganado en la ruleta), la próxima Cuestionados le da el doble de segundos.
  - **Comodín de inmunidad**: si el jugador lo tiene pendiente, la próxima vez que falle oca/cárcel/calavera, el fallo se convierte en acierto automáticamente.

---

## 5. Minijuegos

- **Reflejos**: esperar a que un botón se ponga verde y tocarlo rápido (menos de 1 segundo de ventana). Falla si tocás antes de tiempo O si tardás demasiado tras ponerse verde (antes solo fallaba por tocar antes de tiempo, se corrigió para que también haya forma de perder por lento).
- **Memoria**: se iluminan 3 fichas de colores en secuencia, hay que repetirla tocando en el mismo orden.
- Se elige al azar cuál de los dos se muestra.
- Aparecen en: la casilla de tipo "minijuego" del tablero, y en la transición entre etapas de la campaña (mini-juego + ruleta de premio).
- Cada uno debería tener nombre propio para diferenciarlos mejor (pendiente menor de pulido).

---

## 6. Modos de juego

### 6.1 Solo (campaña de 10 etapas contra un bot)
- 10 etapas con dificultad creciente (`generarConfigEtapa`): el bot acierta más Cuestionados a medida que avanza la etapa, el tiempo de respuesta baja de 15s a 8s, desde la etapa 7 hasta oca/cárcel usan el banco difícil.
- Cada etapa tiene **nombre propio y una leyenda de lore** (opcional de leer, con botón "Leer" / "✕" para descartar): El Nido Inicial, El Estanque Sereno, El Bosque de las Dudas, La Colina Ventosa, El Valle de los Espejismos, La Cueva Oscura, El Puente Colgante, La Montaña Helada, El Desfiladero Final, La Cima de Ocaland.
- Al perder una etapa: elección entre **"🔁 Reintentar"** o **"🎯 Responder 3 Cuestionados nuevos para pasar igual"** (si fallás alguna de las 3, caés en reintentar).
- Se cuenta el número de reintentos por etapa, visible en el marcador.
- Al completar toda la campaña: guarda historial local (últimas 20 corridas), muestra tiempo total, registra estadística permanente y monedas.

### 6.2 Multijugador — Sala normal ("tanda")
- Serie de mejor-de-3: quien gane 2 partidas seguidas gana la tanda antes; si sigue 1-1 tras 3, se juega una 4ta; si sigue empatado, desempate directo por Cuestionados eliminando de a uno.
- Reconexión: si alguien cierra la app en medio de una partida, puede volver a entrar con el código y elegir su nombre de la lista para retomar exactamente donde estaba.
- Botones de "Revancha" (misma sala) y "Nueva tanda" (resetea todo) arrancan **directo**, sin volver a pasar por la sala de espera ni re-clickear "Iniciar partida" (esto generaba fricción, se corrigió).

### 6.3 Multijugador — Campaña grupal en vivo
- Todos juegan en el mismo tablero al mismo tiempo, pero cada ronda es una etapa distinta (1 a 10) con la misma dificultad creciente que la campaña solo. Se corona quien ganó más etapas (o gana 2 seguidas).
- **Bug corregido durante el desarrollo**: la ruleta de comodines nunca se disparaba en este modo (solo en solo). Se corrigió para que el ganador de cada etapa tire el mini-juego + ruleta de forma cosmética (no bloquea a los demás), y el comodín se aplique correctamente al jugador ganador (no asumir que es "uno mismo": esto requirió sincronizar el estado de comodín vía base de datos en vez de una variable local del navegador, porque cada jugador está en un dispositivo distinto).

### 6.4 Desafío grupal (campañas individuales comparadas)
- Cada persona juega su propia campaña de 10 etapas cuando quiera (no hace falta estar todos conectados a la vez), pero atada a un código de desafío compartido.
- Al completar la campaña, el resultado (etapas completadas + tiempo total) se guarda y se compara en un ranking del desafío.

### 6.5 Pendiente: Matchmaking con desconocidos ("modo 3")
- **No implementado.** La idea es un "Buscar partida pública" que empareja gente que no se conoce entre sí, sin necesidad de compartir código, filtrando por nivel/edad.
- **Decisión explícita: se deja para la etapa de Flutter**, porque depende de tener cuentas de usuario reales (no identidad por dispositivo) para que el emparejamiento y el ranking tengan sentido, y porque no depende de nada de lo ya construido — se puede agregar en cualquier momento sin tocar el resto.

---

## 7. Sorteo de turno y plazos

- **Sorteo con dados, visible para todos**: al arrancar cualquier ronda, cada jugador "tira un dado" (valor 1-6, empates vuelven a tirar solo entre los empatados), se muestra en un panel a todos los dispositivos con corona 👑 al ganador. Reemplazó una versión anterior (animación de nombres pasando) que no se sentía divertida.
- **Turnos con plazo de 6 horas**: cada turno tiene un vencimiento (`turno_vence_ts`); si nadie juega a tiempo, se salta automáticamente al siguiente jugador. Esto permite jugar sin que todos estén conectados al mismo tiempo.
- El plazo y el sorteo no aplican en modo solo (no tiene sentido con un bot).

---

## 8. Identidad y progresión

- **Identidad persistente por dispositivo** (sin autenticación real todavía): se genera un `usuario_id` guardado en `localStorage`, vinculado a una fila en la tabla `usuarios`. Al volver a abrir la app, se reconoce automáticamente ("¡Hola de nuevo, Pablo!") sin pedir el nombre de nuevo.
- **Perfil** (pantalla "Mi perfil"): monedas, racha de días, partidas jugadas/ganadas, campañas completadas, mejor tiempo de campaña, multiplicador activo (si tiene), amigos invitados, código propio de referido.
- **Ranking global**: top 20 por partidas ganadas, con medallas para los primeros 3, resaltando al propio usuario.
- **Multi-partidas simultáneas**: un jugador puede estar en varias salas/campañas a la vez (antes el sistema solo soportaba una sesión activa). Pantalla "Mis partidas" lista todas las activas; si hay 2 o más al recargar la página, se muestra un selector en vez de auto-entrar a una.

---

## 9. Economía de monedas

- **Ganar monedas**:
  - +5 por ganar una partida/etapa, +2 por jugarla igual si se pierde.
  - +50 al completar toda la campaña de 10 etapas.
  - Recompensa diaria por volver (racha): día 1 = 10, escala +5 por día hasta el día 7 (40), y vuelve a empezar el ciclo.
  - +15 por compartir la app (una vez por día).
  - +5 a los 5, 15 y 30 minutos de actividad continua en la app (un heartbeat cada 60s revisa esto).
  - +20 al usuario que invitó, cuando alguien nuevo entra usando su código de referido.
- **Multiplicador de monedas**: ruleta de bonus aparte (una vez por día) que puede dar x1.5, x2 o x3 por un tiempo limitado (15 a 60 minutos). El multiplicador se aplica automáticamente a **todas** las formas de ganar monedas de arriba (calculado del lado del servidor, no confía en el cliente).
- **Gastar monedas** (o ver un "video" simulado, gratis):
  - 15 monedas: reintentar una Cuestionados fallada.
  - 10 monedas: pedir una pista (elimina una opción incorrecta).
  - 10 monedas: girar la ruleta de premio una vez más.
  - 15 monedas: saltar el mini-juego de transición entre etapas.
  - Duplicar el premio diario de monedas (solo viendo un "video", no cuesta monedas).
- **Ruleta de premio entre etapas** (solo campaña y campaña grupal): da un "comodín" real (no solo texto decorativo, se corrigió):
  - +3 casillas de ventaja al arrancar la próxima etapa.
  - Inmunidad a la próxima trampa fallada.
  - Tirada extra al empezar la próxima etapa.
  - Doble tiempo en la próxima Cuestionados.
  - "Nada esta vez" (dos de los seis segmentos).

**Nota de diseño para publicidad real (AdMob) en Flutter**: la lógica de "elegí video o monedas" ya está armada y probada con un video simulado; en Flutter solo hay que reemplazar la simulación por un rewarded ad real de AdMob, sin tocar el resto de la lógica. Ubicaciones sugeridas: rewarded (todos los puntos de arriba) + interstitial limitado (al volver al menú tras terminar una tanda/campaña) + banner chico (solo en pantallas de espera/perfil/ranking, nunca durante el tablero activo).

---

## 10. Notificaciones push (OneSignal)

- App de OneSignal creada: **App ID `e435e540-70fa-4435-aecc-d84efc1f81cb`**.
- REST API Key guardada de forma segura en el **Vault de Supabase** (secreto `onesignal_rest_api_key_ocaland`), nunca expuesta en el cliente.
- Disparo **automático server-side**: un trigger de Postgres (`notificar_turno`) se ejecuta cada vez que cambia `turno_actual` en la tabla `partidas`, busca el `onesignal_player_id` del jugador correspondiente (vinculado en `usuarios.onesignal_player_id`) y llama a la API de OneSignal vía `pg_net` — sin necesitar un servidor propio corriendo.
- El mensaje incluye el código de sala, para diferenciar cuando alguien tiene varias partidas activas.
- Cliente: SDK Web de OneSignal integrado, captura el `PushSubscription.id` del navegador y lo guarda vinculado al usuario.
- **Pendiente**: subir el archivo del Service Worker (`OneSignalSDKWorker.js`) a la raíz del sitio en producción (paso manual de Pablo, no de código).

---

## 11. Seguridad

- **Protegido**: la tabla `usuarios` (perfil, monedas, estadísticas, comodines) no permite `UPDATE` ni `DELETE` directo desde el cliente. Todos los cambios pasan por funciones `SECURITY DEFINER` en Postgres (RPC) que validan y calculan del lado del servidor — así nadie puede escribirse victorias o monedas falsas directamente vía la clave pública.
- **Sin proteger todavía** (limitación conocida y aceptada para esta etapa de prototipo): las tablas `partidas`, `jugadores_partida`, `desafios_grupales` y `desafios_resultados` siguen totalmente abiertas (cualquiera con la clave anon podría editar el estado de cualquier sala). Es un riesgo aceptable mientras se juega con gente conocida vía código compartido, pero **debe cerrarse antes de cualquier lanzamiento público real**.
- **Cierre completo pendiente para Flutter**: mover todo el motor de juego (resolución de tiradas, turnos, trivia) a funciones del servidor en vez de que el cliente escriba el resultado directamente. Es un cambio de arquitectura grande, no cosmético.

---

## 12. Sonido

Todo generado por código (Web Audio API, osciladores), sin archivos de audio externos — portable directamente a Flutter con paquetes como `audioplayers` o generando tonos nativos si se prefiere mantener el enfoque sin assets.

Eventos con sonido: tirar el dado, tick por paso de caminata, acierto/error en Cuestionados, sufrimiento (calavera/cárcel fallada), victoria (fanfarria, doble en campaña completa), monedas ganadas, sorteo de turno.

---

## 13. Identidad visual

- **Paleta "Candy Crush"** vibrante (reemplazó una paleta verde bosque/beige apagada): violeta `#7C4DFF`, fucsia `#FF4D8D`, amarillo `#FFC93C`, turquesa `#4FD8E0`, celeste `#29B6F6`, verde `#43D67D`.
- Ícono: círculo dorado con "OL" sobre violeta.
- **Pendiente para Flutter**: avatares de jugador personalizables y animados caminando por el tablero (hoy son círculos de color con la inicial del nombre).

---

## 14. Esquema de base de datos (schema `la_vuelta`, proyecto Supabase `ejobycpstnbzkjnlebrd`)

### Tablas

**`partidas`**: id, codigo, estado (`esperando`/`en_curso`/`finalizada`/`desempate`), modo (`tanda`/`campana_grupal`), max_jugadores, turno_actual, estado_turno, ronda_actual, etapa_actual, ultimo_ganador_id, racha_ganador, ganador_tanda_id, desempate_pendientes[], desempate_turno_idx, sorteo_tiradas (jsonb), layout_casillas (jsonb), layout_puentes (jsonb), trivia_pregunta_actual, turno_vence_ts, created_at.

**`jugadores_partida`**: id, partida_id, usuario_id (fk a usuarios), nombre, es_bot, posicion, orden_turno, edad_bracket, pais, salta_turno, victorias, comodin_pendiente.

**`usuarios`**: id, nombre, creado_en, ultima_conexion, racha_dias, partidas_jugadas, partidas_ganadas, campanas_completadas, mejor_tiempo_campana_ms, onesignal_player_id, monedas, multiplicador_valor, multiplicador_vence_ts, ultima_ruleta_bonus, ultimo_share_app, minutos_activos_hoy, fecha_actividad, codigo_referido (único), referido_por (fk a sí misma), amigos_invitados.

**`desafios_grupales`**: id, codigo (único), creado_en.

**`desafios_resultados`**: id, desafio_id (fk), usuario_id, nombre, etapas_completadas, ms_total, completado_en.

### Funciones (RPC, todas `SECURITY DEFINER`)

- `registrar_resultado_partida(usuario_id, gano)` → aplica monedas (con multiplicador) + stats.
- `registrar_campana_completada(usuario_id, ms_total)` → +50 monedas (con multiplicador) + stats.
- `reclamar_recompensa_diaria(usuario_id)` → calcula racha y monedas del día server-side.
- `actualizar_onesignal_id(usuario_id, onesignal_id)`.
- `gastar_monedas(usuario_id, cantidad)` / `agregar_monedas(usuario_id, cantidad)`.
- `girar_ruleta_bonus(usuario_id)` → multiplicador aleatorio, una vez por día.
- `recompensa_por_compartir(usuario_id)` → una vez por día.
- `registrar_minuto_activo(usuario_id)` → hitos a los 5/15/30 min.
- `aplicar_codigo_referido(usuario_nuevo_id, codigo)`.
- `_aplicar_multiplicador(usuario_id, monedas_base)` → helper interno usado por todas las de arriba.
- `notificar_turno()` → trigger que dispara el push de OneSignal vía pg_net.

Todas las funciones de monedas fueron **probadas directamente contra la base real** (no solo simuladas), incluyendo la interacción del multiplicador con cada una.

---

## 15. Aprendizajes / bugs reales encontrados y corregidos durante el desarrollo

- La ficha "avanzaba y retrocedía" — causado por un refresco automático de respaldo (polling) que reconstruía los tokens en medio de la animación de caminata. Se corrigió con un flag `caminataEnCurso`.
- El sorteo de turno por nombres pasando no se sentía divertido — se reemplazó por un sorteo de dados real y visible para todos.
- Los premios de la ruleta eran solo texto decorativo, no hacían nada — se conectaron a efectos reales.
- El comodín de "tirada extra" se guardaba en una variable local del navegador en vez de la base de datos, lo que fallaba en multijugador real (cada jugador en un dispositivo distinto) — corregido para sincronizar vía DB.
- La ruleta de comodines nunca aparecía en el modo campaña grupal (solo en solo) — corregido.
- El menú principal creció a 11 botones apilados sin orden — reorganizado en pestañas (Jugar / Bonus / Cuenta).

---

## 16. Pendiente explícito para la etapa de Flutter

1. **Matchmaking con desconocidos** (modo 3) — depende de cuentas reales.
2. **Cerrar la seguridad completa del estado del juego** — mover el motor de resolución de turnos al servidor.
3. **Autenticación real** (Gmail u otro proveedor) en vez de identidad por dispositivo — resuelve varias limitaciones de seguridad y permite identidad entre dispositivos.
4. **Avatares personalizables** que caminen animados por el tablero.
5. **Publicidad real con AdMob** (reemplazando la simulación ya probada).
6. **Multi-idioma** (inglés, portugués, etc.), con la idea de asociarlo automáticamente al país elegido salvo que el jugador viva en otro país y prefiera elegir el suyo manualmente.
7. **Banco de Cuestionados mucho más grande**, o generado dinámicamente, para que no se sienta repetitivo.
8. Integrar de verdad el archivo del Service Worker de OneSignal en el hosting de producción.
9. Probar el conjunto completo con gente real jugando en simultáneo (las pruebas automatizadas cubrieron cada pieza por separado, no todas las combinaciones a la vez).

---

## 17. Créditos de acceso relevantes

- Proyecto Supabase: `ejobycpstnbzkjnlebrd`, schema `la_vuelta` (compartido con Charla, otra app de Pablo).
- OneSignal App "Ocaland": App ID `e435e540-70fa-4435-aecc-d84efc1f81cb`, bajo la organización "Pablo Morales" (misma que Charla).
- Deploy actual del prototipo: Vercel, mismo repo de GitHub que sirve `index.html`, `manifest.json`, `icon-192.png`, `icon-512.png`, `OneSignalSDKWorker.js`.

---

*Documento generado a partir de una sesión extensa de desarrollo del prototipo HTML de Ocaland. Sirve como base de referencia, no como reemplazo del código fuente — para el detalle exacto de implementación, ver `la-vuelta-multijugador-test.html`.*
