import numpy as np


def calcular_ausencias(sorteos, N=46):
    """Sorteos transcurridos desde la ultima aparicion de cada numero en 'extra', normalizado."""
    n_dat = len(sorteos)
    scores = np.zeros(N)
    for num in range(N):
        aus = 0
        for k in range(n_dat - 1, -1, -1):
            if num in sorteos[k]['extra']:
                break
            aus += 1
        scores[num] = aus
    if scores.max() > 0:
        scores /= scores.max()
    return scores
