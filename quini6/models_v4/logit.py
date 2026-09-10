import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler


def mod_logit(sorteos, dia_siguiente, N=46, ventana=100):
    """Regresion logistica por numero con 7 features (ausencia, tendencia, señal, dia, etc.)."""

    def get_features(idx, num):
        aus = 0
        for k in range(idx, -1, -1):
            if num in sorteos[k]['extra']:
                break
            aus += 1
        ap = [1 if num in sorteos[k]['extra'] else 0 for k in range(idx + 1)]
        fg = sum(ap) / len(ap) if ap else 0
        ciclo = (idx + 1) / (sum(ap) + 1)
        x1 = aus / ciclo if ciclo > 0 else 0
        rec = ap[-20:] if len(ap) >= 20 else ap
        x2 = (sum(rec) / len(rec)) / fg if fg > 0 else 0
        s = sorteos[idx]
        # señal en abs(): un coeficiente negativo aprendido penalizaría dobles/triples,
        # que en la práctica migran con alta probabilidad al sorteo siguiente.
        x3 = abs(sum([num in s['trad'], num in s['seg'], num in s['rev']]))
        x4 = 1 if num in s['extra'] else 0
        x5 = 1 if idx > 0 and num in sorteos[idx - 1]['extra'] else 0
        x6 = 1 if dia_siguiente == 'X' else 0
        x7 = min(aus, 20) / 20
        return [x1, x2, x3, x4, x5, x6, x7]

    n_dat = len(sorteos)
    X_tr, y_tr = [], []
    for i in range(max(1, n_dat - ventana), n_dat - 1):
        nx = sorteos[i + 1]['extra']
        for num in range(N):
            X_tr.append(get_features(i, num))
            y_tr.append(1 if num in nx else 0)

    if len(set(y_tr)) < 2:
        return np.zeros(N)

    scaler = StandardScaler()
    X_sc = scaler.fit_transform(X_tr)
    clf = LogisticRegression(C=0.5, max_iter=500, random_state=42)
    clf.fit(X_sc, y_tr)

    X_pred = scaler.transform([get_features(n_dat - 1, num) for num in range(N)])
    probs = clf.predict_proba(X_pred)[:, 1]
    if probs.max() > 0:
        probs /= probs.max()
    return probs
