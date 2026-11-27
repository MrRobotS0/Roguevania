"""Objetos em fatias (sprite stacking), já desenhados quadro a quadro.

    python tools/gen_pilhas.py [--previa]

Sprite stacking: o objeto é uma pilha de fatias horizontais (cada uma é o objeto
visto de cima numa altura), desenhadas com 1 px de diferença; girar as fatias gira
o objeto em 3D. O jogo girava as fatias na hora, na placa de vídeo, e na câmera lisa
(tela desenhada na resolução real) isso saía fora da grade de pixel: baú serrilhado e
item do pedestal virando rabisco quando ficava de lado. Aqui cada objeto é girado em
N ângulos e rasterizado NA GRADE DO JOGO; o jogo só escolhe o quadro (scripts/world/stack.gd).

Grava assets/sprites/pilhas.png (uma tira de N quadros por objeto) e pilhas.json:
  nome: x, y da tira; w, h do quadro; ox, oy = onde fica o centro da base no quadro.
Objetos: bau, bau_aberto, bau_maldito, bau_maldito_aberto, moeda, planta e item_<id>
para cada ícone de assets/icons/<id>_16.png. Rodar de novo ao criar ícone novo.
"""
import glob
import json
import math
import os
import sys

from PIL import Image

RAIZ = os.path.join(os.path.dirname(__file__), "..")
SAIDA = os.path.join(RAIZ, "assets", "sprites")
ICONES = os.path.join(RAIZ, "assets", "icons")
QUADROS = 32
CONTORNO = (0x0b, 0x09, 0x10, 255)
NADA = (0, 0, 0, 0)


