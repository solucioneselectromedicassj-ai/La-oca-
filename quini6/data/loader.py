import os
from datetime import date, timedelta

DATASET_PATH = os.path.join(os.path.dirname(__file__), 'dataset.txt')
REAL_SOURCE_PATH = os.path.join(os.path.dirname(__file__), 'sources', 'quini6_real_3276_3407.txt')

DIA_ANCHOR_N = 3276
DIA_ANCHOR_DATE = date(2025, 6, 8)  # Domingo 08/06/2025 - ancla verificada

# Sorteos hardcodeados como override porque son verificados a mano y pueden
# no coincidir con lo que extraiga el parser de PDF para ese rango.
VERIFICADOS = {
    3393: ('X', [0, 5, 10, 36, 41, 42], [6, 24, 31, 34, 42, 43], [1, 8, 18, 30, 38, 43], [2, 7, 20, 23, 44, 45]),
    3394: ('D', [8, 9, 12, 21, 28, 37], [0, 1, 3, 4, 5, 22], [3, 5, 8, 22, 25, 45], [6, 10, 13, 40, 42, 43]),
    3395: ('X', [0, 2, 27, 34, 37, 38], [0, 1, 3, 6, 10, 35], [6, 24, 28, 32, 39, 42], [15, 17, 30, 35, 36, 39]),
    3396: ('D', [0, 12, 23, 29, 43, 45], [1, 13, 18, 29, 31, 44], [2, 3, 19, 20, 23, 25], [0, 1, 9, 22, 27, 29]),
    3397: ('X', [3, 4, 14, 17, 19, 35], [5, 22, 28, 31, 32, 41], [8, 11, 14, 29, 33, 44], [5, 10, 20, 24, 25, 38]),
    3398: ('D', [6, 9, 10, 18, 22, 31], [11, 13, 23, 25, 26, 30], [1, 3, 18, 23, 24, 31], [1, 9, 16, 18, 30, 40]),
    3399: ('X', [23, 24, 25, 30, 31, 44], [4, 8, 16, 20, 24, 36], [3, 7, 22, 24, 25, 42], [13, 21, 23, 26, 32, 33]),
    3400: ('D', [2, 9, 15, 18, 28, 31], [2, 18, 28, 34, 43, 44], [12, 16, 29, 30, 37, 43], [2, 6, 9, 10, 32, 35]),
    3401: ('X', [1, 2, 6, 10, 17, 25], [3, 10, 12, 16, 26, 33], [2, 12, 14, 24, 29, 40], [7, 21, 27, 30, 32, 37]),
    3402: ('D', [0, 21, 24, 26, 27, 42], [19, 24, 25, 27, 29, 36], [2, 9, 21, 29, 36, 39], [1, 4, 5, 20, 37, 43]),
    3403: ('X', [5, 9, 11, 16, 23, 26], [10, 14, 25, 30, 37, 39], [8, 10, 22, 30, 36, 37], [20, 23, 24, 28, 35, 39]),
    3404: ('D', [7, 14, 22, 23, 40, 45], [5, 11, 17, 36, 38, 40], [0, 5, 10, 20, 26, 28], [6, 13, 14, 21, 36, 37]),
    3405: ('X', [0, 5, 10, 22, 26, 45], [2, 3, 16, 22, 24, 44], [2, 7, 14, 25, 34, 38], [2, 5, 8, 10, 31, 38]),
    3406: ('D', [2, 16, 20, 21, 22, 38], [12, 16, 23, 26, 28, 34], [0, 3, 22, 32, 37, 41], [0, 3, 4, 13, 23, 42]),
    3407: ('X', [10, 19, 22, 29, 36, 43], [3, 10, 24, 28, 32, 45], [0, 8, 20, 23, 24, 32], [1, 9, 21, 30, 35, 41]),
}


def calc_dia(n):
    """D=Domingo, X=Miercoles. Ancla: 3276 = Domingo 08/06/2025."""
    return 'D' if (n - DIA_ANCHOR_N) % 2 == 0 else 'X'


def calc_fecha(n):
    """Fecha calendario del sorteo n, a partir del ancla y la alternancia D/X semanal."""
    diff = n - DIA_ANCHOR_N
    pares, resto = divmod(diff, 2)
    d = DIA_ANCHOR_DATE + timedelta(days=7 * pares)
    if resto == 1:
        d += timedelta(days=3)  # Domingo -> Miercoles siguiente
    return d


def fmt_nums(nums):
    return '-'.join(f'{n:02d}' for n in sorted(nums))


def parse_nums(s):
    return [int(x) for x in s.split('-') if x != '']


def make_sorteo(n, dia, trad, seg, rev, ss):
    extra = sorted(set(trad) | set(seg) | set(rev))
    return {
        'n': n, 'dia': dia,
        'trad': sorted(trad), 'seg': sorted(seg), 'rev': sorted(rev), 'ss': sorted(ss),
        'extra': extra,
    }


def load_dataset(path=DATASET_PATH):
    sorteos = []
    if not os.path.exists(path):
        return sorteos
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('sorteo|'):
                continue
            parts = line.split('|')
            if len(parts) < 6:
                continue
            n = int(parts[0])
            dia = parts[1]
            trad, seg, rev, ss = (parse_nums(p) for p in parts[2:6])
            sorteos.append(make_sorteo(n, dia, trad, seg, rev, ss))
    sorteos.sort(key=lambda s: s['n'])
    return sorteos


def save_dataset(sorteos, path=DATASET_PATH):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    sorteos = sorted(sorteos, key=lambda s: s['n'])
    with open(path, 'w', encoding='utf-8') as f:
        f.write('sorteo|dia|trad|seg|rev|ss|extra\n')
        for s in sorteos:
            f.write('|'.join([
                str(s['n']), s['dia'],
                fmt_nums(s['trad']), fmt_nums(s['seg']), fmt_nums(s['rev']), fmt_nums(s['ss']),
                fmt_nums(s['extra']),
            ]) + '\n')


def apply_verificados(sorteos_by_n):
    for n, (dia, trad, seg, rev, ss) in VERIFICADOS.items():
        sorteos_by_n[n] = make_sorteo(n, dia, trad, seg, rev, ss)
    return sorteos_by_n
