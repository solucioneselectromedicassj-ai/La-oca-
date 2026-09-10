from collections import Counter


def compute_day_cooc(sorteos):
    """Co-ocurrencias de numeros entre sorteos segun el dia (Domingo/Miercoles)."""
    dom_s = [s for s in sorteos if s['dia'] == 'D']
    mier_s = [s for s in sorteos if s['dia'] == 'X']

    freq_dd = Counter(); freq_dd2 = Counter(); freq_md = Counter()
    freq_dm = Counter(); freq_mm = Counter(); freq_mm2 = Counter()

    for i in range(len(dom_s) - 1):
        for n in set(dom_s[i]['extra']) & set(dom_s[i + 1]['extra']):
            freq_dd[n] += 1
    for i in range(len(dom_s) - 2):
        for n in set(dom_s[i]['extra']) & set(dom_s[i + 2]['extra']):
            freq_dd2[n] += 1
    for d in dom_s:
        nx = next((s for s in mier_s if s['n'] > d['n']), None)
        if nx:
            for n in set(d['extra']) & set(nx['extra']):
                freq_dm[n] += 1
    for m in mier_s:
        nx = next((s for s in dom_s if s['n'] > m['n']), None)
        if nx:
            for n in set(m['extra']) & set(nx['extra']):
                freq_md[n] += 1
    for i in range(len(mier_s) - 1):
        for n in set(mier_s[i]['extra']) & set(mier_s[i + 1]['extra']):
            freq_mm[n] += 1
    for i in range(len(mier_s) - 2):
        for n in set(mier_s[i]['extra']) & set(mier_s[i + 2]['extra']):
            freq_mm2[n] += 1

    return dom_s, mier_s, freq_dd, freq_dd2, freq_md, freq_dm, freq_mm, freq_mm2
