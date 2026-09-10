import json
import os

TRACKING_DIR = os.path.dirname(__file__)
PENDING_PATH = os.path.join(TRACKING_DIR, 'pending.json')
STATS_PATH = os.path.join(TRACKING_DIR, 'model_stats.json')

CATEGORIAS = ('trad', 'seg', 'rev', 'ss', 'extra')


def _load(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def _save(path, data):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=1, ensure_ascii=False, sort_keys=True)


def load_pending():
    return _load(PENDING_PATH)


def save_pending(data):
    _save(PENDING_PATH, data)


def load_stats():
    return _load(STATS_PATH)


def save_stats(data):
    _save(STATS_PATH, data)


def registrar_proyeccion(target_n, categorias):
    """categorias: {categoria: {modelo: [numeros]}}. Sobreescribe cualquier proyección previa para ese sorteo."""
    pending = load_pending()
    pending[str(target_n)] = categorias
    save_pending(pending)


def actualizar_stats(stats, cat, nombre, hits):
    cat_stats = stats.setdefault(cat, {})
    m = cat_stats.setdefault(nombre, {'n': 0, 'sum_hits': 0, 'max_hits': 0, 'veces_4mas': 0})
    m['n'] += 1
    m['sum_hits'] += hits
    m['max_hits'] = max(m['max_hits'], hits)
    if hits >= 4:
        m['veces_4mas'] += 1


def real_por_categoria(sorteo):
    return {
        'extra': set(sorteo['extra']), 'trad': set(sorteo['trad']),
        'seg': set(sorteo['seg']), 'rev': set(sorteo['rev']), 'ss': set(sorteo['ss']),
    }


def evaluar_pendiente(sorteo):
    """
    Si había una proyección guardada para sorteo['n'], la evalúa contra el resultado real,
    actualiza las estadísticas históricas por modelo y devuelve la lista de resultados
    [(categoria, nombre, hits, numeros_predichos)] ordenada de mayor a menor acierto.
    Devuelve None si no había proyección pendiente para ese sorteo.
    """
    pending = load_pending()
    key = str(sorteo['n'])
    if key not in pending:
        return None

    categorias = pending.pop(key)
    save_pending(pending)

    stats = load_stats()
    real = real_por_categoria(sorteo)
    resultados = []
    for cat, modelos in categorias.items():
        real_cat = real.get(cat, set())
        for nombre, nums in modelos.items():
            hits = len(set(nums) & real_cat)
            resultados.append((cat, nombre, hits, nums))
            actualizar_stats(stats, cat, nombre, hits)

    save_stats(stats)
    resultados.sort(key=lambda r: -r[2])
    return resultados


def ranking(cat):
    """[(nombre, stats)] de la categoria, ordenado por promedio histórico de aciertos descendente."""
    stats = load_stats().get(cat, {})

    def promedio(m):
        return m['sum_hits'] / m['n'] if m['n'] else -1

    return sorted(stats.items(), key=lambda kv: -promedio(kv[1]))
