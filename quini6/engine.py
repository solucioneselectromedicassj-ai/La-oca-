from data.loader import calc_dia, load_dataset, make_sorteo, save_dataset
from models import build_pool, build_pool_c, get_all_models
from models.section_predict import extra_por_seccion, grupos_seccion, mod_complemento
import tracking.store as tracking


def build_all_models(sorteos):
    """
    Corre TODOS los modelos disponibles (pool extra v1 + por sección) sobre la historia
    dada. Devuelve {categoria: {nombre_modelo: [6 numeros]}} para 'trad','seg','rev','ss','extra'.
    """
    pool16 = build_pool(sorteos, 16)
    pool20 = build_pool(sorteos, 20)
    poolC = build_pool_c(sorteos, 16)

    categorias = {'extra': dict(get_all_models(sorteos, pool20, poolC))}

    t_a, t_b, sc_t = grupos_seccion(sorteos, 'trad')
    s_a, s_b, sc_s = grupos_seccion(sorteos, 'seg')
    r_a, r_b, sc_r = grupos_seccion(sorteos, 'rev')
    ss_a, ss_b, _ = grupos_seccion(sorteos, 'ss')

    categorias['trad'] = {'MOD-T-A': t_a, 'MOD-T-B': t_b}
    categorias['seg'] = {'MOD-S-A': s_a, 'MOD-S-B': s_b}
    categorias['rev'] = {'MOD-R-A': r_a, 'MOD-R-B': r_b}
    categorias['ss'] = {'MOD-SS-A': ss_a, 'MOD-SS-B': ss_b}

    ex_a, ex_b = extra_por_seccion(sc_t, sc_s, sc_r)
    categorias['extra']['MOD-EX-A'] = ex_a
    categorias['extra']['MOD-EX-B'] = ex_b
    categorias['extra']['MOD-COMP'] = mod_complemento(sorteos)

    return categorias, pool16, pool20, poolC


def process_sorteo(dataset_path, n, dia, trad, seg, rev, ss):
    """
    Pipeline completo para un sorteo ya jugado:
    1) evalúa la proyección guardada para ese sorteo (si existía) y actualiza el historial
       de aciertos por modelo,
    2) agrega el sorteo al dataset,
    3) genera y guarda la proyección para el sorteo siguiente con todos los modelos.
    """
    sorteos = load_dataset(dataset_path)
    if not sorteos:
        raise RuntimeError('Dataset vacío. Corré primero: python main.py --build-dataset')

    dia = dia or calc_dia(n)
    nuevo = make_sorteo(n, dia, trad, seg, rev, ss)

    evaluacion = tracking.evaluar_pendiente(nuevo)

    sorteos = [s for s in sorteos if s['n'] != nuevo['n']] + [nuevo]
    sorteos.sort(key=lambda s: s['n'])
    save_dataset(sorteos, dataset_path)

    categorias, pool16, pool20, poolC = build_all_models(sorteos)
    target_n = n + 1
    target_dia = 'D' if nuevo['dia'] == 'X' else 'X'
    tracking.registrar_proyeccion(target_n, categorias)

    return {
        'nuevo': nuevo,
        'evaluacion': evaluacion,
        'target_n': target_n,
        'target_dia': target_dia,
        'categorias': categorias,
        'pool16': pool16, 'pool20': pool20, 'poolC': poolC,
    }
