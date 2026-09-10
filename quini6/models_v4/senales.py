from collections import defaultdict


def calcular_señales(sorteo):
    """Numeros que aparecieron en 3+ secciones (triple) o exactamente 2 (doble)."""
    conteo = defaultdict(int)
    for sec in ['trad', 'seg', 'rev', 'ss']:
        for n in sorteo[sec]:
            conteo[n] += 1
    triples = sorted(n for n, c in conteo.items() if c >= 3)
    dobles = sorted(n for n, c in conteo.items() if c == 2)
    return triples, dobles
