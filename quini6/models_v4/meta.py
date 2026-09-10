import numpy as np

PESOS_ENSEMBLE = {
    'decay': 2.5,
    'logit': 1.5,
    'knn': 1.8,
    'fft': 2.0,
    'aus': 2.2,
}


def mod_meta(scores_dict, pesos_base=PESOS_ENSEMBLE, N=46):
    """Ensemble ponderado de los scores de cada modelo."""
    total = sum(pesos_base.values())
    score_final = np.zeros(N)
    for nombre, sc in scores_dict.items():
        w = pesos_base.get(nombre, 1.0)
        score_final += (w / total) * sc
    if score_final.max() > 0:
        score_final /= score_final.max()
    return score_final
