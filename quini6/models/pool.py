from collections import Counter


def build_pool(sorteos, size=20):
    """Construye el pool de candidatos para el proximo sorteo."""
    N = len(sorteos)
    fe = Counter(); ft = Counter(); fs = Counter(); fr = Counter()
    fdom = Counter(); fmier = Counter()

    for s in sorteos:
        for n in s['extra']:
            fe[n] += 1
            if s['dia'] == 'D':
                fdom[n] += 1
            else:
                fmier[n] += 1
        for n in s['trad']:
            ft[n] += 1
        for n in s['seg']:
            fs[n] += 1
        for n in s['rev']:
            fr[n] += 1

    prev = sorteos[-1]
    sig = Counter()
    for sec in ['trad', 'seg', 'rev', 'ss']:
        for n in prev[sec]:
            sig[n] += 1

    cal = Counter()
    for s in sorteos[-3:]:
        for n in s['extra']:
            cal[n] += 1

    ult = {n: -1 for n in range(46)}
    for i, s in enumerate(sorteos):
        for n in s['extra']:
            ult[n] = i
    aus = {n: N - 1 - ult[n] for n in range(46)}

    mfe = max(fe.values())
    mft = max(max(ft.values()), 1)
    fd = fdom if prev['dia'] == 'X' else fmier
    mfd = max(max(fd.values()), 1) if fd else 1

    score = Counter({
        n: (fe[n] / mfe) * 4 + (fd.get(n, 0) / mfd) * 3 + sig.get(n, 0) * 3 +
           cal.get(n, 0) * 2 + min(aus[n] / 8, 2) + (ft[n] + fs[n] + fr[n]) / (mft * 3) * 2
        for n in range(46)
    })
    return sorted(range(46), key=lambda x: -score[x])[:size]


def build_pool_c(sorteos, size=16):
    """Pool C: numeros con ciclo vencido (complementario al pool estandar)."""
    N = len(sorteos)
    fe = Counter()
    for s in sorteos:
        for n in s['extra']:
            fe[n] += 1

    ult = {n: -1 for n in range(46)}
    for i, s in enumerate(sorteos):
        for n in s['extra']:
            ult[n] = i
    aus = {n: N - 1 - ult[n] for n in range(46)}

    ciclo = {}
    for n in range(46):
        ap = [i for i, s in enumerate(sorteos) if n in s['extra']]
        ciclo[n] = sum(ap[j + 1] - ap[j] for j in range(len(ap) - 1)) / max(len(ap) - 1, 1) if len(ap) >= 2 else N

    mfe = max(fe.values())
    score = Counter({
        n: (aus[n] / max(ciclo[n], 1)) * 4 + min(aus[n] / 3, 5) + fe[n] / mfe * 2
        if fe[n] >= 5 else 0
        for n in range(46)
    })
    return sorted(range(46), key=lambda x: -score[x])[:size]
