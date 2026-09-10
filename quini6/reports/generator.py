from data.loader import calc_dia, calc_fecha, fmt_nums

DIA_NOMBRE = {'D': 'Domingo', 'X': 'Miércoles'}


def generate_report(target_n, sorteos, models, ranking, pool16, pool20, poolC):
    prev = sorteos[-1]
    dia_t = calc_dia(target_n)
    fecha_t = calc_fecha(target_n)
    top6 = [r['numero'] for r in ranking[:6]]
    extra20 = [n for n in pool20 if n not in pool16]

    lines = [
        f'=== QUINI 6 — PROYECCIÓN SORTEO {target_n} '
        f'({DIA_NOMBRE[dia_t]} {fecha_t.strftime("%d/%m/%Y")}) ===',
        '',
        f'Último sorteo procesado: {prev["n"]} ({DIA_NOMBRE[prev["dia"]]} '
        f'{calc_fecha(prev["n"]).strftime("%d/%m/%Y")})',
        f'Trad: {fmt_nums(prev["trad"])} | Seg: {fmt_nums(prev["seg"])}',
        f'Rev:  {fmt_nums(prev["rev"])} | SS: {fmt_nums(prev["ss"])}',
        f'Extra: {fmt_nums(prev["extra"])}',
        '',
        f'Pool-16: {fmt_nums(pool16)}',
        f'Pool-20 (+): {fmt_nums(extra20)}',
        f'Pool-C: {fmt_nums(poolC)}',
        '',
        f'TOP-6 (mayor consenso): {fmt_nums(top6)}',
        '',
        'Ranking del pool (score descendente):',
        f'{"n":>3} {"votos":>6} {"señal":>6} {"p_rep":>6} {"calor":>6} {"score":>7}',
    ]
    for r in ranking:
        lines.append(
            f'{r["numero"]:02d} {r["votos"]:>6} {r["señal"]:>6} '
            f'{r["p_rep"]:>6.2f} {r["calor"]:>6} {r["score"]:>7.2f}'
        )
    lines.append('')
    lines.append('Modelos individuales:')
    for nombre, nums in sorted(models.items()):
        lines.append(f'  {nombre:<10} {fmt_nums(nums)}')

    return '\n'.join(lines)
