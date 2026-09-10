from data.loader import calc_fecha, fmt_nums

DIA_NOMBRE = {'D': 'Domingo', 'X': 'Miércoles'}


def generate_report_v4(target_n, dia_t, triples, dobles, boletos, cb, pool18, scores):
    fecha_t = calc_fecha(target_n)

    lines = [
        f'PROYECCIÓN {target_n} — {DIA_NOMBRE[dia_t]} {fecha_t.strftime("%d/%m/%Y")} (sistema v4)',
        '',
        f'SEÑALES: TRIPLE={fmt_nums(triples) if triples else "-"} | '
        f'DOBLE={fmt_nums(dobles) if dobles else "-"}',
        '',
        f'EXTRA POOL ({len(pool18)}): {fmt_nums(pool18)}',
        '',
        'BOLETOS:',
    ]
    for etiqueta, nums in boletos:
        lines.append(f'  {etiqueta}: {fmt_nums(nums)}')

    lines.append('')
    lines.append('5 COMBINACIONES (CB):')
    for i, c in enumerate(cb, 1):
        lines.append(f'  CB-{i}: {fmt_nums(c)}')

    lines.append('')
    lines.append('SCORES DESTACADOS:')
    ranked = sorted(range(len(scores)), key=lambda n: -scores[n])[:10]
    for n in ranked:
        marca = ''
        if n in triples:
            marca = ' ⚡⚡⚡ TRIPLE'
        elif n in dobles:
            marca = ' ⚡⚡ DOBLE'
        lines.append(f'  {n:02d}: {scores[n]:.2f}{marca}')

    return '\n'.join(lines)
