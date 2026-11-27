#!/usr/bin/env python3
"""Parede de fundo de cada domínio, tirada do próprio atlas de blocos.

    python tools/gen_paredes.py [id ...]

A parede é a pedra enterrada do domínio (linha 16 de tiles_<id>.png) com menos
contraste e a beira quebrada: nos lados abertos o bloco perde de 1 a 5 px em
degraus, com um fio escuro no corte. Sai um atlas com as mesmas 16 máscaras de
vizinhança dos blocos (linha = máscara: 1 aberto em cima, 2 à direita, 4
embaixo, 8 à esquerda) e 4 variações por linha:

    assets/sprites/parede_<id>.png

O tom (mais escuro, menos cor) é dado no jogo, em BackWall e no shader da
parede, para ser afinado sem regerar. Depois de rodar este, rode
`python tools/gen_normais.py parede_<id>` para o relevo.
"""
import glob
import os
import random
import sys

import numpy as np
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
TILE = 16
LINHA_ENTERRADA = 16
ROCHA = [0, 3, 4, 5, 6, 7]      # na linha enterrada, 1 e 2 são osso e veio de vidro
VARIACOES = 4
CONTRASTE = 0.72
FIO = 0.5                       # o pixel do corte fica com metade da luz


def perfil(rng: random.Random) -> np.ndarray:
    """Quanto a beira perde em cada pixel do lado aberto, em degraus."""
    out: list[int] = []
    while len(out) < TILE:
        out += [rng.choice([1, 1, 2, 2, 3, 3, 4, 5])] * rng.choice([2, 2, 3, 4])
    p = np.array(out[:TILE])
    # as pontas sempre com 2: o degrau continua de um bloco para o vizinho
    p[:2] = 2
    p[-2:] = 2
    return p


def bloco(base: np.ndarray, mascara: int, rng: random.Random) -> np.ndarray:
    t = base.astype(np.float32).copy()
    media = t[..., :3].reshape(-1, 3).mean(0)
    t[..., :3] = media + (t[..., :3] - media) * CONTRASTE
    cheio = np.ones((TILE, TILE), bool)
    yy, xx = np.mgrid[0:TILE, 0:TILE]
    if mascara & 1:
        cheio &= yy >= perfil(rng)[None, :]
    if mascara & 4:
        cheio &= yy <= TILE - 1 - perfil(rng)[None, :]
    if mascara & 8:
        cheio &= xx >= perfil(rng)[:, None]
    if mascara & 2:
        cheio &= xx <= TILE - 1 - perfil(rng)[:, None]
    # quina lascada onde dois lados abertos se encontram
    for a, b, cx, cy in ((1, 8, 0, 0), (1, 2, TILE - 1, 0), (4, 8, 0, TILE - 1), (4, 2, TILE - 1, TILE - 1)):
        if mascara & a and mascara & b:
            cheio &= (np.abs(xx - cx) + np.abs(yy - cy)) >= 6 + rng.randrange(3)
    # o fio do corte; o vizinho do lado fechado continua a parede, não conta
    pad = np.pad(cheio, 1, constant_values=True)
    cercado = pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
    t[cheio & ~cercado, :3] *= FIO
    t[..., 3] = np.where(cheio, 255, 0)
    return t.clip(0, 255).astype(np.uint8)


def gerar(dominio: str) -> bool:
    origem = os.path.join(RAIZ, "tiles_%s.png" % dominio)
    if not os.path.exists(origem):
        return False
    atlas = np.asarray(Image.open(origem).convert("RGBA"))
    y0 = LINHA_ENTERRADA * TILE
    if atlas.shape[0] < y0 + TILE:
        return False
    rocha = [atlas[y0:y0 + TILE, c * TILE:(c + 1) * TILE] for c in ROCHA if (c + 1) * TILE <= atlas.shape[1]]
    rng = random.Random(dominio)
    out = np.zeros((16 * TILE, VARIACOES * TILE, 4), np.uint8)
    for mascara in range(16):
        for v in range(VARIACOES):
            base = rocha[(mascara * 3 + v) % len(rocha)]
            out[mascara * TILE:(mascara + 1) * TILE, v * TILE:(v + 1) * TILE] = bloco(base, mascara, rng)
    Image.fromarray(out, "RGBA").save(os.path.join(RAIZ, "parede_%s.png" % dominio))
    return True


def main() -> None:
    pedidos = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not pedidos:
        for p in sorted(glob.glob(os.path.join(RAIZ, "tiles_*.png"))):
            nome = os.path.basename(p)[6:-4]
            if nome not in ("n", "e", "s") and not nome.endswith(("_n", "_e", "_s")):
                pedidos.append(nome)
    feitos = [d for d in pedidos if gerar(d)]
    print("%d paredes: %s" % (len(feitos), ", ".join(feitos)))


if __name__ == "__main__":
    main()
