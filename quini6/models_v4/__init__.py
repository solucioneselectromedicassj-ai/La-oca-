from .ausencia import calcular_ausencias
from .decay import mod_decay
from .fft import mod_fft
from .knn import mod_knn
from .logit import mod_logit
from .meta import PESOS_ENSEMBLE, mod_meta

BOOST_TRIPLE = 1.5
BOOST_DOBLE = 1.0
BOOST_MIG_T = 0.55
BOOST_MIG_S = 0.50
BOOST_MIG_SS = 0.25
BOOST_AUS_LARGA = 0.60
BOOST_ZONA_MID = 0.15
ZONA_MID = range(8, 23)

__all__ = ['predecir', 'PESOS_ENSEMBLE']


def predecir(sorteos, dia_siguiente, señales_triples, señales_dobles, lam=0.012, N=46, pool_size=18):
    """Ensemble DECAY+LOGIT+KNN+FFT+ausencia, con boosts de señales y migración."""
    sc_decay = mod_decay(sorteos, dia_siguiente, lam, N)
    sc_logit = mod_logit(sorteos, dia_siguiente, N)
    sc_knn = mod_knn(sorteos, dia_siguiente, N=N)
    sc_fft = mod_fft(sorteos, N)
    sc_aus = calcular_ausencias(sorteos, N)

    scores = mod_meta(
        {'decay': sc_decay, 'logit': sc_logit, 'knn': sc_knn, 'fft': sc_fft, 'aus': sc_aus},
        PESOS_ENSEMBLE, N,
    )

    for n in señales_triples:
        scores[n] += BOOST_TRIPLE
    for n in señales_dobles:
        scores[n] += BOOST_DOBLE

    ultimo = sorteos[-1]
    for n in ultimo['trad']:
        scores[n] += BOOST_MIG_T
    for n in ultimo['seg']:
        scores[n] += BOOST_MIG_S
    for n in ultimo['ss']:
        scores[n] += BOOST_MIG_SS

    for n in ZONA_MID:
        scores[n] += BOOST_ZONA_MID

    vistos_recientes = set()
    for s in sorteos[-3:]:
        vistos_recientes.update(s['extra'])
    for n in range(N):
        if n not in vistos_recientes:
            scores[n] += BOOST_AUS_LARGA

    if scores.max() > 0:
        scores /= scores.max()

    top = sorted(range(N), key=lambda x: -scores[x])[:pool_size]
    return scores, sorted(top)
