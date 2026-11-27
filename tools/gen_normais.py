"""Mapas de relevo (normal maps) para a luz 2D dar volume à pixel art.

Para cada folha em assets/sprites/ grava <nome>_n.png, no mesmo tamanho:
o jogo junta as duas num CanvasTexture e as luzes (PointLight2D e a luz
do domínio) passam a acender um lado e sombrear o outro.

A altura de cada pixel sai do próprio desenho:
  - forma: distância até a borda transparente, arredondada (o corpo abaula);
  - detalhe: a luminância (o claro salta, o escuro afunda).
Blocos do chão: cada célula de 16 px abaula só nos lados abertos (a
máscara da linha do atlas diz quais), e a textura da pedra vira detalhe.

O alfa não é usado pela luz (o Godot lê só vermelho e verde), então nas folhas
de personagem ele guarda a borda de fora de cada quadro, para a linha de luz do
contorno (shaders/personagem.gdshader): 128 + 16 se o pixel é o primeiro da
linha pela esquerda, + 32 pela direita, + 64 se é o primeiro da coluna por cima.

    python tools/gen_normais.py            # todas
    python tools/gen_normais.py wolf hero  # só estas

Rodar de novo depois de importar arte nova (importar_inimigos.py etc.).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

RAIZ = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
TILE = 16
# fundo, HUD, ícones: ficam sem relevo (longe demais ou fora do mundo)
FORA = ("bd", "hud_", "icon", "font")


def distancia_borda(alfa: np.ndarray, raio: int) -> np.ndarray:
    """Quantos pixels até o transparente mais perto (teto em `raio`)."""
    d = np.zeros(alfa.shape, np.float32)
    atual = alfa.copy()
    for i in range(1, raio + 1):
        d[atual] = i
        p = np.pad(atual, 1, constant_values=False)
        atual = p[1:-1, 1:-1] & p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
    return d


def luminancia(rgb: np.ndarray) -> np.ndarray:
    return (rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114) / 255.0


def normais(altura: np.ndarray, alfa: np.ndarray, forca: float) -> np.ndarray:
    """Altura -> normal em RGB (convenção OpenGL: verde = para cima)."""
    h = np.pad(altura, 1, mode="edge")
    dx = (h[1:-1, 2:] - h[1:-1, :-2]) * 0.5
    dy = (h[2:, 1:-1] - h[:-2, 1:-1]) * 0.5
    nx = -dx * forca
    ny = dy * forca          # imagem cresce para baixo; a normal "para cima" é +y
    nz = np.ones_like(nx)
    n = np.sqrt(nx * nx + ny * ny + nz * nz)
    out = np.stack([nx / n, ny / n, nz / n], axis=-1)
    rgb = ((out * 0.5 + 0.5) * 255.0).round().clip(0, 255).astype(np.uint8)
    rgb[~alfa] = (128, 128, 255)
    a = np.where(alfa, 255, 0).astype(np.uint8)
    return np.dstack([rgb, a])


def suavizar(x: np.ndarray) -> np.ndarray:
    p = np.pad(x, 1, mode="edge")
    return (p[1:-1, 1:-1] * 4 + p[:-2, 1:-1] + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:]) / 8.0


def borda_de_fora(alfa: np.ndarray, fw: int, fh: int) -> np.ndarray:
    """Alfa codificado: quem é o primeiro pixel do quadro visto da esquerda, da direita e de cima."""
    out = np.where(alfa, 128, 0).astype(np.uint8)
    for y0 in range(0, alfa.shape[0] - fh + 1, fh):
        for x0 in range(0, alfa.shape[1] - fw + 1, fw):
            cel = alfa[y0:y0 + fh, x0:x0 + fw]
            if not cel.any():
                continue
            esq = cel & (np.cumsum(cel, axis=1) == 1)
            dir_ = cel & (np.cumsum(cel[:, ::-1], axis=1)[:, ::-1] == 1)
            cima = cel & (np.cumsum(cel, axis=0) == 1)
            out[y0:y0 + fh, x0:x0 + fw] += (esq * 16 + dir_ * 32 + cima * 64).astype(np.uint8)
    return out


def personagem(img: Image.Image, colorida: bool, tamanho: int, quadro=None) -> np.ndarray:
    a = np.asarray(img.convert("RGBA"))
    alfa = a[..., 3] >= 128
    # corpo grande abaula mais devagar (um chefe de 128 px não é uma moeda)
    raio = int(np.clip(tamanho / 14, 2, 6))
    d = distancia_borda(alfa, raio) / raio
    forma = np.sqrt(np.clip(d, 0, 1))           # perfil redondo, não chanfro reto
    if colorida:
        det = suavizar(luminancia(a[..., :3].astype(np.float32)))
        altura = forma * 0.65 + det * 0.55
    else:
        # folha indexada: o vermelho é o índice da paleta, não a luz
        altura = forma
    out = normais(altura * raio, alfa, 2.6)
    if quadro:
        out[..., 3] = borda_de_fora(alfa, quadro[0], quadro[1])
    return out


def blocos(img: Image.Image) -> np.ndarray:
    a = np.asarray(img.convert("RGBA"))
    alfa = a[..., 3] >= 128
    lum = luminancia(a[..., :3].astype(np.float32))
    altura = np.zeros(alfa.shape, np.float32)
    linhas, colunas = alfa.shape[0] // TILE, alfa.shape[1] // TILE
    yy, xx = np.mgrid[0:TILE, 0:TILE].astype(np.float32)
    for r in range(linhas):
        mascara = r if r < 16 else (0 if r == 16 else 5)   # 16 = enterrado, 17 = tábua (aberta em cima e embaixo)
        aberto = {"cima": mascara & 1, "dir": mascara & 2, "baixo": mascara & 4, "esq": mascara & 8}
        # distância até cada lado aberto (lado fechado continua no vizinho)
        dist = np.full((TILE, TILE), 99.0, np.float32)
        if aberto["cima"]:
            dist = np.minimum(dist, yy)
        if aberto["baixo"]:
            dist = np.minimum(dist, TILE - 1 - yy)
        if aberto["esq"]:
            dist = np.minimum(dist, xx)
        if aberto["dir"]:
            dist = np.minimum(dist, TILE - 1 - xx)
        bisel = np.sqrt(np.clip(dist / 4.0, 0, 1))
        for c in range(colunas):
            ys, xs = slice(r * TILE, (r + 1) * TILE), slice(c * TILE, (c + 1) * TILE)
            altura[ys, xs] = bisel * 3.0 + suavizar(lum[ys, xs]) * 2.2
    return normais(altura, alfa, 2.3)


def processar(nome: str) -> bool:
    png = os.path.join(RAIZ, nome + ".png")
    if not os.path.exists(png) or nome.endswith("_n") or nome.startswith(FORA):
        return False
    img = Image.open(png)
    meta_path = os.path.join(RAIZ, nome + ".json")
    if nome.startswith("tiles"):
        out = blocos(img)
    elif os.path.exists(meta_path):
        m = json.load(open(meta_path, encoding="utf-8"))
        fw, fh = int(m.get("w", m.get("size", 32))), int(m.get("h", m.get("size", 32)))
        # só folha em grade de quadros (com animações) tem borda de fora por quadro
        out = personagem(img, bool(m.get("color", False)), max(fw, fh), (fw, fh) if "anims" in m else None)
    elif nome == "props":
        out = personagem(img, True, 32)
    else:
        return False
    Image.fromarray(out, "RGBA").save(os.path.join(RAIZ, nome + "_n.png"))
    return True


def main() -> None:
    nomes = sys.argv[1:] or sorted(f[:-4] for f in os.listdir(RAIZ) if f.endswith(".png"))
    feitos = [n for n in nomes if processar(n)]
    print(f"{len(feitos)} mapas de relevo gravados")


if __name__ == "__main__":
    main()
