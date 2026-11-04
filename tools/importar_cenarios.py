"""Fundos dos domínios a partir dos cenários baixados (ansimuz, CC0).

    python tools/importar_cenarios.py     (depois de tools/baixar_arte.py)

Grava assets/sprites/<prefixo>_cor_{sky,far,mid,near}.png, que o jogo já
prefere (scripts/world/backdrop.gd): o céu parado em 480x270 e as outras
camadas repetidas na horizontal, encostadas embaixo, para a paralaxe. Alguns
domínios ganham outra cor (a Forja vira brasa, Carcosa vira amarelo doente).
"""
import colorsys
import glob
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "arte_externa")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(ROOT, "tools", "previews")
W, H, LW = 480, 270, 960


def find(pattern):
    hits = [f for f in glob.glob(os.path.join(ART, pattern), recursive=True) if not os.path.basename(f).startswith("._")]
    if not hits:
        raise SystemExit("não achei: " + pattern)
    return Image.open(hits[0]).convert("RGBA")


# prefixo: (camadas [sky, far, mid, near] — None deixa vazia, matiz (graus) a girar, saturação)
SETS = {
    "bd": (["gothicvania-rocky-pass-environment/**/PNG/back.png", "gothicvania-rocky-pass-environment/**/PNG/middle.png",
            "gothicvania-rocky-pass-environment/**/PNG/near.png", None], 0, 1.0),
    "bd_saloes": (["fort-of-illusion/**/Layers/back.png", None, "fort-of-illusion/**/Layers/mountains.png", None], 0, 1.0),
    "bd_forja": (["industrial-parallax-background/**/skill-desc_0003_bg.png", "industrial-parallax-background/**/skill-desc_0002_far-buildings.png",
                  "industrial-parallax-background/**/skill-desc_0001_buildings.png", "industrial-parallax-background/**/skill-desc_0000_foreground.png"], -150, 1.3),
    "bd_torre": (["gothicvania-town/**/layers/background.png", None, "gothicvania-town/**/layers/middleground.png", None], 0, 1.0),
    "bd_jardim": (["gotthicvania-swamp/**/Evironment/background.png", "gotthicvania-swamp/**/Evironment/mid-layer-01.png",
                   "gotthicvania-swamp/**/Evironment/mid-layer-02.png", None], 0, 1.0),
    "bd_carcosa": (["gothicvania-junk-wasteland-environment/**/layers/back.png", "gothicvania-junk-wasteland-environment/**/layers/middle.png",
                    "gothicvania-junk-wasteland-environment/**/layers/near.png", None], -105, 1.1),
    "bd_necropole": (["gothicvania-cemetery-pack/**/PNG/Environment/background.png", "gothicvania-cemetery-pack/**/PNG/Environment/mountains.png",
                      "gothicvania-cemetery-pack/**/PNG/Environment/graveyard.png", None], 0, 1.0),
    "bd_catedral": ([None, None, "gothicvania-church-pack/**/ENVIRONMENT/backgrounds.png", None], -40, 1.2),
    "bd_ventre": (["living-tissue-background/**/tile-background.png", None, None, None], 140, 1.3),
    "bd_penhascos": (["magic-cliffs-environment/**/PNG/sky.png", "magic-cliffs-environment/**/PNG/clouds.png",
                      "magic-cliffs-environment/**/PNG/far-grounds.png", None], 80, 0.9),
    "bd_cavernas": (["cavern-tile-set/**/layers/background.png", "cavern-tile-set/**/layers/back-walls.png", None, None], 0, 1.0),
    "bd_bosque": (["forest-background/**/layers/parallax-forest-back-trees.png", "forest-background/**/layers/parallax-forest-lights.png",
                   "forest-background/**/layers/parallax-forest-middle-trees.png", "forest-background/**/layers/parallax-forest-front-trees.png"], 0, 1.0),
}

# O espaço vem em peças pequenas: vai em escala 2 (inteira, não borra) e os
# planetas soltos são postos à mão na camada do meio.
SPACE = "space-background-3/**/layers/parallax-space-%s.png"


