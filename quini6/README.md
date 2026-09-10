# Quini 6 — Sistema de análisis estadístico

Investigación estadística sobre los sorteos del Quini 6 (Argentina). **No es un sistema para
garantizar premios**: el hallazgo validado con walk-forward honesto (2308 evaluaciones sobre 2508
sorteos reales, sorteos 900-3407) es que la cobertura de los pools es estadísticamente
indistinguible del azar puro (Pool-16 ≈ 34.7% vs azar 34.8%, Pool-20 ≈ 43.4% vs azar 43.5%). El
valor del proyecto es la reproducibilidad del análisis y el seguimiento honesto de qué modelos
rinden mejor — no una ventaja predictiva real garantizada.

## Setup

```bash
pip install -r requirements.txt
```

## Uso rápido (app web)

```bash
python main.py --build-dataset   # una vez, para generar data/dataset.txt
python webapp.py                 # abrí http://localhost:8000
```

La app muestra el último sorteo cargado, un formulario para cargar el resultado del siguiente y,
al enviarlo: evalúa automáticamente la proyección que había quedado guardada para ese sorteo
(aciertos por modelo), guarda el resultado en el dataset, y genera la proyección del próximo
sorteo — por sección (Tradicional / La Segunda / Revancha / Siempre Sale) y Extra Pool — con los
modelos ordenados por su acierto histórico real (no por promesas).

## Uso por CLI

```bash
# 1. Construir el dataset
python main.py --build-dataset [--pdf ruta/al/historico.pdf]

# 2. (Recomendado, una sola vez) sembrar el historial de aciertos de cada modelo
#    corriendo walk-forward modelo por modelo sobre todo el dataset
python main.py --backtest-models --ventana 200

# 3. Procesar un sorteo nuevo: evalúa la proyección pendiente para ese sorteo (si existía),
#    guarda el resultado y genera + guarda la proyección del siguiente
python main.py --sorteo 3408 --dia D \
  --t 00-08-20-23-24-32 --s 03-16-22-34-41-45 \
  --r 09-19-29-36-40-43 --ss 06-11-18-27-33-38

# Sistema alternativo (ensemble ML: DECAY/LOGIT/KNN/FFT + señales, boletos y CB)
python main.py --sistema v4 --sorteo 3408 --dia D --t ... --s ... --r ... --ss ...

# Validación agregada de los pools (sin trackear modelo por modelo)
python main.py --walkforward --ventana 200
```

`--dia` es opcional: se calcula solo a partir del número de sorteo (D=Domingo, X=Miércoles,
ancla: sorteo 3276 = domingo 08/06/2025).

## Cómo funciona el seguimiento de modelos

Cada vez que se genera una proyección para el sorteo N+1 (por CLI o por la webapp), se guarda en
`tracking/pending.json`. Cuando después cargás el resultado real del sorteo N+1, el sistema busca
esa proyección pendiente, cuenta los aciertos de cada modelo (por sección y en el extra pool), y
actualiza `tracking/model_stats.json` (promedio de aciertos, máximo, cuántas veces acertó 4+). Los
reportes siguientes ordenan los modelos de cada sección por ese promedio histórico, así los que
"venimos acertando" quedan arriba. `--backtest-models` hace lo mismo pero hacia atrás, sobre todo
el dataset, para no arrancar de cero.

## Sistemas

- **Unificado** (default — `engine.py`, `models/`, `models/section_predict.py`): pool-16/20/C +
  ~24 modelos heurísticos de extra pool (v1) + modelos propios por sección (Tradicional, La
  Segunda, Revancha, Siempre Sale: Grupo A = top 6, Grupo B = candidatos 7-12, por frecuencia +
  co-ocurrencia con el sorteo anterior + señal cruzada de las otras secciones + ausencia + calor
  reciente) + tracking de aciertos históricos por modelo.
- **v4** (`models_v4/`): ensemble de 5 modelos (co-ocurrencia con decaimiento exponencial,
  regresión logística, KNN por similitud Jaccard, ciclo dominante vía FFT, ausencia) + boosts por
  señales triple/doble y migración entre secciones + generación de boletos y combinaciones (CB).
  No tiene tracking de modelos individuales todavía.
- **v1-legacy** (`--sistema v1-legacy`): el reporte original de extra pool sin sección ni tracking.

Todos comparten el mismo `data/loader.py` y el mismo `dataset.txt`.

## Datos

- `data/sources/quini6_full_900_3407.txt`: **2508 sorteos reales** (900–3407), la franja completa
  del Quini 6 con las 4 secciones (Tradicional, La Segunda, Revancha, Siempre Sale) en el rango
  00-45 actual. Reconstruido a partir de:
  - `Quini6_Historico_Completo_Sorteo1_al_3398.xlsx` (histórico oficial completo, sorteos 900-3398,
    números exactos — pero el día D/X viene como placeholder genérico "Mié/Dom" para casi todo el
    tramo, no verificado por sorteo).
  - `Quini6_Resultados_Completos_3012_3275.xlsx`, `QUINI6_BASE_DATOS.txt`,
    `QUINI6_DATOS_historicos.docx` y los sorteos verificados a mano (3012-3407, con fecha y día
    reales).
  - `data/sources/quini6_real_3012_3407.txt` es el subconjunto con día **verificado** (no
    estimado) — usalo si necesitás descartar la incertidumbre de día en el tramo 900-3011.
    `DIA_VERIFICADO_DESDE = 3012` en `data/loader.py`. `--backtest-models --solo-dia-verificado`
    evalúa solo esa franja verificada.
  - Antes del sorteo 900 el juego no tenía Siempre Sale completo (y antes de ~450 tampoco La
    Segunda, con rango de bolillas distinto: 01-30 hasta 1994, 01-42 hasta 1998) — esos sorteos
    más viejos no son compatibles con los modelos actuales (pensados para 00-45 con las 4
    secciones) y no se importaron.

## Google Drive (opcional)

`--upload` sube el reporte generado a la carpeta de Drive del proyecto. Requiere `credentials.json`
(Service Account con acceso a Drive) — ver `drive/uploader.py`.
