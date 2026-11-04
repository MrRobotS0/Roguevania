"""Prévia do HUD de cada domínio sobre o fundo dele (tools/previews/hud_temas.png).

    python tools/previa_hud.py      (depois de tools/importar_hud.py)

Imita as contas de scripts/ui/hud_skin.gd e hud.gd (posições, tampas, meio
repetido, miolo da barra) para ver os 7 HUDs sem abrir o jogo. O texto vira
blocos claros: a fonte do jogo é desenhada em GDScript.
"""
import json
import os

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
SP = os.path.join(ROOT, "assets", "sprites")
W, H = 480, 270
BAR_W, BOSS_W = 120, 240
BACK = {"mar_de_cinzas": "bd", "saloes": "bd_saloes", "forja_rubra": "bd_forja", "torre_babel": "bd_torre",
        "jardim_primordial": "bd_jardim", "carcosa": "bd_carcosa", "observatorio": "bd_observatorio"}
HP, GHOST, BOSS = (214, 69, 69), (240, 190, 70), (143, 95, 208)


def backdrop(dom):
    img = Image.new("RGBA", (W, H), (10, 10, 14, 255))
    for layer in ["sky", "far", "mid", "near"]:
        p = os.path.join(SP, "%s_cor_%s.png" % (BACK[dom], layer))
        if os.path.exists(p):
            im = Image.open(p).convert("RGBA")
            img.alpha_composite(im.crop((0, 0, min(W, im.width), im.height)), (0, H - im.height))
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 90))
    img.alpha_composite(shade)
    return img


class Skin:
    def __init__(self, dom):
        self.atlas = Image.open(os.path.join(SP, "hud_%s.png" % dom)).convert("RGBA")
        self.meta = json.load(open(os.path.join(SP, "hud_%s.json" % dom), encoding="utf-8"))

    def region(self, part, x, w):
        r = self.meta[part]["rect"]
        return self.atlas.crop((r[0] + x, r[1], r[0] + x + w, r[1] + r[3]))

    def size(self, part):
        return self.meta[part]["rect"][2], self.meta[part]["rect"][3]

    def hbar(self, img, part, at, width):
        p = self.meta[part]
        rw, rh = self.size(part)
        left, right = p["left"], p["right"]
        x, y = at
        img.alpha_composite(self.region(part, 0, left), (x, y))
        img.alpha_composite(self.region(part, p["mid"], 1).resize((width - left - right, rh), Image.NEAREST), (x + left, y))
        img.alpha_composite(self.region(part, rw - right, right), (x + width - right, y))
        if p.get("center"):
            cx, cw = p["center"]
            img.alpha_composite(self.region(part, cx, cw), (x + round((width - cw) / 2), y))
        inner = p.get("inner")
        if inner:
            return (x + inner[0], y + inner[1], width - inner[0] - inner[2], inner[3])
        return (x, y, width, rh)

    def panel(self, img, box, pad=3):
        r = self.meta["panel"]["rect"]
        m = self.meta["panel"]["margin"]
        src = self.atlas.crop((r[0], r[1], r[0] + r[2], r[1] + r[3]))
        x0, y0, w, h = box[0] - pad, box[1] - pad, box[2] + pad * 2, box[3] + pad * 2
        sw, sh = src.size
        xs = [(0, m, 0, m), (m, sw - m, m, w - m), (sw - m, sw, w - m, w)]
        ys = [(0, m, 0, m), (m, sh - m, m, h - m), (sh - m, sh, h - m, h)]
        for sx0, sx1, dx0, dx1 in xs:
            for sy0, sy1, dy0, dy1 in ys:
                piece = src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST)
                img.alpha_composite(piece, (x0 + dx0, y0 + dy0))

    def slot(self, img, at):
        r = self.meta["slot"]["rect"]
        img.alpha_composite(self.atlas.crop((r[0], r[1], r[0] + r[2], r[1] + r[3])), at)

    def color(self, key):
        h = self.meta[key]
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def text(d, x, y, n, color, scale=1):
    """bloco no lugar do texto: n letras da fonte 5x7 (avanço 6)"""
    d.rectangle([x, y, x + n * 6 * scale - 2, y + 7 * scale - 1], fill=color)


