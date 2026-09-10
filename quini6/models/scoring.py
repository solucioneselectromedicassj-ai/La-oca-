from collections import Counter


def score_pool(sorteos, pool20, models):
    """Rankea los numeros del pool por probabilidad de aparecer."""
    N = len(sorteos)
    fe = Counter()
    for s in sorteos:
        for n in s['extra']:
            fe[n] += 1

    ult = {n: -1 for n in range(46)}
    for i, s in enumerate(sorteos):
        for n in s['extra']:
            ult[n] = i

    prev = sorteos[-1]
    sig = Counter()
    for sec in ['trad', 'seg', 'rev', 'ss']:
        for n in prev[sec]:
            sig[n] += 1

    cal = Counter()
    for s in sorteos[-3:]:
        for n in s['extra']:
            cal[n] += 1

    def p_rep(n):
        ap = [i for i, s in enumerate(sorteos[:-1]) if n in s['extra']]
        rep = sum(1 for i in ap if i + 1 < N and n in sorteos[i + 1]['extra'])
        return rep / max(len(ap), 1)

    cnt = Counter()
    for nums in models.values():
        for n in nums:
            cnt[n] += 1

    scores = []
    for n in sorted(pool20):
        v = cnt[n]; p = p_rep(n); se = sig.get(n, 0); c = cal.get(n, 0)
        score = v * 2 + se * 3 + p * 4 + c
        scores.append({'numero': n, 'votos': v, 'señal': se, 'p_rep': p, 'calor': c, 'score': score})

    return sorted(scores, key=lambda x: -x['score'])
