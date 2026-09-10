from data.loader import calc_fecha, fmt_nums
import tracking.store as tracking

DIA_NOMBRE = {'D': 'Domingo', 'X': 'Miércoles'}
CAT_NOMBRE = {
    'trad': 'TRADICIONAL', 'seg': 'LA SEGUNDA', 'rev': 'REVANCHA',
    'ss': 'SIEMPRE SALE', 'extra': 'EXTRA POOL',
}
ORDEN_CATS = ['trad', 'seg', 'rev', 'ss', 'extra']


def _linea_historial(stats_modelo):
    if not stats_modelo or not stats_modelo['n']:
        return '(sin historial)'
    prom = stats_modelo['sum_hits'] / stats_modelo['n']
    return (f"(hist: {prom:.2f} prom/6, {stats_modelo['n']} sorteos evaluados, "
            f"máx {stats_modelo['max_hits']}, {stats_modelo['veces_4mas']}x con 4+)")


def generate_report(result):
    nuevo = result['nuevo']
    lines = []

    if result['evaluacion']:
        lines.append(f"=== EVALUACIÓN SORTEO {nuevo['n']} vs. proyección guardada ===")
        for cat, nombre, hits, nums in result['evaluacion']:
            lines.append(f"  [{CAT_NOMBRE[cat]:<12}] {nombre:<10} {hits}/6  {fmt_nums(nums)}")
        lines.append('')
    else:
        lines.append(f"(No había proyección guardada para el sorteo {nuevo['n']}; no se evaluó nada.)")
        lines.append('')

    lines.append(f"Sorteo cargado: {nuevo['n']} ({DIA_NOMBRE[nuevo['dia']]} "
                 f"{calc_fecha(nuevo['n']).strftime('%d/%m/%Y')})")
    lines.append(f"Trad: {fmt_nums(nuevo['trad'])} | Seg: {fmt_nums(nuevo['seg'])}")
    lines.append(f"Rev:  {fmt_nums(nuevo['rev'])} | SS: {fmt_nums(nuevo['ss'])}")
    lines.append(f"Extra: {fmt_nums(nuevo['extra'])}")
    lines.append('')

    target_n = result['target_n']
    fecha_t = calc_fecha(target_n)
    lines.append(f"=== PROYECCIÓN SORTEO {target_n} "
                 f"({DIA_NOMBRE[result['target_dia']]} {fecha_t.strftime('%d/%m/%Y')}) ===")
    lines.append(f"Pool-16: {fmt_nums(result['pool16'])}")
    lines.append(f"Pool-20: {fmt_nums(result['pool20'])}")
    lines.append(f"Pool-C:  {fmt_nums(result['poolC'])}")
    lines.append('')

    for cat in ORDEN_CATS:
        modelos = result['categorias'].get(cat, {})
        if not modelos:
            continue
        rank = dict(tracking.ranking(cat))
        orden_nombres = [nombre for nombre, _ in tracking.ranking(cat)]
        ordenados = sorted(
            modelos.items(),
            key=lambda kv: orden_nombres.index(kv[0]) if kv[0] in orden_nombres else 999,
        )
        lines.append(f"── {CAT_NOMBRE[cat]} (modelos ordenados por acierto histórico) ──")
        for nombre, nums in ordenados:
            lines.append(f"  {nombre:<10} {fmt_nums(nums):<20} {_linea_historial(rank.get(nombre))}")
        lines.append('')

    return '\n'.join(lines)
