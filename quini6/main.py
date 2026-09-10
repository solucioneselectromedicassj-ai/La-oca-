import argparse
import os
import sys

from data.loader import (
    DATASET_PATH,
    DIA_VERIFICADO_DESDE,
    REAL_SOURCE_PATH,
    apply_verificados,
    calc_dia,
    load_dataset,
    make_sorteo,
    parse_nums,
    save_dataset,
)
import engine
from evaluation.metrics import summarize
from evaluation.walkforward import walkforward
from models import build_pool, build_pool_c, get_all_models
from models.scoring import score_pool
from reports.generator import generate_report
from reports.generator_unificado import generate_report as generate_report_unificado


def cmd_build_dataset(args):
    sorteos_by_n = {}
    if args.pdf and os.path.exists(args.pdf):
        from data.pdf_parser import parse_pdf

        print(f'Parseando PDF: {args.pdf}')
        sorteos_by_n = parse_pdf(args.pdf, debug=args.debug)
        print(f'{len(sorteos_by_n)} sorteos extraídos del PDF.')
    elif args.pdf:
        print(f'No se encontró el PDF en {args.pdf}.')

    real = {s['n']: s for s in load_dataset(REAL_SOURCE_PATH)}
    if real:
        print(f'Cargados {len(real)} sorteos verificados reales '
              f'({min(real)}-{max(real)}) desde {REAL_SOURCE_PATH}.')
        sorteos_by_n.update(real)
    else:
        print(f'No se encontró la fuente real en {REAL_SOURCE_PATH}.')

    if not args.pdf and not real:
        print('Se genera un dataset mínimo con los sorteos verificados (3393-3407).')

    sorteos_by_n = apply_verificados(sorteos_by_n)
    sorteos = sorted(sorteos_by_n.values(), key=lambda s: s['n'])
    if not sorteos:
        print('No hay datos para guardar.')
        return

    save_dataset(sorteos, args.out)
    print(f'Dataset guardado en {args.out}: {len(sorteos)} sorteos '
          f'({sorteos[0]["n"]}-{sorteos[-1]["n"]})')


def _validar_nums(args):
    try:
        trad, seg, rev, ss = (parse_nums(v) for v in (args.t, args.s, args.r, args.ss))
    except ValueError:
        print('Formato inválido: usá números de 2 cifras separados por guion, ej: 10-19-22-29-36-43')
        sys.exit(1)

    for nombre, nums in [('--t', trad), ('--s', seg), ('--r', rev), ('--ss', ss)]:
        if len(nums) != 6:
            print(f'{nombre} debe tener 6 números, recibí {len(nums)}: {nums}')
            sys.exit(1)
    return trad, seg, rev, ss


def _load_and_append_sorteo(args):
    sorteos = load_dataset(args.dataset)
    if not sorteos:
        print('Dataset vacío. Corré primero: python main.py --build-dataset')
        sys.exit(1)

    trad, seg, rev, ss = _validar_nums(args)
    dia = args.dia or calc_dia(args.sorteo)
    nuevo = make_sorteo(args.sorteo, dia, trad, seg, rev, ss)

    sorteos = [s for s in sorteos if s['n'] != nuevo['n']] + [nuevo]
    sorteos.sort(key=lambda s: s['n'])
    save_dataset(sorteos, args.dataset)
    return sorteos, nuevo


def cmd_sorteo_unificado(args):
    trad, seg, rev, ss = _validar_nums(args)
    result = engine.process_sorteo(args.dataset, args.sorteo, args.dia, trad, seg, rev, ss)
    report = generate_report_unificado(result)
    print(report)
    _guardar_reporte(args, result['target_n'], report, prefijo='QUINI6_PROY')


def _guardar_reporte(args, target_n, report, prefijo='QUINI6_PROY'):
    os.makedirs(args.reports_dir, exist_ok=True)
    out_path = os.path.join(args.reports_dir, f'{prefijo}_{target_n}.txt')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(report)
    print(f'\nReporte guardado en {out_path}')

    if args.upload:
        try:
            from drive.uploader import get_drive_service, upload_text_file

            service = get_drive_service(args.credentials)
            upload_text_file(service, f'{prefijo}_{target_n}', report)
            print('Reporte subido a Google Drive.')
        except Exception as e:
            print(f'No se pudo subir a Google Drive: {e}')


def cmd_sorteo(args):
    sorteos, _ = _load_and_append_sorteo(args)

    pool16 = build_pool(sorteos, 16)
    pool20 = build_pool(sorteos, 20)
    poolC = build_pool_c(sorteos, 16)
    models = get_all_models(sorteos, pool20, poolC)
    ranking = score_pool(sorteos, pool20, models)

    target_n = args.sorteo + 1
    report = generate_report(target_n, sorteos, models, ranking, pool16, pool20, poolC)
    print(report)
    _guardar_reporte(args, target_n, report)


def cmd_sorteo_v4(args):
    sorteos, nuevo = _load_and_append_sorteo(args)

    from models_v4 import predecir
    from models_v4.boletos import gen_boletos, gen_cb
    from models_v4.senales import calcular_señales
    from reports.generator_v4 import generate_report_v4

    triples, dobles = calcular_señales(nuevo)
    dia_siguiente = 'D' if nuevo['dia'] == 'X' else 'X'
    scores, pool18 = predecir(sorteos, dia_siguiente, triples, dobles)

    top15 = sorted(pool18, key=lambda n: -scores[n])[:15]
    boletos = gen_boletos(top15)
    cb = gen_cb(pool18, scores, triples + dobles, nuevo['trad'], nuevo['seg'])

    target_n = args.sorteo + 1
    report = generate_report_v4(target_n, dia_siguiente, triples, dobles, boletos, cb, pool18, scores)
    print(report)
    _guardar_reporte(args, target_n, report, prefijo='QUINI6_PROY_V4')


