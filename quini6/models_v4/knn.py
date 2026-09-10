import numpy as np


def mod_knn(sorteos, dia_siguiente, K=10, N=46):
    """Busca los K sorteos historicos mas similares (Jaccard sobre 'extra') al ultimo sorteo."""
    actual = set(sorteos[-1]['extra'])
    sims = []
    for i in range(len(sorteos) - 2):
        if sorteos[i + 1]['dia'] != dia_siguiente:
            continue
        hist = set(sorteos[i]['extra'])
        u = len(actual | hist)
        inter = len(actual & hist)
        sims.append((inter / u if u > 0 else 0, i))
    sims.sort(reverse=True)

    scores = np.zeros(N)
    for jacc, i in sims[:K]:
        for num in sorteos[i + 1]['extra']:
            scores[num] += jacc
    if scores.max() > 0:
        scores /= scores.max()
    return scores
