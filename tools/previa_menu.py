"""Prévia das caixas de menu (Mercador, Vigia, pausa) sem abrir o jogo.

    python tools/previa_menu.py      -> tools/previews/menu.png

Imita scripts/ui/menu.gd (_draw) com a fonte do jogo, sobre um cenário.
Serve para julgar layout e contraste; não tem a luz nem a ambiência.
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import previa_titulo as pt  # noqa: E402  (fonte do jogo lida do pixel_font.gd)

ROOT = os.path.join(os.path.dirname(__file__), "..")
W, H = 480, 270
WIDTH, PAD, LINE, ROW_H, DETAIL_H, FOOT_H = 316, 10, 12, 16, 36, 14
C = {k: pt.hexc(v) for k, v in dict(panel="0e0b14", head="161120", frame="5a4d74", pick="2c2340", row="cdc4de",
                                     sub="9a8fb4", detail="e6dff2", disabled="625a78", dprice="8a4a52",
                                     gold="f2c14e", text="f2ecff", ess="9fe8ff", shadow="07060b").items()}


def icon(name):
    p = os.path.join(ROOT, "assets", "icons", name + "_16.png")
    return Image.open(p).convert("RGBA") if os.path.exists(p) else None


def wrap(text, limit):
    out, line = [], ""
    for w in text.split():
        if len(line) + len(w) + (1 if line else 0) > limit:
            out.append(line)
            line = w
        else:
            line = (line + " " + w).strip()
    return out + ([line] if line else [])


def menu(img, title, subtitle, options, index, cancel=True):
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, 0, W, H], fill=(7, 6, 11, 209))
    info = ""
    if "  ·  " in title:
        title, info = title.split("  ·  ")
    iw = len(info) * 6 + 10 if info else 0
    sc = 2 if len(title) * 12 <= WIDTH - PAD * 2 - iw else 1
    title_h = 7 * sc + 8
    subs = wrap(subtitle.upper(), (WIDTH - PAD * 2) // 6)[:2] if subtitle else []
    has_detail = any(o.get("detail") for o in options)
    rows = min(len(options), 8)
    head_h = PAD + title_h + (len(subs) * LINE + 2 if subs else 0) + 6
    body_h = rows * ROW_H + (DETAIL_H + 9 if has_detail else 0)
    box_h = head_h + body_h + 8 + FOOT_H
    bx, by = (W - WIDTH) // 2, (H - box_h) // 2
    d.rectangle([bx - 3, by - 3, bx + WIDTH + 2, by + box_h + 2], fill=C["shadow"])
    d.rectangle([bx - 1, by - 1, bx + WIDTH, by + box_h], fill=C["frame"])
    d.rectangle([bx, by, bx + WIDTH - 1, by + box_h - 1], fill=C["panel"])
    d.rectangle([bx, by, bx + WIDTH - 1, by + head_h - 5], fill=C["head"])
    d.line([bx, by + head_h - 4, bx + WIDTH - 1, by + head_h - 4], fill=C["frame"])
    x, y = bx + PAD, by + PAD
    pt.body(d, title, x, y + 2, C["gold"], sc)
    if info:
        pt.body(d, info, bx + WIDTH - PAD - iw + 10, y + 2 + (7 * sc - 7) // 2, C["ess"])
    y += title_h
    for s in subs:
        pt.body(d, s, x, y + 2, C["sub"])
        y += LINE
    y = by + head_h + 4
    icons = any(o.get("icon") for o in options)
    tx = x + (20 if icons else 4)
    for i, o in enumerate(options[:rows]):
        sel, dis = i == index, o.get("disabled", False)
        if sel:
            d.rectangle([bx + 4, y, bx + WIDTH - 5, y + ROW_H - 2], fill=C["pick"])
            d.rectangle([bx + 4, y, bx + 5, y + ROW_H - 2], fill=C["gold"])
        col = C["disabled"] if dis else (C["text"] if sel else C["row"])
        ty = y + 2
        if o.get("icon"):
            ic = icon(o["icon"])
            if ic:
                if dis:
                    ic.putalpha(ic.getchannel("A").point(lambda a: int(a * .4)))
                img.alpha_composite(ic, (x, y - 1))
        price = o.get("price", "")
        pw = len(price) * 6
        pt.body(d, o["label"].upper(), tx, ty + 2, col)
        if price:
            pt.body(d, price, bx + WIDTH - PAD - pw, ty + 2, C["dprice"] if dis else C[o.get("pc", "gold")])
        y += ROW_H
    if has_detail:
        y += 4
        d.line([bx + PAD, y, bx + WIDTH - PAD, y], fill=C["frame"])
        y += 5
        for line in wrap(options[index].get("detail", "").upper(), (WIDTH - PAD * 2) // 6)[:3]:
            pt.body(d, line, x, y + 2, C["detail"])
            y += LINE
    top = by + box_h - FOOT_H
    d.line([bx, top, bx + WIDTH - 1, top], fill=C["frame"])
    d.rectangle([bx, top + 1, bx + WIDTH - 1, by + box_h - 1], fill=C["head"])
    hint = "W/S ESCOLHER   J OK" + ("   ESC SAIR" if cancel else "")
    pt.body(d, hint, x, top + 3, C["sub"])


def scene(bg="bd_catedral"):
    img = Image.new("RGBA", (W, H))
    for layer in ("sky", "far", "mid", "near"):
        p = os.path.join(ROOT, "assets", "sprites", "%s_cor_%s.png" % (bg, layer))
        if os.path.exists(p):
            img.alpha_composite(Image.open(p).convert("RGBA").crop((0, 0, W, H)))
    return img


def main():
    shots = []
    m = scene()
    menu(m, "O MERCADOR", "\"TUDO TEM PREÇO. ATÉ O QUE CAIU DO CÉU.\"", [
        dict(label="Tridente Afogado", price="85 OURO", icon="tridente_afogado", detail="ARMA DE ASTÚCIA · CRÍTICO COM A PONTA"),
        dict(label="Bile Ácida", price="70 OURO", icon="bile_acida", detail="HABILIDADE DE ASTÚCIA"),
        dict(label="Arco do Sonho", price="VENDIDO", icon="arco_sonho", disabled=True, detail="ARMA DE FÚRIA"),
        dict(label="Pão de Cinza", price="60 OURO", icon="pao", detail="CURA METADE DA VIDA AGORA"),
        dict(label="Frasco Extra", price="105 OURO", icon="frasco", disabled=True, detail="+1 FRASCO DE CURA NESTA PARTIDA"),
        dict(label="Sair", detail="VOCÊ TEM 92 DE OURO")], 0)
    shots.append(m)
    v = scene("bd_necropole")
    menu(v, "A VIGIA  ·  ESSÊNCIA 140", "VOCÊ DE NOVO. OU OUTRO IGUAL A VOCÊ.", [
        dict(label="Lâmina do Luto", price="45", pc="ess", icon="lamina_luto", detail="ARMA DE ASTÚCIA · PASSA A APARECER NAS PARTIDAS"),
        dict(label="Grito da Carpideira", price="45", pc="ess", icon="grito_carpideira", detail="HABILIDADE DE VIGOR · PASSA A APARECER NAS PARTIDAS"),
        dict(label="Aparência: Mortalha", price="110", pc="ess", detail="SÓ MUDA O VISUAL · ESCOLHA NO TÍTULO"),
        dict(label="Segundo Cálice", price="110", pc="ess", icon="calice", detail="+1 FRASCO DE CURA (REQUER O PRIMEIRO)"),
        dict(label="Sair", detail="A ESSÊNCIA QUE SOBRAR SE PERDE SE VOCÊ MORRER")], 1)
    shots.append(v)
    p = scene("bd_bosque")
    menu(p, "PAUSA", "MUTAÇÕES: LUTO, SONO LEVE", [
        dict(label="Continuar"), dict(label="Opções"), dict(label="Comandos"), dict(label="Salvar e sair"),
        dict(label="Desistir da partida")], 0)
    shots.append(p)
    out = Image.new("RGBA", (W, H * len(shots)))
    for i, s in enumerate(shots):
        out.alpha_composite(s, (0, i * H))
    out = out.resize((W * 2, H * 2 * len(shots)), Image.NEAREST)
    path = os.path.join(ROOT, "tools", "previews", "menu.png")
    out.save(path)
    print(path)


if __name__ == "__main__":
    main()