def cmd_walkforward(args):
    sorteos = load_dataset(args.dataset)
    if len(sorteos) <= args.ventana:
        print(f'Se necesitan más de {args.ventana} sorteos para walk-forward '
              f'(hay {len(sorteos)}).')
        sys.exit(1)

    results = walkforward(sorteos, ventana=args.ventana)
    s = summarize(results)
    print(f'Evaluaciones: {s["n"]}')
    print(f'Pool-16 accuracy promedio: {s["acc_p16"] * 100:.1f}%  (V4+: {s["v4_p16"] * 100:.1f}%)')
    print(f'Pool-20 accuracy promedio: {s["acc_p20"] * 100:.1f}%  (V4+: {s["v4_p20"] * 100:.1f}%)')


def cmd_backtest_models(args):
    from evaluation.backtest_models import backtest_and_seed

    sorteos = load_dataset(args.dataset)
    if len(sorteos) <= args.ventana:
        print(f'Se necesitan más de {args.ventana} sorteos para el backtest (hay {len(sorteos)}).')
        sys.exit(1)

    print(f'Corriendo backtest modelo por modelo sobre {len(sorteos) - args.ventana} sorteos '
          f'(esto puede tardar unos minutos)...')
    stats, n_evaluados = backtest_and_seed(sorteos, ventana=args.ventana,
                                            solo_dia_verificado=args.solo_dia_verificado)
    print(f'Listo: {n_evaluados} sorteos evaluados. tracking/model_stats.json actualizado.\n')

    for cat, modelos in stats.items():
        print(f'── {cat} ──')
        ranked = sorted(modelos.items(), key=lambda kv: -(kv[1]['sum_hits'] / kv[1]['n']))
        for nombre, m in ranked[:8]:
            prom = m['sum_hits'] / m['n']
            print(f'  {nombre:<10} prom={prom:.2f}  max={m["max_hits"]}  '
                  f'4+={m["veces_4mas"]}  n={m["n"]}')
        print()


def build_parser():
    p = argparse.ArgumentParser(description='Quini 6 - Sistema de análisis estadístico')
    p.add_argument('--dataset', default=DATASET_PATH, help='Ruta al dataset.txt')
    p.add_argument('--reports-dir', default=os.path.join(os.path.dirname(__file__), 'reports', 'output'),
                    help='Carpeta de salida de reportes')
    p.add_argument('--credentials', default='credentials.json', help='JSON de credenciales de Google Drive')

    p.add_argument('--build-dataset', action='store_true',
                    help='Construye dataset.txt a partir del PDF histórico')
    p.add_argument('--pdf', help='Ruta al PDF histórico (Quini6_Historico_Completo_Sorteo1_al_3398.pdf)')
    p.add_argument('--out', default=DATASET_PATH, help='Ruta de salida del dataset')
    p.add_argument('--debug', action='store_true',
                    help='Muestra el texto crudo extraído del PDF (para calibrar el parser)')

    p.add_argument('--sorteo', type=int, help='Número del sorteo a procesar')
    p.add_argument('--sistema', choices=['unificado', 'v4', 'v1-legacy'], default='unificado',
                    help='unificado (default): por sección (T/S/R/SS) + extra pool, ranking por '
                         'acierto histórico real. v4: ensemble DECAY/LOGIT/KNN/FFT + señales/boletos. '
                         'v1-legacy: solo extra pool, reporte original sin tracking')
    p.add_argument('--dia', choices=['D', 'X'],
                    help='Día del sorteo (D=Domingo, X=Miércoles). Si se omite se calcula automáticamente')
    p.add_argument('--t', help='Números de la Tradicional, ej: 10-19-22-29-36-43')
    p.add_argument('--s', help='Números de la Segunda')
    p.add_argument('--r', help='Números de la Revancha')
    p.add_argument('--ss', help='Números de Siempre Sale')
    p.add_argument('--upload', action='store_true', help='Subir el reporte a Google Drive')

    p.add_argument('--walkforward', action='store_true',
                    help='Corre la validación walk-forward sobre el dataset (accuracy de pools)')
    p.add_argument('--ventana', type=int, default=200,
                    help='Tamaño de la ventana de entrenamiento para walk-forward/backtest')

    p.add_argument('--backtest-models', action='store_true',
                    help='Siembra tracking/model_stats.json corriendo walk-forward modelo por '
                         'modelo (T/S/R/SS + extra) sobre todo el histórico')
    p.add_argument('--solo-dia-verificado', action='store_true',
                    help=f'Con --backtest-models: evalúa solo sorteos >= {DIA_VERIFICADO_DESDE} '
                         '(día D/X verificado; excluye la franja con día estimado)')
    return p


def main():
    parser = build_parser()
    args = parser.parse_args()

    if args.build_dataset:
        cmd_build_dataset(args)
    elif args.sorteo is not None:
        faltan = [name for name, val in
                  [('--t', args.t), ('--s', args.s), ('--r', args.r), ('--ss', args.ss)] if not val]
        if faltan:
            print(f'Faltan argumentos: {", ".join(faltan)}')
            sys.exit(1)
        if args.sistema == 'v4':
            cmd_sorteo_v4(args)
        elif args.sistema == 'v1-legacy':
            cmd_sorteo(args)
        else:
            cmd_sorteo_unificado(args)
    elif args.backtest_models:
        cmd_backtest_models(args)
    elif args.walkforward:
        cmd_walkforward(args)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
