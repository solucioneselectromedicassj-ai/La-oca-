# Quini 6 — Sistema de análisis estadístico

Investigación estadística sobre los sorteos del Quini 6 (Argentina). **No es un sistema para
garantizar premios**: el hallazgo validado con walk-forward honesto (72 evaluaciones sobre 132
sorteos reales, y confirmado antes con 2395 sorteos en el histórico completo) es que la cobertura
de los pools es estadísticamente indistinguible del azar puro (Pool-16 ≈ 34% vs azar 34.8%,
Pool-20 ≈ 43% vs azar 43.5%). El valor del proyecto es la reproducibilidad del análisis, no una
ventaja predictiva real.

## Setup

```bash
pip install -r requirements.txt
```

## Uso

```bash
# 1. Construir el dataset (usa data/sources/quini6_real_3276_3407.txt, 132 sorteos reales
#    verificados; si le pasás --pdf además intenta parsear un PDF histórico más largo)
python main.py --build-dataset [--pdf ruta/al/historico.pdf]

# 2. Procesar un sorteo nuevo y generar la proyección del siguiente
python main.py --sorteo 3408 --dia D \
  --t 00-08-20-23-24-32 --s 03-16-22-34-41-45 \
  --r 09-19-29-36-40-43 --ss 06-11-18-27-33-38

# Sistema alternativo (ensemble DECAY/LOGIT/KNN/FFT + señales, boletos y CB)
python main.py --sistema v4 --sorteo 3408 --dia D --t ... --s ... --r ... --ss ...

# 3. Validar con walk-forward honesto (sin look-ahead)
python main.py --walkforward --ventana 60
```

`--dia` es opcional: se calcula solo a partir del número de sorteo (D=Domingo, X=Miércoles,
ancla: sorteo 3276 = domingo 08/06/2025).

## Sistemas

- **v1** (`models/`): pool-16/pool-20/pool-C + 34 modelos heurísticos (frecuencias, cruces por
  sección, ciclos, co-ocurrencia día a día, similitud por Siempre Sale) + scoring por consenso.
- **v4** (`models_v4/`): ensemble de 5 modelos (co-ocurrencia con decaimiento exponencial,
  regresión logística, KNN por similitud Jaccard, ciclo dominante vía FFT, ausencia) + boosts por
  señales triple/doble y migración entre secciones + generación de boletos y combinaciones (CB).

Ambos sistemas comparten el mismo `data/loader.py` y el mismo `dataset.txt`.

## Datos

- `data/sources/quini6_real_3276_3407.txt`: 132 sorteos reales (08/06/2025 – 10/09/2026),
  reconstruidos a partir de los documentos del Google Drive del proyecto (`QUINI6_BASE_DATOS.txt`,
  `QUINI6_DATOS historicos.docx`) y validados contra la fórmula de día D/X sin discrepancias.
- Existe además un histórico más largo (sorteos 1–3398, con secciones incompletas antes de que
  existieran Segunda/Revancha/Siempre Sale) como planilla en Drive
  (`Quini6_Historico_Completo_Sorteo1_al_3398`), no importado todavía por su tamaño — se puede
  traer como PDF/CSV y pasarlo con `--pdf` a `data/pdf_parser.py` (parser best-effort, calibrar
  con `--debug`).

## Google Drive (opcional)

`--upload` sube el reporte generado a la carpeta de Drive del proyecto. Requiere `credentials.json`
(Service Account con acceso a Drive) — ver `drive/uploader.py`.
