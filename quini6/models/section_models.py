from collections import Counter


def psec(pool, f, fe):
    return sorted(sorted(pool, key=lambda n: -f.get(n, 0) / max(fe.get(n, 1), 1))[:6])


def cruz(pool, f1, f2, fe):
    return sorted(sorted(pool, key=lambda n: -(f1.get(n, 0) + f2.get(n, 0)) / max(fe.get(n, 1), 1))[:6])


def rng(pool, nb, nm, na, f, fe):
    b = sorted([n for n in pool if n <= 15], key=lambda n: -f.get(n, 0) / max(fe.get(n, 1), 1))
    m = sorted([n for n in pool if 16 <= n <= 30], key=lambda n: -f.get(n, 0) / max(fe.get(n, 1), 1))
    a = sorted([n for n in pool if n >= 31], key=lambda n: -f.get(n, 0) / max(fe.get(n, 1), 1))
    return sorted(b[:nb] + m[:nm] + a[:na])


def t6(c, base):
    return sorted([n for n, _ in Counter({n: c.get(n, 0) for n in base}).most_common(6)])
