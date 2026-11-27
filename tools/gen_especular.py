#!/usr/bin/env python3
"""Mapa de brilho (especular) dos blocos dos domínios molhados, de gelo e de metal.

    python tools/gen_especular.py [id ...]

Com o relevo, a luz do herói, dos braseiros e dos clarões deixa um reflexo que
anda pelo chão: é o que faz gelo parecer gelo e carne parecer molhada. Só os
pixels mais claros de cada atlas refletem (a aresta polida, o veio, a gota); o
resto fica fosco, senão o bloco inteiro vira plástico.

Sai assets/sprites/tiles_<id>_s.png, em cinza. A cor e a abertura do reflexo de
cada domínio ficam no jogo (Depth.GLOSS), para afinar sem regerar.
"""
import os
import sys

import numpy as np
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
# domínio: (percentil onde o brilho começa, força)
DOMINIOS = {
    "saloes": (55, 1.0),          # gelo e mármore
    "catedral": (60, 0.8),        # pedra molhada
    "cavernas": (62, 0.8),        # rocha úmida
    "ventre": (50, 1.0),          # carne
    "observatorio": (65, 0.9),    # metal e cristal
    "forja_rubra": (70, 0.6),     # tijolo vitrificado pelo calor
}


def gerar(dominio: str) -> bool:
    origem = os.path.join(RAIZ, "tiles_%s.png" % dominio)
    if dominio not in DOMINIOS or not os.path.exists(origem):
        return False
    inicio, forca = DOMINIOS[dominio]
    a = np.asarray(Image.open(origem).convert("RGBA")).astype(np.float32)
    cheio = a[..., 3] >= 128
    lum = (a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114) / 255.0
    piso = np.percentile(lum[cheio], inicio)
    teto = max(np.percentile(lum[cheio], 99), piso + 0.02)
    brilho = np.clip((lum - piso) / (teto - piso), 0.0, 1.0) ** 1.5 * forca
    cinza = (brilho * 255.0).clip(0, 255).astype(np.uint8)
    out = np.dstack([cinza, cinza, cinza, np.where(cheio, 255, 0).astype(np.uint8)])
    Image.fromarray(out, "RGBA").save(os.path.join(RAIZ, "tiles_%s_s.png" % dominio))
    return True


def main() -> None:
    pedidos = [x for x in sys.argv[1:] if not x.startswith("-")] or list(DOMINIOS)
    feitos = [d for d in pedidos if gerar(d)]
    print("%d mapas de brilho: %s" % (len(feitos), ", ".join(feitos)))


if __name__ == "__main__":
    main()
