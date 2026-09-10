def summarize(results):
    """Resume los resultados de walk-forward: accuracy promedio y % de aciertos >=4 (V4+)."""
    n = len(results)
    if n == 0:
        return {'n': 0, 'acc_p16': 0.0, 'acc_p20': 0.0, 'v4_p16': 0.0, 'v4_p20': 0.0}
    return {
        'n': n,
        'acc_p16': sum(r['acc_p16'] for r in results) / n,
        'acc_p20': sum(r['acc_p20'] for r in results) / n,
        'v4_p16': sum(1 for r in results if r['hits_p16'] >= 4) / n,
        'v4_p20': sum(1 for r in results if r['hits_p20'] >= 4) / n,
    }
