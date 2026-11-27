#!/usr/bin/env python3
"""O que emite luz nos blocos dos domínios quentes: metal em brasa e carne que
pulsa.

    python tools/gen_emissivo.py [id ...]

Separa do atlas de blocos só os pixels muito claros e de cor viva e grava
assets/sprites/tiles_<id>_e.png. O jogo soma esse desenho por cima dos blocos,
pulsando devagar (Room.draw_emissive, shaders/blocos_brasa.gdshader); como
passa do limiar do brilho, ganha halo.

Só entram os domínios listados aqui: capim amarelo e musgo verde também são
claros e vivos, e não emitem luz.
"""
import os
import sys

import numpy as np
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
# domínio: (valor mínimo, saturação mínima) do pixel que emite
DOMINIOS = {
    "forja_rubra": (0.62, 0.7),
    "ventre": (0.8, 0.45),
}


def gerar(dominio: str) -> bool:
    origem = os.path.join(RAIZ, "tiles_%s.png" % dominio)
    if dominio not in DOMINIOS or not os.path.exists(origem):
        return False
    v0, s0 = DOMINIOS[dominio]
    a = np.asarray(Image.open(origem).convert("RGBA")).astype(np.float32) / 255.0
    rgb = a[..., :3]
    maior = rgb.max(-1)
    menor = rgb.min(-1)
    sat = np.where(maior > 0.01, (maior - menor) / np.maximum(maior, 1e-4), 0.0)
    forca = np.clip((maior - v0) / max(1.0 - v0, 1e-4), 0.0, 1.0) * (sat >= s0) * (a[..., 3] >= 0.5)
    out = np.dstack([rgb, forca])
    out[forca <= 0.0] = 0.0
    Image.fromarray((out * 255.0).round().astype(np.uint8), "RGBA").save(os.path.join(RAIZ, "tiles_%s_e.png" % dominio))
    print("  %s: %.1f%% dos pixels emitem" % (dominio, 100.0 * (forca > 0).sum() / max((a[..., 3] >= 0.5).sum(), 1)))
    return True


def main() -> None:
    pedidos = [x for x in sys.argv[1:] if not x.startswith("-")] or list(DOMINIOS)
    feitos = [d for d in pedidos if gerar(d)]
    print("%d mapas de emissão: %s" % (len(feitos), ", ".join(feitos)))


if __name__ == "__main__":
    main()
