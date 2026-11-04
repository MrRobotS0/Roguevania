"""Blocos do chão de cada domínio a partir dos tilesets Gothicvania (ansimuz, CC0).

    python tools/importar_blocos.py     (depois de tools/baixar_arte.py)

Os tilesets vêm em peças grandes, não numa grade de autotile. Então cada
domínio escolhe um bloco inteiro do tileset (com superfície em cima) e ele é
lido como 9 fatias de 16 px: um bloco do jogo com o lado de cima aberto pega a
faixa de cima da arte; com o lado esquerdo aberto, a borda esquerda; enterrado,
o miolo. Assim a borda desenhada pelo artista vira a borda do bloco no jogo.

Grava assets/sprites/tiles_<domínio>.png no mesmo formato do atlas antigo
(tools/gen_tiles.py): linhas 0-15 = máscara dos lados abertos (1 cima, 2
direita, 4 baixo, 8 esquerda) x 4 variações; linha 16 = 8 blocos enterrados;
linha 17 = 4 tábuas de plataforma.
"""
import colorsys
import glob
import os

from PIL import Image, ImageEnhance

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "arte_externa")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(ROOT, "tools", "previews")
T = 16

# domínio: (tileset, bloco x, y, w, h, matiz a girar em graus, saturação,
#           altura da superfície — o miolo é lido abaixo dela —, brilho)
SETS = {
    "mar_de_cinzas": ("gothicvania-rocky-pass-environment/**/PNG/tileset.png", (48, 16, 32, 64), 0, 1.0, 14, 1.0),
    "saloes": ("fort-of-illusion/**/Layers/tileset.png", (48, 48, 96, 60), 0, 1.0, 8, 1.0),
    "forja_rubra": ("gothicvania-patreons-collection/**/Gothic-Castle-Files/PNG/layers/gothic-castle-tileset.png", (32, 32, 32, 32), -50, 1.4, 6, 1.0),
    "torre_babel": ("gothicvania-church-pack/**/ENVIRONMENT/tileset.png", (0, 151, 48, 40), 120, 0.55, 8, 0.72),
    "jardim_primordial": ("gotthicvania-swamp/**/Evironment/tileset.png", (32, 4, 76, 56), 0, 1.0, 18, 1.0),
    "carcosa": ("gothicvania-cemetery-pack/**/PNG/Environment/tileset.png", (64, 56, 64, 40), -20, 1.1, 16, 1.0),
    "observatorio": ("gothicvania-junk-wasteland-environment/**/layers/tileset.png", (64, 0, 32, 62), 0, 1.0, 20, 1.0),
}


def find(pattern):
    hits = [f for f in glob.glob(os.path.join(ART, pattern), recursive=True) if not os.path.basename(f).startswith("._")]
    if not hits:
        raise SystemExit("não achei: " + pattern)
    return Image.open(hits[0]).convert("RGBA")


def shift(im, degrees, sat, bright=1.0):
    if degrees == 0 and sat == 1.0 and bright == 1.0:
        return im
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h + degrees / 360.0) % 1.0
            s = min(1.0, s * sat)
            v = min(1.0, v * bright)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return im