def cor(hexa):
    return tuple(int(hexa[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def escuro(c, k):
    return (round(c[0] * (1 - k)), round(c[1] * (1 - k)), round(c[2] * (1 - k)), c[3])


def claro(c, k):
    return (round(c[0] + (255 - c[0]) * k), round(c[1] + (255 - c[1]) * k), round(c[2] + (255 - c[2]) * k), c[3])


# --- modelos: fatias[y][z][x], y = 0 é a fatia do chão; z maior fica mais perto de quem olha

def de_voxels(w, h, d, fn):
    return [[[fn(x, y, z) for x in range(w)] for z in range(d)] for y in range(h)]


def de_imagem(img, espessura=2):
    """Cada linha do desenho vira uma fatia: o desenho ganha corpo e gira como peça."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()

    def fn(x, y, z):
        c = px[x, h - 1 - y]
        if c[3] < 128:
            return NADA
        c = (c[0], c[1], c[2], 255)
        # a face de trás é mais escura: de lado se vê a espessura
        return c if z == espessura - 1 else escuro(c, 0.45)

    return de_voxels(w, h, espessura, fn)


def bau(aberto, maldito):
    madeira = cor("6a3f8a") if maldito else cor("7a4a2c")
    ferro = cor("1c1620") if maldito else cor("3a3236")
    fecho = cor("c08fff") if maldito else cor("f2c14e")
    W, H, D, tampa = 16, 12, 10, 8

    def fn(x, y, z):
        # casca de 2 voxels: com a inclinação cada fatia mostra 1 px da frente
        borda_x = x <= 1 or x >= W - 2
        borda_z = z <= 1 or z >= D - 2
        if aberto and y >= tampa:
            return NADA
        topo = not aberto and y == H - 1
        if not (borda_x or borda_z) and y > 0 and not topo:
            if aberto and y == tampa - 1:
                return cor("f2c14e") if (x + z) % 3 else cor("ffe28a")
            return NADA
        c = madeira
        if x % 4 == 1 and not borda_x and z >= D - 2:
            c = escuro(madeira, 0.18)
        if y == tampa - 1:
            c = escuro(madeira, 0.35)
        if x == 3 or x == W - 4 or y == 0 or (y == H - 1 and not aberto and (borda_x or borda_z)):
            c = ferro
        if z >= D - 2 and abs(x - W // 2) <= 1 and tampa - 3 <= y <= tampa:
            c = fecho
        return c

    return de_voxels(W, H, D, fn)


def moeda():
    ouro = cor("f2c14e")

    def fn(x, y, _z):
        dx, dy = x - 3, y - 3
        r2 = dx * dx + dy * dy
        if r2 > 10:
            return NADA
        if r2 > 6:
            return escuro(ouro, 0.25)
        return claro(ouro, 0.25) if dx + dy < 0 else ouro

    return de_voxels(7, 7, 2, fn)


def planta():
    """A planta enrolada: papel com riscos azuis e os rolos escuros nas pontas."""
    papel = cor("e8dcc0")
    img = Image.new("RGBA", (8, 7), cor("07060b"))
    px = img.load()
    for y in range(1, 6):
        for x in range(1, 7):
            px[x, y] = papel
        px[0, y] = px[7, y] = escuro(papel, 0.3)
    for x in range(2, 6):
        px[x, 2] = cor("3a6aa0")
    for x in range(2, 5):
        px[x, 4] = cor("3a6aa0")
    return de_imagem(img, 2)


# --- rasterização ------------------------------------------------------------------

def medidas(fatias, inclina):
    n, d, w = len(fatias), len(fatias[0]), len(fatias[0][0])
    raio = math.hypot(w, d) / 2
    fw = 2 * math.ceil(raio) + 4
    fundo = math.ceil(raio * inclina)
    fh = n + 2 * fundo + 4
    return fw, fh, fw // 2, fh - 3 - fundo


def girar(fatias, angulo, inclina, contorno):
    """Um quadro: a pilha girada de `angulo`, vista com `inclina` (0 = de lado puro).

    Cada fatia, em cada coluna da tela, ocupa um trecho de profundidade; ele sempre
    pinta pelo menos uma linha (fatia fina de lado não some nem vira peneira) e, onde
    cobre mais de uma, cada linha busca o seu ponto da fatia.
    """
    n, d, w = len(fatias), len(fatias[0]), len(fatias[0][0])
    fw, fh, ox, oy = medidas(fatias, inclina)
    img = Image.new("RGBA", (fw, fh), NADA)
    px = img.load()
    ca, sa = math.cos(angulo), math.sin(angulo)
    for i, fatia in enumerate(fatias):
        k = 0.62 + 0.38 * i / max(n - 1, 1)
        if i == n - 1:
            k = 1.12
        for sx in range(fw):
            X = sx + 0.5 - ox
            # pontos da fatia nesta coluna: (X, Y) na tela -> u = X cos + Y sen, v = -X sen + Y cos
            lo, hi = -1e9, 1e9
            for a, b, lim in ((sa, X * ca, w / 2), (ca, -X * sa, d / 2)):
                if abs(a) < 1e-6:
                    if abs(b) >= lim:
                        lo, hi = 1.0, -1.0
                    continue
                y1, y2 = (-lim - b) / a, (lim - b) / a
                lo, hi = max(lo, min(y1, y2)), min(hi, max(y1, y2))
            if hi <= lo:
                continue
            r0 = math.floor(lo * inclina + oy - i + 0.5)
            r1 = math.floor(hi * inclina + oy - i + 0.5 - 1e-6)
            for r in range(r0, max(r0, r1) + 1):
                if not 0 <= r < fh:
                    continue
                Y = min(max((r - oy + i) / inclina, lo + 1e-4), hi - 1e-4)
                u = int(math.floor(X * ca + Y * sa + w / 2))
                v = int(math.floor(-X * sa + Y * ca + d / 2))
                if not (0 <= u < w and 0 <= v < d):
                    continue
                c = fatia[v][u]
                if c[3] == 0:
                    continue
                px[sx, r] = (min(255, round(c[0] * k)), min(255, round(c[1] * k)), min(255, round(c[2] * k)), 255)
    if contorno:
        cheio = [[px[x, y][3] > 0 for x in range(fw)] for y in range(fh)]
        for y in range(fh):
            for x in range(fw):
                if cheio[y][x]:
                    continue
                if any(0 <= x + a < fw and 0 <= y + b < fh and cheio[y + b][x + a] for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    px[x, y] = CONTORNO
    return img


def main():
    objetos = [
        ("bau", bau(False, False), 0.5, True),
        ("bau_aberto", bau(True, False), 0.5, True),
        ("bau_maldito", bau(False, True), 0.5, True),
        ("bau_maldito_aberto", bau(True, True), 0.5, True),
        ("moeda", moeda(), 0.3, False),
        ("planta", planta(), 0.2, False),
    ]
    for arq in sorted(glob.glob(os.path.join(ICONES, "*_16.png"))):
        nome = os.path.basename(arq)[:-len("_16.png")]
        objetos.append(("item_" + nome, de_imagem(Image.open(arq), 2), 0.16, True))

    tiras, meta, y, largura = [], {}, 0, 0
    for nome, fatias, inclina, contorno in objetos:
        fw, fh, ox, oy = medidas(fatias, inclina)
        tira = Image.new("RGBA", (fw * QUADROS, fh), NADA)
        for f in range(QUADROS):
            tira.paste(girar(fatias, f * math.tau / QUADROS, inclina, contorno), (f * fw, 0))
        tiras.append((tira, y))
        meta[nome] = {"x": 0, "y": y, "w": fw, "h": fh, "ox": ox, "oy": oy}
        y += fh
        largura = max(largura, tira.width)
    atlas = Image.new("RGBA", (largura, y), NADA)
    for tira, ty in tiras:
        atlas.paste(tira, (0, ty))
    atlas.save(os.path.join(SAIDA, "pilhas.png"))
    with open(os.path.join(SAIDA, "pilhas.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"frames": QUADROS, "color": True, "w": 24, "h": 24, "itens": meta}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("%d objetos, atlas %dx%d" % (len(objetos), atlas.width, atlas.height))

    if "--previa" in sys.argv:
        nomes = ["bau", "bau_aberto", "bau_maldito", "moeda", "planta"] + [n for n in meta if n.startswith("item_")][:6]
        alt = sum(meta[n]["h"] + 2 for n in nomes)
        previa = Image.new("RGBA", (largura, alt), (42, 36, 48, 255))
        py = 0
        for n in nomes:
            m = meta[n]
            previa.alpha_composite(atlas.crop((0, m["y"], m["w"] * QUADROS, m["y"] + m["h"])), (0, py))
            py += m["h"] + 2
        destino = os.path.join(RAIZ, "build", "auditoria", "pilhas_previa.png")
        os.makedirs(os.path.dirname(destino), exist_ok=True)
        previa.resize((previa.width * 3, previa.height * 3), Image.NEAREST).convert("RGB").save(destino)
        print("prévia:", destino)


if __name__ == "__main__":
    main()