def space():
    sky = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for part in ("backgound", "stars"):
        im = find(SPACE % part)
        im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
        sky.alpha_composite(tiled(im, W).crop((0, 0, W, min(H, im.height))), (0, 0))
    far = find(SPACE % "far-planets")
    far = to_screen(far.resize((far.width * 2, far.height * 2), Image.NEAREST), LW, fill_top=False)
    mid = Image.new("RGBA", (LW, H), (0, 0, 0, 0))
    big = find(SPACE % "big-planet")
    ring = find(SPACE % "ring-planet")
    for im, x, y in ((big, 120, 40), (ring, 520, 70), (big.resize((44, 44), Image.NEAREST), 760, 150)):
        mid.alpha_composite(im, (x, y))
    near = Image.new("RGBA", (LW, H), (0, 0, 0, 0))
    return {"sky": sky, "far": far, "mid": mid, "near": near}


def shift(im, degrees, sat):
    if degrees == 0 and sat == 1.0:
        return im
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h + degrees / 360.0) % 1.0
            s = min(1.0, s * sat)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return im


def tiled(im, width):
    out = Image.new("RGBA", (width, im.height), (0, 0, 0, 0))
    for x in range(0, width, im.width):
        out.alpha_composite(im, (x, 0))
    return out


def to_screen(im, width, fill_top):
    """Encosta a camada embaixo de uma tela de altura H; o céu repete a linha de cima."""
    im = tiled(im, width)
    if im.height >= H:
        return im.crop((0, im.height - H, width, im.height))
    out = Image.new("RGBA", (width, H), (0, 0, 0, 0))
    # camada que já começa opaca no topo também sobe até a borda da tela
    row = 0
    if not fill_top and min(im.crop((0, 0, width, 1)).getchannel("A").get_flattened_data()) == 255:
        fill_top, row = True, 0
    if fill_top:
        # no céu, a cor vem de umas linhas abaixo da borda (a primeira às vezes é outra)
        top = im.crop((0, row, width, row + 1)).resize((width, H - im.height))
        out.alpha_composite(top, (0, 0))
    out.alpha_composite(im, (0, H - im.height))
    return out


SCALE2 = {"bd_bosque"}


def packed(im):
    """Os painéis da igreja vêm separados por vãos transparentes: junta lado a lado."""
    cols = [x for x in range(im.width) if im.crop((x, 0, x + 1, im.height)).getbbox()]
    runs, start = [], cols[0]
    for a, b in zip(cols, cols[1:] + [None]):
        if b is None or b != a + 1:
            runs.append((start, a + 1))
            start = b
    out = Image.new("RGBA", (sum(b - a for a, b in runs), im.height), (0, 0, 0, 0))
    x = 0
    for a, b in runs:
        out.alpha_composite(im.crop((a, 0, b, im.height)), (x, 0))
        x += b - a
    return out


def wallpaper(im, width):
    """Textura que repete nas duas direções (a carne do Ventre)."""
    out = Image.new("RGBA", (width, H), (0, 0, 0, 0))
    for y in range(H - im.height, -im.height, -im.height):
        for x in range(0, width, im.width):
            out.alpha_composite(im, (x, y)) if y >= 0 else out.alpha_composite(im.crop((0, -y, im.width, im.height)), (x, 0))
    return out


def main():
    os.makedirs(PREV, exist_ok=True)
    jobs = list(SETS.items()) + [("bd_observatorio", None)]
    for prefix, spec in jobs:
        if spec is None:
            layers = space()
        else:
            paths, hue, sat = spec
            layers = {}
            for name, path in zip(("sky", "far", "mid", "near"), paths):
                if path is None:
                    layers[name] = Image.new("RGBA", (W if name == "sky" else LW, H), (0, 0, 0, 0))
                    continue
                im = shift(find(path), hue, sat)
                if prefix in SCALE2:
                    im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
                if prefix == "bd_catedral":
                    im = packed(im)
                if prefix == "bd_ventre":
                    layers[name] = wallpaper(im, LW)
                    continue
                layers[name] = to_screen(im, W if name == "sky" else LW, fill_top=(name == "sky"))
            if prefix == "bd_catedral":
                # a nave escura atrás dos vitrais
                mid = layers["mid"]
                tone = mid.getpixel((4, H - 150))
                layers["sky"] = Image.new("RGBA", (W, H), tone[:3] + (255,))
        for name, im in layers.items():
            im.save(os.path.join(OUT, "%s_cor_%s.png" % (prefix, name)))
        comp = layers["sky"].copy()
        for name in ("far", "mid", "near"):
            comp.alpha_composite(layers[name].crop((0, 0, W, H)))
        comp.save(os.path.join(PREV, "cenario_%s.png" % prefix))
        print("ok", prefix)


if __name__ == "__main__":
    main()
