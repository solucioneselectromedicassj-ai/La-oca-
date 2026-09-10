def gen_boletos(cand15):
    """3 boletos (A/B/C) diversificados a partir de los top-15 candidatos por score."""
    c = cand15[:15]
    bA = sorted(c[:6])
    bB = sorted(set(c[:4] + c[6:9]))[:6]
    if len(bB) < 6:
        bB += [x for x in c if x not in bB][:6 - len(bB)]
        bB = sorted(bB)
    bC = sorted(set(c[2:5] + c[9:13]))[:6]
    if len(bC) < 6:
        bC += [x for x in c if x not in bC][:6 - len(bC)]
        bC = sorted(bC)
    return [('A', bA), ('B', bB), ('C', bC)]


def gen_cb(pool, scores, señales, mig_t, mig_s):
    """5 combinaciones diversas para el extra pool."""
    top = sorted(pool, key=lambda x: -scores[x])
    pool_s = set(pool)
    todos = list(range(46))

    def fill(fuente, c):
        return [n for n in fuente if n not in c] or [n for n in todos if n not in c]

    cb = [
        sorted(top[:6]),
        sorted(top[4:10]),
        sorted(señales[:3] + [n for n in top if n not in señales[:3]][:3]),
        sorted([n for n in mig_t if n in pool_s][:3] + top[6:9]),
        sorted([n for n in mig_s if n in pool_s][:3] + top[9:12]),
    ]
    for i, c in enumerate(cb):
        while len(c) < 6:
            c.append(fill(top, c)[0])
            c = sorted(c)
        cb[i] = sorted(set(c))[:6]
    return cb
