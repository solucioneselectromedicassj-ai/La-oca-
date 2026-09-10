import re

from .loader import calc_dia, make_sorteo

SORTEO_LINE_RE = re.compile(r'sorteo\s*n?[°ºo]?\s*[:\-]?\s*(\d{1,4})\b', re.IGNORECASE)
SIXNUMS_RE = re.compile(
    r'\b(\d{1,2})\s*[-\s]\s*(\d{1,2})\s*[-\s]\s*(\d{1,2})\s*[-\s]\s*'
    r'(\d{1,2})\s*[-\s]\s*(\d{1,2})\s*[-\s]\s*(\d{1,2})\b'
)


def _six_num_groups(line):
    groups = []
    for m in SIXNUMS_RE.finditer(line):
        nums = [int(x) for x in m.groups()]
        if all(0 <= x <= 45 for x in nums) and len(set(nums)) == 6:
            groups.append(nums)
    return groups


def parse_pdf(path, debug=False):
    """
    Parsea el PDF historico del Quini 6 (best-effort).

    El layout exacto de "Quini6_Historico_Completo_Sorteo1_al_3398.pdf" no
    fue visto por este parser todavia. Usa --debug para volcar el texto
    crudo extraido de cada pagina y calibrar las expresiones regulares de
    este archivo si los resultados no coinciden con los sorteos conocidos.

    Devuelve un dict {numero_sorteo: sorteo_dict}.
    """
    import pdfplumber

    sorteos = {}
    current_n = None
    current_groups = []

    def flush():
        nonlocal current_n, current_groups
        if current_n is not None and len(current_groups) >= 3:
            trad, seg, rev = current_groups[0], current_groups[1], current_groups[2]
            ss = current_groups[3] if len(current_groups) >= 4 else []
            sorteos[current_n] = make_sorteo(current_n, calc_dia(current_n), trad, seg, rev, ss)
        current_n = None
        current_groups = []

    with pdfplumber.open(path) as pdf:
        for pageno, page in enumerate(pdf.pages):
            text = page.extract_text() or ''
            if debug:
                print(f'--- pagina {pageno} ---')
                print(text)
            for line in text.split('\n'):
                m = SORTEO_LINE_RE.search(line)
                if m:
                    flush()
                    current_n = int(m.group(1))
                current_groups.extend(_six_num_groups(line))
        flush()

    return sorteos
