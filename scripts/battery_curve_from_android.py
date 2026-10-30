#!/usr/bin/env python3
"""battery_curve_from_android.py — extrai a curva SOC<->tensão do perfil de
bateria que o Android usa neste aparelho e emite uma `ocv-capacity-table-0`
pronta para o DT (Linux, power_supply_batinfo_ocv2cap).

Fonte: work/android-dump-*/dt-battery-profiles.dts (coleta read-only do
aparelho), bloco do pack 6000 mAh (ATL ou SUNWODA) e o LUT `pc-temp-v1-lut`,
que é o modelo da própria Motorola/Qualcomm: linhas = SOC em 0.01%, colunas =
temperatura, valores = tensão em 0.1 mV.

Uso:
    ./battery_curve_from_android.py [--temp 25] [--points 21] [--vmin 3400000]

O ponto de 0% do modelo (3.000 V) é um artefato do corte do algoritmo; o
padrão --vmin 3400000 usa o fim de descarga realista do pack.
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DEFAULT_DTS = REPO / 'work/android-dump-20261025/dt-battery-profiles.dts'
PROFILE_CANDIDATES = ('qcom,ATL466271_6000mAh {', 'qcom,SUNWODA466271_6000mAh {')


def load_block(path, marker):
    txt = path.read_text()
    try:
        start = txt.index(marker)
    except ValueError:
        return None
    nxt = [txt.find(m, start + 1) for m in PROFILE_CANDIDATES if txt.find(m, start + 1) > 0]
    end = min(nxt) if nxt else len(txt)
    return txt[start:end]


def lut_prop(block, name):
    m = re.search(r'qcom,' + name + r' \{(.*?)\n\t\t\t\};', block, re.S)
    if not m:
        raise SystemExit(f'LUT {name} não encontrada no perfil')
    body = m.group(1)

    def prop(p):
        mm = re.search(r'qcom,' + p + r' = <([^;]*)>;', body)
        return [int(v, 16) for v in mm.group(1).split()]

    return prop('lut-col-legend'), prop('lut-row-legend'), prop('lut-data')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dts', type=Path, default=DEFAULT_DTS)
    ap.add_argument('--temp', type=int, default=25, help='coluna de temperatura')
    ap.add_argument('--points', type=int, default=21)
    ap.add_argument('--vmin', type=int, default=3400000, help='tensão de 0%% em uV')
    args = ap.parse_args()

    for marker in PROFILE_CANDIDATES:
        block = load_block(args.dts, marker)
        if block:
            print(f'# perfil: {marker.rstrip(" {")}', file=sys.stderr)
            break
    else:
        raise SystemExit('nenhum perfil de 6000 mAh encontrado')

    cols, rows, data = lut_prop(block, 'pc-temp-v1-lut')
    if args.temp not in cols:
        raise SystemExit(f'temperatura {args.temp} não está nas colunas {cols}')
    col = cols.index(args.temp)
    ncol = len(cols)
    curve = [(rows[r] / 100.0, data[r * ncol + col] / 10000.0) for r in range(len(rows))]

    step = 100 // (args.points - 1)
    targets = [100 - i * step for i in range(args.points)]

    out = []
    for t in targets:
        soc, v = min(curve, key=lambda p: abs(p[0] - t))
        uv = int(round(v * 1e6))
        if t == 0:
            uv = args.vmin
        out.append((uv, t))

    # o kernel exige tabela ordenada: OCV decrescente e capacidade decrescente
    out.sort(key=lambda p: -p[0])
    assert all(out[i][0] > out[i + 1][0] for i in range(len(out) - 1)), 'OCV não monotônica'

    print(f'\t\t\tocv-capacity-celsius = <{args.temp}>;')
    print('\t\t\tocv-capacity-table-0 = ', end='')
    for i, (uv, soc) in enumerate(out):
        sep = ';' if i == len(out) - 1 else ','
        print(f'<{uv} {soc}>{sep}', end='\n\t\t\t\t      ' if i % 2 == 1 and i != len(out) - 1 else ' ')


if __name__ == '__main__':
    main()
