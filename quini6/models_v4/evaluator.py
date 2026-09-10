def evaluar(boletos, cb, resultado_real):
    """Evalua boletos (A/B/C) y CB contra el resultado real de un sorteo (contra 'extra')."""
    real_extra = set(resultado_real['extra'])

    boletos_hits = [(etiqueta, len(set(nums) & real_extra)) for etiqueta, nums in boletos]
    pool_pred = set(n for c in cb for n in c)
    cb_hits = [len(set(c) & real_extra) for c in cb]

    return {
        'boletos': {'hits': boletos_hits, 'max': max(h for _, h in boletos_hits)},
        'pool': {
            'acertados': sorted(pool_pred & real_extra),
            'perdidos': sorted(real_extra - pool_pred),
            'pct': len(pool_pred & real_extra) / len(real_extra) * 100 if real_extra else 0,
        },
        'cb': {'hits': cb_hits, 'max': max(cb_hits) if cb_hits else 0},
    }
