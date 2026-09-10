import numpy as np


def mod_decay(sorteos, dia_siguiente, lam=0.012, N=46):
    """Co-ocurrencia con decaimiento exponencial entre sorteos consecutivos del mismo día."""
    pares = [(sorteos[i], sorteos[i + 1]) for i in range(len(sorteos) - 1)
             if sorteos[i + 1]['dia'] == dia_siguiente]
    base_ex = set(sorteos[-1]['extra'])
    scores = np.zeros(N)
    for num in range(N):
        score, norm = 0.0, 0.0
        for lag_idx, (t0, t1) in enumerate(pares):
            lag = len(pares) - lag_idx
            peso = np.exp(-lam * lag)
            norm += peso
            if num in t0['extra'] and num in t1['extra']:
                score += peso
        scores[num] = (score / norm if norm > 0 else 0) * (1.3 if num in base_ex else 1)
    if scores.max() > 0:
        scores /= scores.max()
    return scores
