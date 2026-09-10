from collections import Counter

from .day_models import compute_day_cooc
from .pool import build_pool, build_pool_c
from .section_models import cruz, psec, rng, t6
from .special_models import ciclo_s_scores, mod_d1_scores, mod_pres_scores, mod_sim_scores

__all__ = ['build_pool', 'build_pool_c', 'get_all_models']


def get_all_models(sorteos, pool20, poolC):
    """Retorna dict {nombre: [6 numeros]} para todos los modelos."""
    N = len(sorteos)
    fe = Counter(); ft = Counter(); fs = Counter(); fr = Counter(); fss = Counter()
    for s in sorteos:
        for n in s['extra']:
            fe[n] += 1
        for n in s['trad']:
            ft[n] += 1
        for n in s['seg']:
            fs[n] += 1
        for n in s['rev']:
            fr[n] += 1
        for n in s['ss']:
            fss[n] += 1

    ult = {n: -1 for n in range(46)}
    for i, s in enumerate(sorteos):
        for n in s['extra']:
            ult[n] = i
    aus = {n: N - 1 - ult[n] for n in range(46)}

    ciclo = {}
    for n in range(46):
        ap = [i for i, s in enumerate(sorteos) if n in s['extra']]
        ciclo[n] = sum(ap[j + 1] - ap[j] for j in range(len(ap) - 1)) / max(len(ap) - 1, 1) if len(ap) >= 2 else N

    cal = Counter()
    for s in sorteos[-3:]:
        for n in s['extra']:
            cal[n] += 1

    prev = sorteos[-1]

    dom_s, mier_s, freq_dd, freq_dd2, freq_md, freq_dm, freq_mm, freq_mm2 = compute_day_cooc(sorteos)

    sc_d1 = mod_d1_scores(sorteos, prev)
    sc_sim = mod_sim_scores(sorteos, prev)
    sc_cics = ciclo_s_scores(sorteos)
    sc_pres = mod_pres_scores(sorteos, fe, N)

    dia_siguiente = 'D' if prev['dia'] == 'X' else 'X'

    mods = {
        'A-PTRAD': psec(pool20, ft, fe),
        'A-PSEG': psec(pool20, fs, fe),
        'A-PREV': psec(pool20, fr, fe),
        'A-PSS': psec(pool20, fss, fe),
        'A-TR': cruz(pool20, ft, fr, fe),
        'A-TS': cruz(pool20, ft, fs, fe),
        'A-SR': cruz(pool20, fs, fr, fe),
        'A-RNGR': rng(pool20, 2, 2, 2, fr, fe),
        'A-RNGT': rng(pool20, 2, 2, 2, ft, fe),
        'A-AUS': sorted(sorted(pool20, key=lambda n: -aus[n])[:6]),
        'A-CIC': sorted(sorted(pool20, key=lambda n: -(aus[n] - ciclo[n]))[:6]),
        'C-SR': cruz(poolC, fs, fr, fe),
        'C-AUS': sorted(sorted(poolC, key=lambda n: -aus[n])[:6]),
        'C-RNGT': rng(poolC, 2, 2, 2, ft, fe),
        'MOD-D1': sorted([n for n, _ in sc_d1.most_common(6)]),
        'MOD-SIM': sorted([n for n, _ in sc_sim.most_common(6)]),
        'MOD-CAL': t6(cal, range(46)),
        'MOD-PRES': sorted([n for n, _ in sc_pres.most_common(6)]),
        'CICLO-S': sorted([n for n, _ in Counter(sc_cics).most_common(6)]),
        'MOD-INT': sorted([n for n, _ in Counter({
            n: fe[n] / N + ft[n] / N + fs[n] / N + fr[n] / N for n in range(46)
        }).most_common(6)]),
    }

    if dia_siguiente == 'D':
        mods['MOD-DD'] = t6(freq_dd, dom_s[-1]['extra']) if freq_dd and dom_s else mods['A-PREV']
        mods['MOD-DD2'] = t6(freq_dd2, dom_s[-2]['extra']) if freq_dd2 and len(dom_s) >= 2 else mods['A-PSEG']
        mods['MOD-MD'] = t6(freq_md, mier_s[-1]['extra']) if freq_md and mier_s else mods['A-SR']
    else:
        mods['MOD-DM'] = t6(freq_dm, dom_s[-1]['extra']) if freq_dm and dom_s else mods['A-PREV']
        mods['MOD-MM'] = t6(freq_mm, mier_s[-1]['extra']) if freq_mm and mier_s else mods['A-SR']
        mods['MOD-MM2'] = t6(freq_mm2, mier_s[-2]['extra']) if freq_mm2 and len(mier_s) >= 2 else mods['A-PSEG']

    return mods