def frame(dom):
    img = backdrop(dom)
    s = Skin(dom)
    d = ImageDraw.Draw(img)
    gw, gh = s.size("gem")
    r = s.meta["gem"]["rect"]
    img.alpha_composite(s.atlas.crop((r[0], r[1], r[0] + gw, r[1] + gh)), (5, 4))
    at = (5 + gw + 1, 5)
    ix, iy, iw, ih = s.hbar(img, "bar", at, BAR_W)
    d.rectangle([ix, iy, ix + round(iw * 0.8) - 1, iy + ih - 1], fill=GHOST)
    d.rectangle([ix, iy, ix + round(iw * 0.65) - 1, iy + ih - 1], fill=HP)
    bh = s.size("bar")[1]
    text(d, at[0] + BAR_W + 4, at[1] + (bh - 5) // 2, 5, s.color("text"))
    fy = at[1] + bh + 3
    for i in range(3):
        c = s.color("text") if i < 2 else s.color("dim")
        d.rectangle([at[0] + i * 9 + 1, fy + 2, at[0] + i * 9 + 5, fy + 7], fill=c)
        if i < 2:
            d.rectangle([at[0] + i * 9 + 2, fy + 4, at[0] + i * 9 + 4, fy + 6], fill=HP)
    # canto direito: essência e atributos
    text(d, W - 40, 8, 4, (120, 230, 255))
    # slots
    cw, ch = s.size("slot")
    sx = 6
    for i in range(4):
        p = (6 + i * (cw + 2) + (6 if i >= 2 else 0), H - ch - 5)
        s.slot(img, p)
        d.rectangle([p[0] + cw // 2 - 4, p[1] + ch // 2 - 4, p[0] + cw // 2 + 3, p[1] + ch // 2 + 3], fill=(200, 200, 210))
        text(d, p[0] + 2, p[1] - 6, 1, s.color("text"))
        sx = p[0] + cw
    # aviso de interação
    box = (W // 2 - 60, H - 61, 120, 17)
    s.panel(img, box)
    text(d, box[0] + 7, box[1] + 5, 1, s.color("text"))
    text(d, box[0] + 20, box[1] + 5, 12, (235, 230, 220))
    # chefe: barra e fita com o nome
    bw = BOSS_W
    bh2 = s.size("boss")[1]
    bx = max((W - bw) // 2, sx + 12)
    by = H - bh2 - 4
    ix, iy, iw, ih = s.hbar(img, "boss", (bx, by), bw)
    d.rectangle([ix, iy, ix + round(iw * 0.7) - 1, iy + ih - 1], fill=BOSS)
    hh = s.size("header")[1]
    caps = s.meta["header"]["left"] + s.meta["header"]["right"]
    for (cx, cy, n, sc) in [(bx + bw // 2, by - hh // 2 - 1, 14, 1), (W // 2, 52, 10, 2)]:
        w = n * 6 * sc + caps + 8
        s.hbar(img, "header", (cx - w // 2, cy - hh // 2), w)
        text(d, cx - n * 3 * sc, cy - 7 * sc // 2, n, s.color("text"), sc)
    return img


def main():
    doms = list(BACK)
    sheet = Image.new("RGBA", (W * 2 + 6, (H + 6) * 4), (20, 20, 24, 255))
    for i, dom in enumerate(doms):
        sheet.paste(frame(dom), ((i % 2) * (W + 6), (i // 2) * (H + 6)))
    out = os.path.join(ROOT, "tools", "previews", "hud_temas.png")
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(out)
    print(out)


if __name__ == "__main__":
    main()
