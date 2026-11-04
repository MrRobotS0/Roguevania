"""HUD de cada domínio a partir dos kits de interface baixados (todos CC0).

    python tools/importar_hud.py     (depois de tools/baixar_arte.py)

Cada domínio monta o seu jogo de peças, de kits diferentes, e recolore tudo
com três rampas (escuro, metal, destaque):
  panel   caixa de 9 fatias (aviso de interação, faixa do título)
  bar     moldura da vida — tampa esquerda, coluna do meio repetida, tampa
          direita e, se houver, um enfeite no centro; o miolo é transparente
          e o .json guarda onde a vida é pintada (inner)
  boss    moldura da barra do chefe (mesmo formato)
  header  fita atrás do nome do bioma/chefe (mesmo formato, sem miolo)
  slot    moldura dos 4 equipamentos, desenhada no tamanho original
  gem     enfeite ao lado da vida

Grava assets/sprites/hud_<domínio>.png + .json e tools/previews/hud_<domínio>.png.

Kits: Tiny RPG Dragon Regalia GUI e Mana Soul GUI (Gabriel "tiopalada" Lima).
"""
import colorsys
import json
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "arte_externa")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(ROOT, "tools", "previews")
DR = "tiny-rpg-dragon-regalia-gui/20240707dragon"
DR9 = "tiny-rpg-dragon-regalia-gui/20240709dragon"
DR11 = "tiny-rpg-dragon-regalia-gui/20240711dragon"
DR13 = "tiny-rpg-dragon-regalia-gui/20240713dragon"
MS = "tiny-rpg-mana-soul-gui/20250420"
MS1 = "tiny-rpg-mana-soul-gui/20250421"
MS3 = "tiny-rpg-mana-soul-gui/20250423"


def piece(spec):
    """'arquivo' | ('arquivo', largura_do_quadro, índice) -> Image recortada no conteúdo."""
    if isinstance(spec, str):
        im = Image.open(os.path.join(ART, spec + ".png")).convert("RGBA")
    else:
        f, fw, i = spec
        im = Image.open(os.path.join(ART, f + ".png")).convert("RGBA")
        im = im.crop((fw * i, 0, fw * (i + 1), im.height))
    box = im.getbbox()
    return im.crop(box)


# ---------------------------------------------------------------- cor

def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def ramp(stops, k):
    k = max(0.0, min(1.0, k)) * (len(stops) - 1)
    i = min(int(k), len(stops) - 2)
    f = k - i
    a, b = hexc(stops[i]), hexc(stops[i + 1])
    return tuple(round(a[j] + (b[j] - a[j]) * f) for j in range(3))


def recolor(im, look):
    """Separa os pixels pela matiz (ouro/prata = metal, vermelho/verde = destaque,
    o resto = escuro) e pinta cada classe pela rampa do domínio conforme a luz."""
    out = im.copy()
    px = out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if s > 0.3 and 0.04 <= h <= 0.18 and l > 0.3:
                c = ramp(look["metal"], (l - 0.3) / 0.6)
            elif s > 0.15 and 0.42 <= h <= 0.6 and l > 0.5:
                c = ramp(look["metal"], (l - 0.4) / 0.55)
            elif s > 0.35 and (h > 0.9 or h < 0.04 or 0.2 <= h <= 0.42) and l > 0.25:
                c = ramp(look["accent"], (l - 0.25) / 0.55)
            else:
                c = ramp(look["dark"], l / 0.55)
            px[x, y] = c + (a,)
    return out


# ---------------------------------------------------------------- geometria

def inner_box(im):
    """Miolo transparente fechado pela moldura (o que a enchente de fora não alcança)."""
    w, h = im.size
    px = im.load()
    seen = set()
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or px[x, y][3] >= 200:
            continue
        seen.add((x, y))
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    hole = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] < 200 and (x, y) not in seen]
    if not hole:
        return None
    xs = [p[0] for p in hole]
    ys = [p[1] for p in hole]
    return [min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1]


def column(im, x):
    return tuple(im.getpixel((x, y)) for y in range(im.height))


def hbar(im):
    """Tampas, coluna do meio e enfeite central de uma peça horizontal."""
    w = im.width
    cols = [column(im, x) for x in range(w)]
    lo, hi = w // 5, w - w // 5
    counts = {}
    for x in range(lo, hi):
        counts[cols[x]] = counts.get(cols[x], 0) + 1
    mode = max(counts, key=counts.get)
    mid = next(x for x in range(lo, hi) if cols[x] == mode)
    left = next(x for x in range(w) if cols[x] == mode)
    right = w - 1 - next(x for x in range(w - 1, -1, -1) if cols[x] == mode)
    # enfeite no centro: a faixa de colunas diferentes em volta do meio
    c = w // 2
    center = None
    if cols[c] != mode:
        a = c
        while a > left and cols[a - 1] != mode:
            a -= 1
        b = c
        while b < w - right - 1 and cols[b + 1] != mode:
            b += 1
        center = [a, b - a + 1]
    return {"left": left, "right": right, "mid": mid, "center": center}


