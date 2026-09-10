#!/usr/bin/env python3
"""
Quini 6 - App web local.
Uso: python webapp.py [--port 8000]
Abrí http://localhost:8000 en el navegador.
"""
import argparse
import html
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

sys.path.insert(0, os.path.dirname(__file__))

import engine
import tracking.store as tracking
from data.loader import DATASET_PATH, calc_dia, calc_fecha, load_dataset, parse_nums

DIA_NOMBRE = {'D': 'Domingo', 'X': 'Miércoles'}
CAT_NOMBRE = {
    'trad': 'Tradicional', 'seg': 'La Segunda', 'rev': 'Revancha',
    'ss': 'Siempre Sale', 'extra': 'Extra Pool',
}
ORDEN_CATS = ['trad', 'seg', 'rev', 'ss', 'extra']

STYLE = """
body{font-family:-apple-system,system-ui,sans-serif;max-width:900px;margin:20px auto;padding:0 16px;
     background:#0f1117;color:#e4e6eb;}
h1{color:#8ab4f8;} h2{color:#8ab4f8;border-bottom:1px solid #333;padding-bottom:4px;margin-top:28px;}
.card{background:#1b1e27;border-radius:10px;padding:16px 18px;margin:14px 0;}
input{background:#0f1117;color:#e4e6eb;border:1px solid #444;border-radius:6px;padding:8px;
      font-family:monospace;width:100%;box-sizing:border-box;}
label{display:block;margin:10px 0 4px;font-size:13px;color:#aaa;}
button{background:#8ab4f8;color:#0f1117;border:none;border-radius:6px;padding:10px 20px;
       font-weight:600;cursor:pointer;margin-top:16px;}
button:hover{background:#a9c8fa;}
table{width:100%;border-collapse:collapse;margin:8px 0;font-size:13px;}
th,td{text-align:left;padding:5px 8px;border-bottom:1px solid #2a2d38;}
th{color:#888;font-weight:600;}
.nums{font-family:monospace;letter-spacing:0.5px;}
.hits-alta{color:#7ee787;font-weight:700;} .hits-media{color:#e3b341;} .hits-baja{color:#888;}
.hist{color:#888;font-size:11px;}
.pill{display:inline-block;background:#2a2d38;border-radius:12px;padding:2px 10px;font-size:12px;margin-right:6px;}
.row{display:flex;gap:10px;flex-wrap:wrap;}
.row > div{flex:1;min-width:140px;}
</style>
"""


def fmt_nums(nums):
    return '-'.join(f'{n:02d}' for n in sorted(nums))


def hits_class(hits):
    if hits >= 4:
        return 'hits-alta'
    if hits >= 2:
        return 'hits-media'
    return 'hits-baja'


def render_evaluacion(evaluacion, nuevo):
    if not evaluacion:
        return (f'<div class="card"><em>No había proyección guardada para el sorteo '
                f'{nuevo["n"]} (probablemente es el primer sorteo cargado en esta app).</em></div>')
    rows = ''.join(
        f'<tr><td>{html.escape(CAT_NOMBRE.get(cat, cat))}</td><td>{html.escape(nombre)}</td>'
        f'<td class="{hits_class(hits)}">{hits}/6</td><td class="nums">{fmt_nums(nums)}</td></tr>'
        for cat, nombre, hits, nums in evaluacion
    )
    return f"""
    <div class="card">
      <h2 style="margin-top:0;border:none;">Evaluación sorteo {nuevo['n']} vs. proyección guardada</h2>
      <table>
        <tr><th>Sección</th><th>Modelo</th><th>Aciertos</th><th>Predijo</th></tr>
        {rows}
      </table>
    </div>
    """


def render_proyeccion(result):
    target_n = result['target_n']
    fecha_t = calc_fecha(target_n)
    partes = [f"""
    <div class="card">
      <h2 style="margin-top:0;border:none;">Proyección sorteo {target_n}
        ({DIA_NOMBRE[result['target_dia']]} {fecha_t.strftime('%d/%m/%Y')})</h2>
      <span class="pill">Pool-16: <span class="nums">{fmt_nums(result['pool16'])}</span></span>
      <span class="pill">Pool-20: <span class="nums">{fmt_nums(result['pool20'])}</span></span>
      <span class="pill">Pool-C: <span class="nums">{fmt_nums(result['poolC'])}</span></span>
    </div>
    """]

    for cat in ORDEN_CATS:
        modelos = result['categorias'].get(cat, {})
        if not modelos:
            continue
        rank = dict(tracking.ranking(cat))
        orden_nombres = [nombre for nombre, _ in tracking.ranking(cat)]
        ordenados = sorted(
            modelos.items(),
            key=lambda kv: orden_nombres.index(kv[0]) if kv[0] in orden_nombres else 999,
        )
        rows = ''
        for nombre, nums in ordenados:
            st = rank.get(nombre)
            if st and st['n']:
                prom = st['sum_hits'] / st['n']
                hist = f'{prom:.2f} prom/6 · {st["n"]} sorteos · {st["veces_4mas"]}x con 4+'
            else:
                hist = 'sin historial'
            rows += (f'<tr><td>{html.escape(nombre)}</td><td class="nums">{fmt_nums(nums)}</td>'
                     f'<td class="hist">{html.escape(hist)}</td></tr>')
        partes.append(f"""
        <div class="card">
          <h2 style="margin-top:0;border:none;">{CAT_NOMBRE[cat]}</h2>
          <table>
            <tr><th>Modelo</th><th>Números</th><th>Historial</th></tr>
            {rows}
          </table>
        </div>
        """)
    return ''.join(partes)


