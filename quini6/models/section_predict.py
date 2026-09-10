from collections import Counter

SECCIONES = ('trad', 'seg', 'rev', 'ss')


def predecir_seccion(sorteos, seccion, N=46):
    """
    Score por número para una sección específica (T/S/R/SS), combinando:
    frecuencia histórica, co-ocurrencia con el sorteo anterior de la misma
    sección, señal cruzada de las otras 3 secciones, ausencia y calor reciente.
    """
    prev = sorteos[-1]
    todos = range(N)

    freq = Counter()
    for s in sorteos:
        for n in s[seccion]:
            freq[n] += 1

    ref = set(prev[seccion])
    cooc = Counter()
    for s in sorteos[:-1]:
        ov = ref & set(s[seccion])
        if ov:
            for n in s[seccion]:
                if n not in ref:
                    cooc[n] += len(ov)

    otras = set(SECCIONES) - {seccion}
    cruz = Counter()
    for sec in otras:
        for n in prev[sec]:
            cruz[n] += 1

    ult_vez = {n: -1 for n in todos}
    for i, s in enumerate(sorteos):
        for n in s[seccion]:
            ult_vez[n] = i
    aus = {n: len(sorteos) - 1 - ult_vez[n] for n in todos}

    rec = Counter()
    for i, s in enumerate(sorteos[-20:]):
        w = 1 + 0.15 * i
        for n in s[seccion]:
            rec[n] += w

    max_freq = max(freq.values()) if freq else 1
    max_cooc = max(cooc.values()) if cooc else 1
    max_rec = max(rec.values()) if rec else 1

    score = Counter()
    for n in todos:
        score[n] = ((freq[n] / max_freq) * 3 +
                    (cooc[n] / max_cooc if max_cooc > 0 else 0) * 4 +
                    cruz.get(n, 0) * 2 +
                    min(aus[n] / 10, 2) +
                    (rec[n] / max_rec if max_rec > 0 else 0) * 2)
    return score


def grupos_seccion(sorteos, seccion, N=46):
    """Grupo A (top 6) y Grupo B (candidatos 7-12) para una sección, más el score completo."""
    score = predecir_seccion(sorteos, seccion, N)
    ranked = [n for n, _ in score.most_common(12)]
    grupo_a = sorted(ranked[:6])
    grupo_b = sorted(ranked[6:12])
    return grupo_a, grupo_b, score


def extra_por_seccion(sc_t, sc_s, sc_r):
    """Extra pool combinando los scores de Trad+Seg+Rev (no SS, igual que el pool extra real)."""
    combinado = Counter()
    for sc in (sc_t, sc_s, sc_r):
        for n, v in sc.items():
            combinado[n] += v
    ranked = [n for n, _ in combinado.most_common(12)]
    return sorted(ranked[:6]), sorted(ranked[6:12])


def mod_complemento(sorteos, N=46):
    """Números que escapan al análisis principal: impares, rango alto, ausencia media, frecuencia moderada."""
    freq_ex = Counter()
    for s in sorteos:
        for n in s['extra']:
            freq_ex[n] += 1

    ult_vez = {n: -1 for n in range(N)}
    for i, s in enumerate(sorteos):
        for n in s['extra']:
            ult_vez[n] = i
    aus = {n: len(sorteos) - 1 - ult_vez[n] for n in range(N)}

    max_freq = max(freq_ex.values()) if freq_ex else 1
    score = Counter()
    for n in range(N):
        s_paridad = 1.5 if n % 2 != 0 else 0
        s_rango = 2.0 if n >= 31 else (1.0 if n >= 16 else 0.5)
        s_aus = 2.0 if 5 <= aus[n] <= 20 else (1.0 if aus[n] < 5 else 0.5)
        s_freq = 1.0 - (freq_ex[n] / max_freq) * 0.5
        score[n] = s_paridad + s_rango + s_aus + s_freq

    return sorted(n for n, _ in score.most_common(6))
