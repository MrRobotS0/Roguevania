"""Efeitos em pixel art do pacote CC0 "Free Pixel Effects Pack" (CodeManu e
Davit Masia, OpenGameArt) viram tiras prontas para o jogo.

    python tools/baixar_arte.py free-pixel-effects-pack
    python tools/importar_efeitos.py

Cada folha original é uma grade de quadros 100x100. Aqui os quadros vazios
saem, tudo é recortado na caixa que cobre a animação inteira (com 1 px de
folga) e vira uma tira na horizontal: assets/sprites/vfx_<nome>.png, com o
tamanho do quadro e o número de quadros em vfx.json.
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "arte_externa", "free-pixel-effects-pack")
OUT = os.path.join(ROOT, "assets", "sprites")

# nome no jogo -> (folha do pacote, quadros por segundo)
EFEITOS = {
    # (o nome do arquivo original nem sempre diz o que o desenho mostra:
    # os nomes daqui são do que se vê)
    "golpe": ("10_weaponhit", 60),        # anel branco que abre (impacto)
    "alma": ("5_magickahit", 30),         # fio rosa e azul que sobe (essência saindo)
    "alma_azul": ("3_bluefire", 30),      # fio azul que sobe
    "tocha": ("9_brightfire", 14),        # chama pequena em pé (laço)
    "fogo": ("11_fire", 14),              # chama alta com fumaça (laço)
    "chama_roxa": ("18_midnight", 16),    # chama roxa (laço)
    "gelo": ("19_freezing", 30),          # anel de flocos
    "estrela": ("14_phantom", 30),        # estrela de quatro pontas (crítico)
    "veneno": ("17_felspell", 30),        # anel verde de esporos
    "vortice": ("13_vortex", 24),         # redemoinho vermelho
    "explosao": ("16_sunburn", 40),       # bola de fogo que estoura
    "estilhaco": ("12_nebula", 40),       # estouro azul e branco
    "circulo": ("8_protectioncircle", 24),
    "faiscas": ("6_flamelash", 45),       # arco de faíscas que se espalha
}


def quadros(folha):
    im = np.array(Image.open(os.path.join(SRC, folha + "_spritesheet.png")).convert("RGBA"))
    n = im.shape[1] // 100
    out = []
    for r in range(im.shape[0] // 100):
        for c in range(n):
            q = im[r * 100:(r + 1) * 100, c * 100:(c + 1) * 100]
            if (q[:, :, 3] > 0).sum() > 0:
                out.append(q)
    return out


def main():
    meta = {}
    for nome, (folha, fps) in EFEITOS.items():
        qs = quadros(folha)
        a = np.zeros((100, 100), bool)
        for q in qs:
            a |= q[:, :, 3] > 0
        ys, xs = np.nonzero(a)
        # recorte simétrico em volta do centro (o efeito nasce no meio do quadro)
        rx = max(50 - xs.min(), xs.max() + 1 - 50) + 1
        ry = max(50 - ys.min(), ys.max() + 1 - 50) + 1
        x0, x1, y0, y1 = max(0, 50 - rx), min(100, 50 + rx), max(0, 50 - ry), min(100, 50 + ry)
        w, h = x1 - x0, y1 - y0
        tira = np.zeros((h, w * len(qs), 4), np.uint8)
        for i, q in enumerate(qs):
            tira[:, i * w:(i + 1) * w] = q[y0:y1, x0:x1]
        Image.fromarray(tira).save(os.path.join(OUT, "vfx_%s.png" % nome))
        meta[nome] = {"w": int(w), "h": int(h), "frames": len(qs), "fps": fps}
        print("%-10s %2d quadros %3dx%-3d  (%s)" % (nome, len(qs), w, h, folha))
    with open(os.path.join(OUT, "vfx.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1, ensure_ascii=False)


if __name__ == "__main__":
    main()
