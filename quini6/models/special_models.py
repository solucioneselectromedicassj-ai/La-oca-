import math
from collections import Counter


def mod_d1_scores(sorteos, prev):
    """Co-ocurrencia Siempre Sale -> Extra del sorteo siguiente."""
    ss_cooc = Counter()
    for i in range(len(sorteos) - 1):
        for n in sorteos[i]['ss']:
            for m in sorteos[i + 1]['extra']:
                ss_cooc[(n, m)] += 1
    sc = Counter()
    for n in prev['ss']:
        for m in range(46):
            sc[m] += ss_cooc.get((n, m), 0)
    return sc


def mod_sim_scores(sorteos, prev):
    """Similitud por Siempre Sale con sorteos pasados."""
    N = len(sorteos)
    sim_scores = [
        (i, len(set(s['ss']) & set(prev['ss'])) / max(len(prev['ss']), 1))
        for i, s in enumerate(sorteos[:-1])
    ]
    sc = Counter()
    for idx, _ in sorted(sim_scores, key=lambda x: -x[1])[:5]:
        if idx + 1 < N:
            for n in sorteos[idx + 1]['extra']:
                sc[n] += 1
    return sc


def ciclo_s_scores(sorteos):
    """Ciclo vencido en la Segunda."""
    N = len(sorteos)
    sc = {}
    for n in range(46):
        ap = [i for i, s in enumerate(sorteos) if n in s['seg']]
        if len(ap) >= 3:
            gaps = [ap[j + 1] - ap[j] for j in range(len(ap) - 1)]
            m = sum(gaps) / len(gaps)
            cv = math.sqrt(sum((g - m) ** 2 for g in gaps) / len(gaps)) / m if m > 0 else 1
            sc[n] = max(0, N - 1 - ap[-1] - m) / max(m, 1) / max(cv, 0.1)
        else:
            sc[n] = 0
    return sc


def mod_pres_scores(sorteos, fe, N):
    """Deficit acumulado respecto a la frecuencia esperada."""
    return Counter({
        n: fe[n] / N * 20 - sum(1 for s in sorteos[-20:] if n in s['extra'])
        for n in range(46)
    })