def mirror_right(im):
    """As abas trazem a marca de 'selecionada' na borda esquerda: o painel vira
    a metade direita e o espelho dela."""
    w, h = im.size
    half = im.crop((w - w // 2, 0, w, h))
    out = Image.new("RGBA", (half.width * 2, h), (0, 0, 0, 0))
    out.paste(half.transpose(Image.FLIP_LEFT_RIGHT), (0, 0))
    out.paste(half, (half.width, 0))
    return out


def dark_fill(src, im, look, tone):
    """O recheio (as 2 cores mais comuns do centro) vira o escuro do domínio,
    para o texto claro ler em cima. A textura do recheio continua, um tom acima."""
    w, h = src.size
    counts = {}
    for y in range(h // 4, h - h // 4):
        for x in range(w // 4, w - w // 4):
            c = src.getpixel((x, y))
            if c[3] > 0:
                counts[c] = counts.get(c, 0) + 1
    top = sorted(counts, key=counts.get, reverse=True)[:2]
    out = im.copy()
    for y in range(h):
        for x in range(w):
            c = src.getpixel((x, y))
            if c in top:
                k = top.index(c)
                out.putpixel((x, y), hexc(look["dark"][tone + k]) + (c[3],))
    return out


# ---------------------------------------------------------------- domínios

LOOKS = {
    # Mar de Cinzas: bronze do império do sol, fita de brasa, cinza por dentro
    "mar_de_cinzas": {
        "dark": ["0c0806", "1b140f", "2e231a", "4a3a2c", "6e5a44"],
        "metal": ["3a2410", "7a5226", "b88a3e", "e0b860", "fff0b8"],
        "accent": ["3a0e08", "7a2210", "c2461c", "f08a3a", "ffd08a"],
        "panel": (MS + "manaTabD-Sheet", 96, 0, 7), "bar": DR9 + "BarA", "boss": DR9 + "BarC",
        "header": DR + "HeaderA", "slot": (DR13 + "FilledFrame-Sheet", 32, 0), "gem": (DR11 + "HorizontalCursorA-Sheet", 26, 0),
    },
    # Salões: prata e gelo, pontas de cristal
    "saloes": {
        "dark": ["060a12", "0e1620", "1c2a3c", "34506a", "5a7a98"],
        "metal": ["2a4058", "5a7a98", "9cc4e0", "dff6ff", "ffffff"],
        "accent": ["0a2a3a", "1a5a7a", "3aa0c8", "9fe8ff", "e8fbff"],
        "panel": (DR + "9SlicesC", 48, 0, 8), "bar": DR9 + "BarB", "boss": DR9 + "BarB",
        "header": DR + "HeaderB", "slot": DR13 + "EmptyFrame", "gem": (DR11 + "VerticalCursorB-Sheet", 26, 0),
    },
    # Forja: ferro escuro com rebites, costuras de brasa
    "forja_rubra": {
        "dark": ["080606", "140c0a", "241816", "3c2c2a", "5a4a4a"],
        "metal": ["2a2a30", "4a4a52", "7a7a86", "a8a8b4", "d8d8e0"],
        "accent": ["3a0804", "8a1a08", "e0400c", "ff8a3a", "ffd060"],
        "panel": (DR + "9SlicesD", 48, 0, 8), "bar": DR9 + "BarC", "boss": DR9 + "BarA",
        "header": (MS + "manaSoulHeaderB-Sheet", 96, 0), "slot": (DR13 + "FilledFrame-Sheet", 32, 2), "gem": (DR11 + "MouseCursorBig-Sheet", 23, 0),
    },
    # Torre de Babel: pedra clara gravada a ouro, molduras em losango
    "torre_babel": {
        "dark": ["0e0b08", "1e1912", "3a3226", "5e5440", "8a8270"],
        "metal": ["4a3a1a", "8a6a2a", "c89a3a", "efd27a", "fff6d2"],
        "accent": ["2a1a3a", "4a2e6a", "7a5aa8", "b89ae0", "efe6ff"],
        "panel": (MS + "manaTabC-Sheet", 96, 1, 7), "bar": (MS1 + "barA-Sheet", 95, 0), "boss": (MS1 + "barA-Sheet", 95, 0),
        "header": (MS + "manaSoulHeaderA-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 0), "gem": (MS1 + "verticalCursorB-Sheet", 13, 0),
    },
    # Jardim: madeira viva, folhas, verde de musgo
    "jardim_primordial": {
        "dark": ["060a04", "0e140a", "1c2a14", "34481e", "4a6a2a"],
        "metal": ["2a3a10", "5a7a22", "9cc65a", "c8e07a", "f0ffc0"],
        "accent": ["0a2a10", "1a6a2a", "3aa848", "8ae06a", "d8ffb0"],
        "panel": (MS + "manaTabF-Sheet", 96, 0, 7), "bar": (MS1 + "barB-Sheet", 95, 0), "boss": (MS1 + "barB-Sheet", 95, 0),
        "header": (MS1 + "manaSoulButtonB-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 2), "gem": (MS1 + "horizontalCursorC-Sheet", 36, 0),
    },
    # Carcosa: preto e o amarelo que escorre
    "carcosa": {
        "dark": ["060402", "120e08", "221a0c", "3a2e14", "5a4a24"],
        "metal": ["4a3a0a", "8a7010", "d0b020", "ffd84a", "fff8b0"],
        "accent": ["2a2a08", "5a5a10", "a0a020", "e8e050", "ffffb0"],
        "panel": (MS + "manaTabG-Sheet", 96, 0, 7), "bar": (MS1 + "barA-Sheet", 95, 0), "boss": DR9 + "BarC",
        "header": (MS1 + "manaSoulButtonC-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 3), "gem": (MS1 + "verticalCursorA-Sheet", 20, 0),
    },
    # Observatório: vidro e latão, azul profundo
    "observatorio": {
        "dark": ["02040a", "050a14", "0e1a30", "1f3a6a", "3a5a9a"],
        "metal": ["3a2a10", "7a5a20", "c09040", "f0d080", "fff6dc"],
        "accent": ["06263a", "0e5a7a", "2aa8d0", "6fe8ff", "e0ffff"],
        "panel": (MS + "manaTabE-Sheet", 96, 3, 7), "bar": (MS1 + "barC-Sheet", 95, 0), "boss": (MS1 + "barC-Sheet", 95, 0),
        "header": (DR9 + "ButtonA-Sheet", 100, 0), "slot": DR13 + "EmptyFrame", "gem": (DR11 + "HorizontalCursorB-Sheet", 26, 0),
    },
    # Necrópole: osso, prata velha e o azul frio dos mortos
    "necropole": {
        "dark": ["06070c", "0e1018", "1c2030", "343a52", "4a5068"],
        "metal": ["3a3a42", "6a6e7a", "a8aeba", "d8dce6", "f6f8ff"],
        "accent": ["101a2e", "2a3a5e", "5a74a8", "a8c0e8", "e8f0ff"],
        "panel": (MS + "manaTabA-Sheet", 96, 0, 7), "bar": (MS1 + "barC-Sheet", 95, 0), "boss": (MS1 + "barA-Sheet", 95, 0),
        "header": (MS1 + "manaSoulButtonA-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 1), "gem": (MS1 + "verticalCursorB-Sheet", 13, 0),
    },
    # Catedral Submersa: pedra molhada, vitral azul
    "catedral": {
        "dark": ["04080e", "0a1622", "142a3e", "1f405e", "2a4a6a"],
        "metal": ["2a3a4a", "4a6a8a", "7aa0c0", "b8d8f0", "eef8ff"],
        "accent": ["06223a", "0e4a6e", "2a8ab8", "6ab8e8", "d0f0ff"],
        "panel": (MS + "manaTabE-Sheet", 96, 0, 7), "bar": (MS1 + "barC-Sheet", 95, 0), "boss": (MS1 + "barC-Sheet", 95, 0),
        "header": (MS1 + "manaSoulButtonB-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 0), "gem": (MS1 + "horizontalCursorC-Sheet", 36, 0),
    },
    # O Ventre: carne, osso e bile
    "ventre": {
        "dark": ["0e0405", "1a0a0c", "3a1216", "5a1a20", "6a2028"],
        "metal": ["5a2a1a", "8a4a30", "c87a5a", "e8b098", "fff0e8"],
        "accent": ["3a3a08", "6a6a10", "a8a828", "c8d040", "f0ffa0"],
        "panel": (MS + "manaTabG-Sheet", 96, 0, 7), "bar": (MS1 + "barB-Sheet", 95, 0), "boss": DR9 + "BarC",
        "header": (MS1 + "manaSoulButtonC-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 3), "gem": (MS1 + "verticalCursorA-Sheet", 20, 0),
    },
    # Penhascos do Sonho: lilás, nuvem e prata
    "penhascos": {
        "dark": ["08060e", "140f20", "261c3a", "3e3060", "5a4a7a"],
        "metal": ["4a4060", "7a6a9a", "b0a0d8", "e0d0ff", "fff8ff"],
        "accent": ["2a103a", "5a2a7a", "9a5ac8", "c8a8ff", "f4e8ff"],
        "panel": (MS + "manaTabC-Sheet", 96, 2, 7), "bar": (MS1 + "barA-Sheet", 95, 0), "boss": (MS1 + "barC-Sheet", 95, 0),
        "header": (DR9 + "ButtonA-Sheet", 100, 0), "slot": DR13 + "EmptyFrame", "gem": (DR11 + "HorizontalCursorB-Sheet", 26, 0),
    },
    # Cavernas Fundas: rocha escura, cristal molhado
    "cavernas": {
        "dark": ["030405", "0a0c10", "161a20", "262c34", "3a4048"],
        "metal": ["2a2e34", "4a5058", "7a828c", "aab4be", "e0e8f0"],
        "accent": ["0a2a32", "1a5060", "3a8aa0", "8ac8e8", "e0f8ff"],
        "panel": (MS + "manaTabF-Sheet", 96, 2, 7), "bar": (MS1 + "barB-Sheet", 95, 0), "boss": (MS1 + "barA-Sheet", 95, 0),
        "header": (MS + "manaSoulHeaderA-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 2), "gem": (MS1 + "verticalCursorB-Sheet", 13, 0),
    },
    # Bosque Errante: couro, madeira e ouro da estrada
    "bosque": {
        "dark": ["080604", "12100a", "241e12", "3a3020", "5a4a2a"],
        "metal": ["4a3a1a", "7a6030", "b89a5a", "e8d498", "fff8dc"],
        "accent": ["1a3010", "3a5a1e", "6a8a3a", "a8c870", "e8f8c0"],
        "panel": (MS + "manaTabB-Sheet", 96, 0, 7), "bar": (MS1 + "barA-Sheet", 95, 0), "boss": (MS1 + "barB-Sheet", 95, 0),
        "header": (MS1 + "manaSoulButtonA-Sheet", 96, 0), "slot": (MS3 + "emptyFrame-Sheet", 32, 0), "gem": (MS1 + "horizontalCursorC-Sheet", 36, 0),
    },
}


def build(dom, look):
    parts = {}
    meta = {}
    for name in ["panel", "bar", "boss", "header", "slot", "gem"]:
        spec = look[name]
        margin = None
        if name == "panel":
            spec, margin = spec[:3], spec[3]
        src = piece(spec)
        if name == "panel" and "manaTab" in spec[0]:
            src = mirror_right(src)
        im = recolor(src, look)
        if name in ("panel", "header"):
            im = dark_fill(src, im, look, 1 if name == "panel" else 2)
        parts[name] = im
        m = {}
        if name == "panel":
            m["margin"] = margin
        if name in ("bar", "boss", "header"):
            m.update(hbar(im))
            if name != "header":
                inner = inner_box(im)
                if inner is None:
                    raise SystemExit("%s/%s sem miolo transparente" % (dom, name))
                m["inner"] = [inner[0], inner[1], im.width - inner[0] - inner[2], inner[3]]  # x, y, sobra à direita, altura
        if name == "slot":
            m["inner"] = inner_box(im)
        meta[name] = m
    # atlas: uma fila só, 1 px de folga entre as peças
    W = sum(p.width + 1 for p in parts.values())
    H = max(p.height for p in parts.values())
    atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = 0
    for name, im in parts.items():
        atlas.paste(im, (x, 0))
        meta[name]["rect"] = [x, 0, im.width, im.height]
        x += im.width + 1
    meta["text"] = look["metal"][3]
    meta["dim"] = look["dark"][4]
    meta["accent"] = look["accent"][3]
    atlas.save(os.path.join(OUT, "hud_%s.png" % dom))
    with open(os.path.join(OUT, "hud_%s.json" % dom), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    big = atlas.resize((W * 4, H * 4), Image.NEAREST)
    bg = Image.new("RGBA", big.size, (40, 40, 48, 255))
    bg.alpha_composite(big)
    bg.save(os.path.join(PREV, "hud_%s.png" % dom))
    print("ok", dom, atlas.size, {k: (v.get("inner") if isinstance(v, dict) else v) for k, v in meta.items() if k in ("bar", "boss")})


def main():
    os.makedirs(PREV, exist_ok=True)
    for dom, look in LOOKS.items():
        build(dom, look)


if __name__ == "__main__":
    main()
