import numpy as np


def mod_fft(sorteos, N=46):
    """Detecta el ciclo dominante de aparicion de cada numero via FFT sobre su serie binaria."""
    n_dat = len(sorteos)
    scores = np.zeros(N)
    for num in range(N):
        serie = np.array([1 if num in s['extra'] else 0 for s in sorteos], dtype=float)
        fft_v = np.abs(np.fft.rfft(serie))
        freqs = np.fft.rfftfreq(n_dat)
        fft_v[0] = 0
        idx_d = np.argmax(fft_v[1:]) + 1 if len(fft_v) > 1 else 0
        fd = freqs[idx_d]
        ciclo = 1 / fd if fd > 0 else n_dat
        aus = 0
        for k in range(n_dat - 1, -1, -1):
            if num in sorteos[k]['extra']:
                break
            aus += 1
        diff = abs(aus - ciclo)
        sc = max(0, 1 - diff / ciclo) if ciclo > 0 else 0
        if aus >= ciclo:
            sc += 0.5
        scores[num] = sc
    if scores.max() > 0:
        scores /= scores.max()
    return scores
