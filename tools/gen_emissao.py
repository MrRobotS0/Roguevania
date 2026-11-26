"""Mapas de emissão: o que brilha por conta própria em cada inimigo e chefe
(olhos, fogo, cristal, runas). Sai assets/sprites/<folha>_e.png, só com
esses pixels; o jogo desenha por cima do corpo sem a penumbra da fase e
somando luz, e o brilho da tela (glow) espalha. No escuro os olhos acendem.

    python tools/gen_emissao.py            todas as folhas de inimigo
    python tools/gen_emissao.py --previa   e uma prévia em build/previa_emissao.png

Um pixel emite quando é claro E mais claro que a vizinhança (um ponto de luz,
não uma armadura clara inteira). Se a folha acender demais (mais de LIMITE dos
pixels), o corte sobe até caber: o brilho tem que ser detalhe.
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SPR = os.path.join(ROOT, "assets", "sprites")
FORA = {"beira", "hero", "hero_g", "props"}
LIMITE = 0.045


def vizinhanca(v, a, r=3):
    """Média de v nos pixels opacos num quadrado (2r+1), por soma acumulada."""
    k = 2 * r + 1
    pv = np.pad(v * a, r)
    pa = np.pad(a.astype(np.float32), r)
    def caixa(x):
        c = x.cumsum(0).cumsum(1)
        c = np.pad(c, ((1, 0), (1, 0)))
        return c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]
    return caixa(pv) / np.maximum(caixa(pa), 1)


def emissao(rgba):
    rgb = rgba[:, :, :3].astype(np.float32) / 255
    a = rgba[:, :, 3] > 127
    v = rgb.max(2)
    s = np.where(v > 0, (v - rgb.min(2)) / np.maximum(v, 1e-6), 0)
    viz = vizinhanca(v, a)
    corte = 0.78
    while True:
        # luz colorida, ou branco só quando é um ponto isolado no escuro
        # (olho); o reflexo branco de armadura e pelo claro não acende
        m = a & (v >= corte) & (v - viz >= 0.16) & ((s >= 0.42) | ((v >= 0.97) & (v - viz >= 0.38)))
        if m.sum() <= LIMITE * max(a.sum(), 1) or corte >= 0.97:
            return m
        corte += 0.03


def main():
    previa = "--previa" in sys.argv
    tiras = []
    for js in sorted(glob.glob(os.path.join(SPR, "*.json"))):
        nome = os.path.basename(js)[:-5]
        if nome in FORA or nome.endswith("_e"):
            continue
        try:
            meta = json.load(open(js, encoding="utf-8"))
        except ValueError:
            continue
        if not isinstance(meta, dict) or "anims" not in meta or not meta.get("color"):
            continue
        rgba = np.array(Image.open(os.path.join(SPR, nome + ".png")).convert("RGBA"))
        m = emissao(rgba)
        destino = os.path.join(SPR, nome + "_e.png")
        if not m.any():
            # nada brilha: sem arquivo (o jogo só liga a emissão se ele existir)
            for f in (destino, destino + ".import"):
                if os.path.exists(f):
                    os.remove(f)
            continue
        out = np.zeros_like(rgba)
        out[m] = rgba[m]
        out[m, 3] = 255
        Image.fromarray(out).save(destino)
        print("%-18s %5d pixels de luz (%.1f%%)" % (nome, m.sum(), 100 * m.sum() / max((rgba[:, :, 3] > 127).sum(), 1)))
        if previa:
            fw, fh = int(meta.get("w", 32)), int(meta.get("h", 32))
            q = rgba[:fh, :fw * 2].astype(np.float32)
            e = out[:fh, :fw * 2].astype(np.float32)
            escuro = q.copy()
            escuro[:, :, :3] *= 0.35
            escuro[:, :, :3] += e[:, :, :3] * (e[:, :, 3:] / 255) * 1.2
            tiras.append(np.clip(np.concatenate([q, escuro], 1), 0, 255).astype(np.uint8))
    if previa and tiras:
        larg = max(t.shape[1] for t in tiras)
        alt = sum(t.shape[0] for t in tiras)
        tela = np.zeros((alt, larg, 4), np.uint8)
        tela[:, :] = (24, 20, 30, 255)
        y = 0
        for t in tiras:
            fundo = Image.fromarray(tela[y:y + t.shape[0], :t.shape[1]])
            fundo.alpha_composite(Image.fromarray(t))
            tela[y:y + t.shape[0], :t.shape[1]] = np.array(fundo)
            y += t.shape[0]
        os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
        Image.fromarray(tela).save(os.path.join(ROOT, "build", "previa_emissao.png"))


if __name__ == "__main__":
    main()