def render_form(target_n_sugerido, dia_sugerido):
    return f"""
    <div class="card">
      <h2 style="margin-top:0;border:none;">Cargar resultado de sorteo</h2>
      <form method="POST" action="/">
        <div class="row">
          <div><label>Sorteo N°</label><input name="sorteo" value="{target_n_sugerido}" required></div>
          <div><label>Día (D=Domingo, X=Miércoles; vacío = automático)</label>
               <input name="dia" value="{dia_sugerido}" placeholder="D o X"></div>
        </div>
        <label>Tradicional (6 números, ej: 10-19-22-29-36-43)</label>
        <input name="t" placeholder="00-00-00-00-00-00" required>
        <label>La Segunda</label>
        <input name="s" placeholder="00-00-00-00-00-00" required>
        <label>Revancha</label>
        <input name="r" placeholder="00-00-00-00-00-00" required>
        <label>Siempre Sale</label>
        <input name="ss" placeholder="00-00-00-00-00-00" required>
        <button type="submit">Procesar sorteo</button>
      </form>
    </div>
    """


def render_page(body, mensaje_error=None):
    error_html = f'<div class="card" style="border:1px solid #f85149;color:#f85149;">{html.escape(mensaje_error)}</div>' if mensaje_error else ''
    return f"""<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8">
<title>Quini 6</title>
<style>{STYLE}</head>
<body>
<h1>Quini 6 — Sistema de análisis estadístico</h1>
{error_html}
{body}
</body></html>"""


def estado_dataset():
    sorteos = load_dataset(DATASET_PATH)
    if not sorteos:
        return None
    return sorteos[-1]


class Handler(BaseHTTPRequestHandler):
    def _send_html(self, content, status=200):
        body = content.encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path != '/':
            self._send_html(render_page('<p>404</p>'), status=404)
            return
        ultimo = estado_dataset()
        if not ultimo:
            self._send_html(render_page(
                '<div class="card">Dataset vacío. Corré <code>python main.py --build-dataset</code> '
                'antes de usar la app.</div>'))
            return
        target_n = ultimo['n'] + 1
        dia_sugerido = 'D' if ultimo['dia'] == 'X' else 'X'
        estado = (f'<div class="card">Último sorteo en el dataset: <b>{ultimo["n"]}</b> '
                  f'({DIA_NOMBRE[ultimo["dia"]]}). Cargá el resultado del sorteo <b>{target_n}</b> '
                  f'cuando salga.</div>')
        self._send_html(render_page(estado + render_form(target_n, dia_sugerido)))

    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8')
        form = {k: v[0] for k, v in parse_qs(body).items()}

        try:
            n = int(form.get('sorteo', ''))
        except ValueError:
            self._send_html(render_page(render_form('', ''), 'Número de sorteo inválido.'))
            return

        dia = (form.get('dia') or '').strip().upper() or None
        if dia not in (None, 'D', 'X'):
            self._send_html(render_page(render_form(n, ''), 'Día inválido: usá D o X (o dejalo vacío).'))
            return

        try:
            trad, seg, rev, ss = (parse_nums(form.get(k, '')) for k in ('t', 's', 'r', 'ss'))
        except ValueError:
            self._send_html(render_page(render_form(n, dia or ''),
                             'Formato inválido: usá números de 2 cifras separados por guion.'))
            return

        for nombre, nums in [('Tradicional', trad), ('La Segunda', seg), ('Revancha', rev), ('Siempre Sale', ss)]:
            if len(nums) != 6:
                self._send_html(render_page(render_form(n, dia or ''),
                                 f'{nombre} debe tener 6 números, recibí {len(nums)}.'))
                return

        try:
            result = engine.process_sorteo(DATASET_PATH, n, dia, trad, seg, rev, ss)
        except Exception as e:
            self._send_html(render_page(render_form(n, dia or ''), f'Error procesando el sorteo: {e}'))
            return

        body_html = (render_evaluacion(result['evaluacion'], result['nuevo']) +
                     render_proyeccion(result) +
                     render_form(result['target_n'], result['target_dia']))
        self._send_html(render_page(body_html))

    def log_message(self, fmt, *args):
        sys.stderr.write('%s - %s\n' % (self.address_string(), fmt % args))


def main():
    # En plataformas tipo Render, el puerto a escuchar viene en $PORT y hay que
    # atender en 0.0.0.0; localmente seguimos usando localhost por defecto.
    default_port = int(os.environ.get('PORT', 8000))
    default_host = os.environ.get('HOST', '0.0.0.0' if 'PORT' in os.environ else '127.0.0.1')

    parser = argparse.ArgumentParser(description='Quini 6 - App web')
    parser.add_argument('--port', type=int, default=default_port)
    parser.add_argument('--host', default=default_host)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f'Quini 6 corriendo en http://{args.host}:{args.port}  (Ctrl+C para salir)')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
