from data.loader import DIA_VERIFICADO_DESDE
from engine import build_all_models
import tracking.store as tracking


def backtest_and_seed(sorteos, ventana=200, solo_dia_verificado=False):
    """
    Walk-forward honesto: en cada paso corre TODOS los modelos usando solo la historia
    previa al sorteo evaluado (sin look-ahead), y siembra tracking/model_stats.json con
    el resultado real de cada modelo.

    solo_dia_verificado=True restringe la evaluación (no el historial de entrenamiento)
    a sorteos con día D/X verificado (>= DIA_VERIFICADO_DESDE) - los sorteos anteriores
    tienen el día estimado, no verificado.
    """
    stats = {}
    n_evaluados = 0
    for i in range(ventana, len(sorteos)):
        actual = sorteos[i]
        if solo_dia_verificado and actual['n'] < DIA_VERIFICADO_DESDE:
            continue
        hist = sorteos[:i]
        categorias, *_ = build_all_models(hist)
        real = tracking.real_por_categoria(actual)
        for cat, modelos in categorias.items():
            real_cat = real.get(cat, set())
            for nombre, nums in modelos.items():
                hits = len(set(nums) & real_cat)
                tracking.actualizar_stats(stats, cat, nombre, hits)
        n_evaluados += 1

    tracking.save_stats(stats)
    return stats, n_evaluados
