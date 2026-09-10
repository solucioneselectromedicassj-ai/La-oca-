from models.pool import build_pool


def walkforward(sorteos, ventana=200, step=1):
    """
    Evalua la accuracy del pool en cada sorteo, sin look-ahead
    (cada evaluacion solo usa historia previa al sorteo evaluado).
    """
    results = []
    for i in range(ventana, len(sorteos), step):
        hist = sorteos[:i]
        act = sorteos[i]
        er = set(act['extra'])
        nr = len(er)
        p16 = set(build_pool(hist, 16))
        p20 = set(build_pool(hist, 20))
        results.append({
            'n': act['n'],
            'acc_p16': len(p16 & er) / nr,
            'acc_p20': len(p20 & er) / nr,
            'hits_p16': len(p16 & er),
            'hits_p20': len(p20 & er),
        })
    return results