def solid_fill(block):
    """Pixels transparentes no meio do bloco (furos da arte) viram a cor média,
    para o bloco do jogo não ficar vazado onde a colisão é cheia."""
    out = block.copy()
    px = out.load()
    w, h = out.size
    opaque = [px[x, y] for y in range(h) for x in range(w) if px[x, y][3] > 200]
    dark = sorted(opaque, key=lambda c: c[0] + c[1] + c[2])[len(opaque) // 4]
    return out, dark


def spans(n, open_lo, open_hi, variant, skip=0):
    """Fatias de origem (início, largura, destino) num eixo de tamanho n para
    um bloco de 16: borda baixa, borda alta, ou miolo deslocado pela variação."""
    if open_lo and open_hi:
        return [(0, T // 2, 0), (n - T // 2, T // 2, T // 2)]
    if open_lo:
        return [(0, T, 0)]
    if open_hi:
        return [(n - T, T, 0)]
    lo, hi = (max(T // 2, skip), n - T // 2) if n >= 2 * T else (min(skip, max(0, n - T)), n)
    if hi - lo < T:
        lo = max(0, hi - T)
    room = max(1, hi - lo - T + 1)
    return [(lo + (variant * 7) % room, T, 0)] if hi - lo >= T else [(max(0, (n - T) // 2), T, 0)]


def cut(block, xs, ys, fill):
    tile = Image.new("RGBA", (T, T), fill)
    for sx, sw, dx in xs:
        for sy, sh, dy in ys:
            piece = block.crop((sx, sy, sx + sw, sy + sh))
            tile.alpha_composite(piece, (dx, dy))
    return tile


def edge_alpha(tile, mask):
    """Nos lados fechados o bloco tem que ser cheio: tira a transparência que a
    borda da arte trouxe para dentro (só nos lados que encostam em outro bloco)."""
    px = tile.load()
    for y in range(T):
        for x in range(T):
            r, g, b, a = px[x, y]
            near_open = (mask & 1 and y < 6) or (mask & 4 and y > 9) or (mask & 8 and x < 6) or (mask & 2 and x > 9)
            if a < 255 and not near_open:
                px[x, y] = (r, g, b, 255) if a > 0 else (0, 0, 0, 0)
    return tile


def build(dom, spec):
    path, (bx, by, bw, bh), hue, sat, cap, bright = spec
    sheet = shift(find(path), hue, sat, bright)
    block = sheet.crop((bx, by, bx + bw, by + bh))
    block, dark = solid_fill(block)
    atlas = Image.new("RGBA", (8 * T, 18 * T), (0, 0, 0, 0))
    for mask in range(16):
        up, right, down, left = mask & 1, mask & 2, mask & 4, mask & 8
        for v in range(4):
            xs = spans(bw, left, right, v)
            ys = spans(bh, up, down, v + 1, cap)
            base = cut(block, spans(bw, False, False, v), spans(bh, False, False, v + 2, cap), dark)
            tile = cut(block, xs, ys, (0, 0, 0, 0))
            base.alpha_composite(tile)
            # o que era transparente na borda aberta continua aberto
            px, tp = base.load(), tile.load()
            for y in range(T):
                for x in range(T):
                    if tp[x, y][3] == 0 and ((up and y < 8) or (down and y > 7) or (left and x < 8) or (right and x > 7)):
                        px[x, y] = (0, 0, 0, 0)
            atlas.alpha_composite(base, (v * T, mask * T))
    # enterrados: só miolo, 8 recortes diferentes
    for v in range(8):
        tile = cut(block, spans(bw, False, False, v * 3), spans(bh, False, False, v * 5 + 1, cap), dark)
        atlas.alpha_composite(tile, (v * T, 16 * T))
    # tábuas: a faixa de cima do bloco (8 px) com sombra embaixo
    for v in range(4):
        top = cut(block, spans(bw, False, False, v), [(0, 8, 0)], (0, 0, 0, 0))
        plank = Image.new("RGBA", (T, T), (0, 0, 0, 0))
        plank.alpha_composite(top.crop((0, 0, T, 8)), (0, 0))
        shade = ImageEnhance.Brightness(top.crop((0, 6, T, 8))).enhance(0.45)
        plank.alpha_composite(shade, (0, 8))
        atlas.alpha_composite(plank, (v * T, 17 * T))
    atlas.save(os.path.join(OUT, "tiles_%s.png" % dom))
    return atlas


ROOM = [
    "..............................",
    "..............................",
    "...........######.............",
    "...........######......====...",
    "..............................",
    ".....####.............#####...",
    "##...####......===....#####...",
    "##.......................##..#",
    "##########......##########...#",
    "##########......##########...#",
    "#############################.",
    "##############################",
]


def preview(dom, atlas):
    """Uma sala de teste montada com a mesma conta do jogo (Room._draw_stone)."""
    rows, cols = len(ROOM), len(ROOM[0])
    img = Image.new("RGBA", (cols * T, rows * T), (24, 22, 30, 255))

    def solid(x, y):
        return 0 <= y < rows and 0 <= x < cols and ROOM[y][x] == "#"

    for y in range(rows):
        for x in range(cols):
            hv = ((x * 73856093) ^ (y * 19349663)) & 0xff
            ch = ROOM[y][x]
            if ch == "=":
                img.alpha_composite(atlas.crop((hv % 4 * T, 17 * T, hv % 4 * T + T, 18 * T)), (x * T, y * T))
            if ch != "#":
                continue
            mask = (0 if solid(x, y - 1) else 1) | (0 if solid(x + 1, y) else 2) | (0 if solid(x, y + 1) else 4) | (0 if solid(x - 1, y) else 8)
            buried = mask == 0 and all(solid(x + a, y + b) for a in (-1, 1) for b in (-1, 1))
            if buried:
                src = (hv % 8 * T, 16 * T)
            else:
                src = (hv % 4 * T, mask * T)
            img.alpha_composite(atlas.crop((src[0], src[1], src[0] + T, src[1] + T)), (x * T, y * T))
    return img


def main():
    os.makedirs(PREV, exist_ok=True)
    shots = []
    for dom, spec in SETS.items():
        atlas = build(dom, spec)
        shots.append(preview(dom, atlas))
        print("ok", dom)
    w, h = shots[0].size
    sheet = Image.new("RGBA", (w * 2 + 4, (h + 4) * 4), (10, 10, 12, 255))
    for i, s in enumerate(shots):
        sheet.paste(s, ((i % 2) * (w + 4), (i // 2) * (h + 4)))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(PREV, "blocos.png"))


if __name__ == "__main__":
    main()
