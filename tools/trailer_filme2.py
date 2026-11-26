"""Trailer 2 do MOKSHA, "de filme": cenas em pixel art feitas só para o trailer.

  python tools/trailer_filme2.py          # PT e EN
  python tools/trailer_filme2.py pt
  python tools/trailer_filme2.py --refazer-cenas   # redesenha as cenas (senão reaproveita build/filmagem/filme2)

Clima de trailer épico de deserto (paisagem imensa e quieta, escala absurda,
silhuetas, graves de metal nos cortes, silêncio antes do título). Tudo original:
as cenas são desenhadas aqui com numpy (480x200 = 2.39:1, ampliado 4x sem borrar) e
usam a arte do jogo (herói, Colosso, Imperador). A trilha é sintetizada aqui, no
ritmo dos cortes. No meio entram tomadas do jogo (cenas cine_/lento_ do filmar.py).

Saída: build/divulgacao/trailerfilme2_<lang>.mp4 (1920x1080, 60 qps).
"""
import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import trailer_cinema as tc  # noqa: E402  (cartelas, tomadas do jogo, concatenação)

RAIZ = tc.RAIZ
TMP = os.path.join(RAIZ, "build", "filmagem", "filme2")
SAIDA = tc.SAIDA
W, H, FPS = 480, 200, 60
tc.FAIXA = 140          # 1080 - 4x200 = 280: duas faixas de 140, igual às cenas desenhadas
SR = 48000

TXT = {
    "pt": {"c1": ("HOUVE TREZE.", ""), "c2": ("TODOS SE APAGARAM.", ""), "c3": ("VOCÊ É O QUE ELES DEIXARAM.", ""),
           "c4": ("O QUE GUARDA CADA PORTA", "não é um estranho."), "q1": ("13 DOMÍNIOS", ""), "q2": ("13 GUARDIÕES", ""),
           "imperador": "O Imperador Cego espera.", "genero": "ROGUELITE DE AÇÃO EM PIXEL ART"},
    "en": {"c1": ("THERE WERE THIRTEEN.", ""), "c2": ("ALL OF THEM WENT OUT.", ""), "c3": ("YOU ARE WHAT THEY LEFT BEHIND.", ""),
           "c4": ("WHAT GUARDS EACH DOOR", "is no stranger."), "q1": ("13 DOMAINS", ""), "q2": ("13 GUARDIANS", ""),
           "imperador": "The Blind Emperor is waiting.", "genero": "PIXEL-ART ACTION ROGUELITE"},
}

# ---------------------------------------------------------------- desenho

RNG = np.random.default_rng(13)
YY, XX = np.mgrid[0:H, 0:W]


def ease(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def ceu(paradas, faixa=5):
    """Gradiente vertical em faixas (pixel art sem pontilhado). paradas: [(y, (r,g,b)), ...]."""
    img = np.zeros((H, W, 3), np.float32)
    ys = [p[0] for p in paradas]
    cs = np.array([p[1] for p in paradas], np.float32)
    for y in range(H):
        yb = (y // faixa) * faixa
        img[y, :] = [np.interp(yb, ys, cs[:, k]) for k in range(3)]
    return img


def mistura(img, mascara, cor, alfa=1.0):
    m = mascara.astype(np.float32)[..., None] * alfa
    img[:] = img * (1 - m) + np.array(cor, np.float32) * m


def perfil(n, base, amp, semente, ondas=4):
    """Altura de duna por coluna (array longo, para deslizar)."""
    r = np.random.default_rng(semente)
    x = np.arange(n, dtype=np.float32)
    y = np.full(n, base, np.float32)
    for k in range(ondas):
        f = (0.004 + 0.011 * k) * (1 + r.random())
        y += amp / (k + 1) * np.sin(x * f + r.random() * 6.28)
    return y


def duna(img, alturas, cor, crista=None):
    alt = np.round(alturas).astype(int)[None, :]
    mask = YY >= alt
    mistura(img, mask, cor)
    if crista is not None:
        mistura(img, YY == alt, crista)


def disco(img, cx, cy, r, cor, alfa=1.0):
    mistura(img, (XX - cx) ** 2 + (YY - cy) ** 2 <= r * r, cor, alfa)


def sprite(caminho, caixa=None, escala=1.0):
    im = Image.open(caminho).convert("RGBA")
    if caixa:
        im = im.crop(caixa)
    im = im.crop(im.getbbox())
    if escala != 1.0:
        im = im.resize((max(1, round(im.width * escala)), max(1, round(im.height * escala))), Image.NEAREST)
    return np.asarray(im).astype(np.float32) / 255.0


def colar(img, spr, x, y, tinta=None, luz=1.0):
    """Cola um sprite RGBA (float 0..1) com o canto inferior-central em (x, y)."""
    h, w = spr.shape[:2]
    x0, y0 = int(round(x - w / 2)), int(round(y - h))
    xa, ya, xb, yb = max(x0, 0), max(y0, 0), min(x0 + w, W), min(y0 + h, H)
    if xa >= xb or ya >= yb:
        return
    s = spr[ya - y0:yb - y0, xa - x0:xb - x0]
    a = s[..., 3:4]
    cor = s[..., :3] * 255.0
    if tinta is not None:
        cor = tinta(cor)
    cor = cor * luz
    img[ya:yb, xa:xb] = img[ya:yb, xa:xb] * (1 - a) + cor * a


def silhueta(escuro, capa=None):
    """Silhueta contra a luz: tudo vira `escuro`, menos a capa vermelha (fica `capa`)."""
    def f(c):
        out = np.empty_like(c)
        out[:] = escuro
        if capa is not None:
            verm = (c[..., 0] > 140) & (c[..., 1] < 90) & (c[..., 2] < 110)
            out[verm] = capa
        return out
    return f


class Cinza:
    """Partículas de cinza levadas pelo vento."""

    def __init__(self, n, vento=(-40, 0), cor=(230, 200, 190), alfa=0.55, semente=1):
        r = np.random.default_rng(semente)
        self.p = np.c_[r.random(n) * W, r.random(n) * H]
        self.v = np.c_[vento[0] * (0.5 + r.random(n)), vento[1] + (r.random(n) - 0.5) * 8]
        self.fase = r.random(n) * 6.28
        self.cor, self.alfa = np.array(cor, np.float32), alfa
        self.grande = r.random(n) < 0.12

    def passo(self, img, t, dt):
        self.p += self.v * dt
        self.p[:, 1] += np.sin(t * 2 + self.fase) * 0.15
        self.p[:, 0] %= W
        self.p[:, 1] %= H
        x, y = self.p[:, 0].astype(int), self.p[:, 1].astype(int)
        img[y, x] = img[y, x] * (1 - self.alfa) + self.cor * self.alfa
        g = self.grande
        x2 = np.minimum(x[g] + 1, W - 1)
        img[y[g], x2] = img[y[g], x2] * (1 - self.alfa) + self.cor * self.alfa


def vinheta(img, forca=0.55):
    d = ((XX - W / 2) / (W / 2)) ** 2 + ((YY - H / 2) / (H / 1.6)) ** 2
    f = 1 - forca * np.clip(d - 0.45, 0, 1) ** 1.5
    img *= f[..., None]


HEROI_CORRE = [sprite(os.path.join(RAIZ, "site", "img", "heroi_corrida.png"), (i * 128, 0, i * 128 + 128, 128)) for i in range(8)]
HEROI_PARADO = sprite(os.path.join(RAIZ, "site", "img", "heroi.png"))
COLOSSO = sprite(os.path.join(RAIZ, "site", "img", "anim", "boss_colossus.png"), (0, 0, 188, 248))
IMPERADOR = sprite(os.path.join(RAIZ, "assets", "sprites", "emperor.png"), (0, 0, 140, 94), 2.0)


# ---------------------------------------------------------------- cenas (cada uma: função de t -> imagem)

def cena_mar(dur):
    """O Mar de Cinzas sem fim. Sol enorme, quatro camadas de duna, o herói minúsculo na crista."""
    fundo = ceu([(0, (24, 12, 28)), (70, (104, 42, 58)), (125, (206, 112, 88)), (150, (230, 150, 104))])
    longe = perfil(4000, 128, 9, 1)
    meio = perfil(4000, 146, 12, 2)
    perto = perfil(4000, 168, 13, 3)
    frente = perfil(4000, 190, 10, 4)
    cinza = Cinza(420, (-45, 0), semente=2)
    minis = [sprite(os.path.join(RAIZ, "site", "img", "heroi_corrida.png"), (i * 128, 0, i * 128 + 128, 128), 0.26) for i in range(8)]

    def f(t, dt):
        img = fundo.copy()
        sol_y = 118 - 4 * t / dur
        for r, a in ((62, 0.06), (50, 0.10), (42, 0.16)):
            disco(img, 300, sol_y, r, (250, 200, 160), a)
        disco(img, 300, sol_y, 34, (252, 222, 182))
        o = lambda v: int(t * v)
        duna(img, longe[o(3):o(3) + W], (118, 56, 70))
        duna(img, meio[o(8):o(8) + W], (78, 34, 50), (150, 76, 74))
        duna(img, perto[o(18):o(18) + W], (40, 18, 30), (120, 58, 58))
        # o herói anda pela crista da duna de perto (a câmera acompanha)
        hx = 150
        hy = perto[o(18) + hx]
        quadro = minis[int(t * 7) % 8]
        colar(img, quadro, hx, hy + 2, silhueta((16, 8, 16), (150, 32, 44)))
        duna(img, frente[o(34):o(34) + W], (14, 6, 12))
        cinza.passo(img, t, dt)
        vinheta(img, 0.5)
        return img * ease(t / 1.6)
    return f


def cena_tronos(dur, apagar):
    """Treze colossos sentados em tronos, em fila no horizonte. Os olhos apagam um a um."""
    fundo = ceu([(0, (6, 4, 10)), (70, (22, 10, 22)), (112, (92, 30, 44)), (124, (140, 52, 58)), (126, (30, 16, 24)),
                 (200, (10, 5, 9))], 3)
    r = np.random.default_rng(5)
    estrelas = np.c_[r.random(160) * W, r.random(160) * 90].astype(int)
    tronos = []
    for i in range(13):
        perto = 1 - abs(i - 6) / 6
        h = int(30 + 84 * perto ** 1.6)
        x = 240 + (i - 6) * (W - 50) / 12
        base = 125 - int((1 - perto) * 8)
        tronos.append((x, h, base))
    ordem = list(r.permutation(13))
    fumaca = []

    def caixa(x0, x1, y0, y1):
        return (XX >= x0) & (XX <= x1) & (YY >= y0) & (YY <= y1)

    def colosso(img, x, h, base, aceso, brilho):
        top = base - h
        # o trono: encosto alto com ponta, braços largos
        enc = caixa(x - h * 0.26, x + h * 0.26, top + h * 0.05, base)
        ponta = (YY >= top - h * 0.12) & (YY <= top + h * 0.06) & (np.abs(XX - x) <= (YY - (top - h * 0.12)) * 1.3)
        bracos = caixa(x - h * 0.34, x + h * 0.34, base - h * 0.42, base)
        trono = enc | ponta | bracos
        mistura(img, trono, (26, 11, 22))
        mistura(img, trono & ~np.roll(trono, 1, axis=0), (70, 28, 40))
        # o deus sentado, à frente do trono
        cab = ((XX - x) / (h * 0.075)) ** 2 + ((YY - (top + h * 0.24)) / (h * 0.085)) ** 2 <= 1
        tronco = (YY >= top + h * 0.32) & (YY <= base - h * 0.4) & \
            (np.abs(XX - x) <= h * (0.13 + 0.05 * (YY - top - h * 0.32) / (h * 0.3)))
        maos = caixa(x - h * 0.3, x + h * 0.3, base - h * 0.44, base - h * 0.37)
        coxas = caixa(x - h * 0.2, x + h * 0.2, base - h * 0.4, base - h * 0.3)
        canelas = caixa(x - h * 0.17, x - h * 0.05, base - h * 0.3, base) | caixa(x + h * 0.05, x + h * 0.17, base - h * 0.3, base)
        deus = cab | tronco | maos | coxas | canelas
        mistura(img, deus, (6, 3, 8))
        mistura(img, deus & ~np.roll(deus, 1, axis=0), (120, 48, 60))
        if aceso:
            ey = int(top + h * 0.235)
            dx = max(1, int(h * 0.03))
            tam = 1 if h < 70 else 2
            cor = (255, 150, 70) if brilho < 1.5 else (255, 240, 200)
            for sx in (-dx, dx):
                ex = int(x + sx)
                for rr, a in ((5 * tam, 0.08), (3 * tam, 0.18)):
                    disco(img, ex, ey, rr, (255, 120, 60), a * min(brilho, 1.8))
                img[ey:ey + tam, ex - tam // 2:ex - tam // 2 + tam] = cor

    def f(t, dt):
        img = fundo.copy()
        img[estrelas[:, 1], estrelas[:, 0]] = img[estrelas[:, 1], estrelas[:, 0]] * 0.4 + 60
        for j, (x, h, base) in sorted(enumerate(tronos), key=lambda e: e[1][1]):
            quando = apagar[ordem.index(j)]
            brilho = 1.0 + (2.2 if quando - 0.07 < t < quando else 0)
            colosso(img, x, h, base, t < quando, brilho)
            if quando <= t < quando + dt * 1.5:
                fumaca.extend([[x + RNG.normal() * 2, base - h * 0.76, RNG.normal() * 3, -6 - RNG.random() * 6] for _ in range(14)])
        for p in fumaca:
            p[0] += p[2] * dt
            p[1] += p[3] * dt
            xi, yi = int(p[0]), int(p[1])
            if 0 <= xi < W and 0 <= yi < H:
                img[yi, xi] = img[yi, xi] * 0.6 + np.array([120, 90, 96]) * 0.4
        vinheta(img, 0.5)
        return img * ease(t / 0.8) * (1 - ease((t - dur + 0.5) / 0.5))
    return f


def cena_brasa(dur):
    """Uma brasa na cinza. Ela acende, e o herói se ergue de dentro dela."""
    chao = 150
    cinza = Cinza(260, (-18, -3), (200, 180, 176), 0.45, semente=7)
    caindo = []
    hp = HEROI_PARADO

    def f(t, dt):
        img = ceu([(0, (2, 1, 4)), (120, (18, 8, 14)), (150, (34, 16, 20)), (200, (14, 8, 12))], 4)
        ondas = chao + 2 * np.sin(XX[0] * 0.05 + 1) + 1.2 * np.sin(XX[0] * 0.13)
        luz = ease((t - 1.0) / 2.0) * 0.8 + 0.2 + 0.08 * math.sin(t * 9)
        raio = 14 + 70 * ease((t - 1.6) / 2.4)
        d = np.sqrt((XX - 240) ** 2 + ((YY - chao) * 1.8) ** 2)
        calor = np.clip(1 - d / raio, 0, 1) * luz
        calor = np.round(calor * 6) / 6
        for k, (cor) in enumerate([(52, 40, 52), (38, 28, 40), (26, 18, 28)]):
            duna(img, ondas + k * 9, cor)
        img += calor[..., None] * np.array([150, 70, 30], np.float32)
        # o herói sobe: só aparece o que já saiu da cinza
        sobe = ease((t - 2.4) / 2.4)
        if sobe > 0:
            h = hp.shape[0]
            cima = int(h * sobe)
            pedaco = hp[:cima].copy()
            colar(img, pedaco, 240, chao + 1,
                  tinta=lambda c: np.clip(c * np.linspace(0.35, 1.25, c.shape[0])[:, None, None] * np.array([1.15, 0.9, 0.8]), 0, 255))
            if sobe < 1 and RNG.random() < 0.9:
                caindo.extend([[240 + RNG.normal() * 10, chao - cima + RNG.random() * cima, RNG.normal() * 4, 20 + RNG.random() * 20] for _ in range(4)])
        for p in caindo:
            p[0] += p[2] * dt
            p[1] += p[3] * dt
            xi, yi = int(p[0]), int(p[1])
            if 0 <= xi < W and 0 <= yi < chao:
                img[yi, xi] = (170, 150, 150)
        # a brasa
        pulso = 2 + int(1.5 + math.sin(t * 7) * 1.2)
        if sobe < 0.2:
            for rr, a in ((pulso + 6, 0.18), (pulso + 3, 0.35)):
                disco(img, 240, chao - 1, rr, (255, 140, 60), a)
            disco(img, 240, chao - 1, pulso, (255, 226, 160))
        cinza.passo(img, t, dt)
        vinheta(img, 0.7)
        img = np.clip(img, 0, 255)
        return img * ease(t / 0.8) * (1 - ease((t - dur + 0.6) / 0.6))
    return f


def cena_guardiao(dur, acende):
    """Um guardião imenso sobe atrás da duna. O herói, pequeno, de costas para nós."""
    fundo = ceu([(0, (14, 6, 12)), (80, (70, 26, 36)), (140, (190, 84, 62)), (160, (220, 120, 80))])
    crista = perfil(800, 158, 6, 9)[:W]
    col = COLOSSO
    topo_vis = col[: col.shape[0] // 3, :, 3] > 0.5
    linhas = np.where(topo_vis.any(axis=1))[0]
    cab_y = linhas[0] + 14
    xs = np.where(col[cab_y, :, 3] > 0.5)[0]
    cab_x = (xs.min() + xs.max()) / 2 if len(xs) else col.shape[1] / 2
    pequeno = sprite(os.path.join(RAIZ, "site", "img", "heroi.png"), None, 0.5)
    poeira = []

    def f(t, dt):
        img = fundo.copy()
        disco(img, 300, 150, 52, (250, 196, 150), 0.18)
        disco(img, 300, 150, 30, (252, 220, 176))
        sobe = ease((t - 0.3) / 3.8)
        base = 158 + col.shape[0] - int(col.shape[0] * 0.64 * sobe)
        tremor = int(round(math.sin(t * 40) * (1.0 if 0.3 < t < 4.1 else 0)))
        colar(img, col, 240 + tremor, base, silhueta((14, 6, 12)))
        ox = 240 - col.shape[1] / 2 + tremor
        oy = base - col.shape[0]
        if t > acende:
            k = 1 + 2.5 * max(0, 0.12 - (t - acende)) / 0.12
            for sx in (-4, 4):
                ex, ey = int(ox + cab_x + sx), int(oy + cab_y)
                if 0 <= ey < H:
                    disco(img, ex, ey, 6, (255, 80, 50), 0.18 * k)
                    img[ey:ey + 2, ex:ex + 2] = (255, 110, 70) if k < 1.5 else (255, 240, 210)
        if 0.3 < t < 4.2 and RNG.random() < 0.5:
            poeira.extend([[ox + col.shape[1] * (0.2 + 0.6 * RNG.random()), oy + 50 + RNG.random() * 20, RNG.normal() * 3,
                            30 + RNG.random() * 30] for _ in range(2)])
        for p in poeira:
            p[0] += p[2] * dt
            p[1] += p[3] * dt
            xi, yi = int(p[0]), int(p[1])
            if 0 <= xi < W and 0 <= yi < H:
                img[yi, xi] = (60, 30, 36)
        duna(img, crista, (12, 6, 10), (90, 40, 44))
        colar(img, pequeno, 300, crista[300] + 1, silhueta((10, 4, 8), (150, 30, 42)))
        vinheta(img, 0.55)
        return img * ease(t / 0.6) * (1 - ease((t - dur + 0.4) / 0.4))
    return f


def cena_tempestade(dur, raios):
    """Tempestade de cinza: uma muralha de nuvens de pó rolando. O herói corre contra ela."""
    chao = perfil(9000, 172, 6, 11)
    r = np.random.default_rng(12)
    camadas = []
    for vel, cor, luz, alto in ((50, (132, 70, 56), (170, 100, 76), 20), (110, (100, 50, 44), (140, 76, 62), 46),
                                (200, (66, 32, 32), (100, 50, 44), 80)):
        n = 40
        camadas.append((vel, cor, luz, r.random(n) * 900, alto + r.random(n) * 40, 16 + r.random(n) * 26))
    riscos = Cinza(500, (-420, 6), (230, 190, 170), 0.5, semente=13)

    def f(t, dt):
        img = ceu([(0, (40, 20, 22)), (90, (150, 76, 54)), (170, (196, 112, 76))], 5)
        relampago = any(q <= t < q + 0.12 for q in raios)
        if relampago:
            img[:] = img * 0.6 + 100
        for vel, cor, luz, xs, ys, rs in camadas:
            m = np.zeros((H, W), bool)
            for x0, y0, rr in zip(xs, ys, rs):
                x = (x0 - t * vel) % 900 - 200
                if x < 150:          # a muralha fica à direita
                    continue
                yy = y0 - (x - 150) * 0.25
                m |= ((XX - x) ** 2 + (YY - yy) ** 2 <= rr * rr) | ((XX >= x - rr) & (XX <= x + rr) & (YY >= yy))
            mistura(img, m & (YY < 178), cor)
            mistura(img, m & ~np.roll(m, 2, axis=0) & (YY < 178), luz)
        for q in raios:
            if q <= t < q + 0.12:
                y, x = 10, int(330 + (q * 97) % 100)
                while y < 150:
                    img[y:y + 3, x:x + 2] = (255, 250, 240)
                    y += 3
                    x += int(RNG.integers(-3, 4))
        duna(img, chao[int(t * 160):int(t * 160) + W], (34, 16, 20), (110, 54, 48))
        quadro = HEROI_CORRE[int(t * 14) % 8]
        colar(img, quadro, 150, chao[int(t * 160) + 150] + 2, luz=0.75)
        riscos.passo(img, t, dt)
        vinheta(img, 0.45)
        return np.clip(img, 0, 255)
    return f


def cena_imperador(dur):
    """O Imperador Cego num salão escuro, um feixe de luz de cima."""
    poeira = Cinza(140, (4, 6), (255, 230, 200), 0.5, semente=21)
    emp = IMPERADOR

    def f(t, dt):
        img = np.zeros((H, W, 3), np.float32) + np.array([6, 3, 8], np.float32)
        trono = ((XX >= 170) & (XX <= 310) & (YY >= 40) & (YY <= 196)) | ((XX >= 140) & (XX <= 340) & (YY >= 120) & (YY <= 196))
        for px, alt in ((180, 22), (205, 34), (240, 48), (275, 34), (300, 22)):
            trono |= (YY >= 40 - alt) & (YY < 40) & (np.abs(XX - px) <= (YY - (40 - alt)) * 0.45)
        mistura(img, trono, (24, 12, 24))
        mistura(img, trono & ~np.roll(trono, 1, axis=0), (70, 40, 60))
        larg = 46 + (YY * 0.18)
        dx = np.abs(XX - 240)
        feixe = np.clip(1 - dx / larg, 0, 1)
        feixe = np.round(feixe * 4) / 4 * (0.22 + 0.03 * math.sin(t * 1.3))
        img += feixe[..., None] * np.array([255, 226, 196], np.float32)
        desce = 6 * ease(t / dur)
        colar(img, emp, 240, 196 + desce,
              tinta=lambda c: c * np.linspace(1.3, 0.45, c.shape[0])[:, None, None] * np.array([1.0, 0.92, 0.88]))
        chao = YY >= 196
        mistura(img, chao, (10, 6, 12))
        m = poeira.p
        dentro = np.abs(m[:, 0] - 240) < 50
        m[~dentro, 0] = 240 + (RNG.random((~dentro).sum()) - 0.5) * 90
        poeira.passo(img, t, dt)
        vinheta(img, 0.7)
        return np.clip(img, 0, 255) * ease(t / 1.2) * (1 - ease((t - dur + 0.8) / 0.8))
    return f


def cena_logo(dur, mascara):
    """Brasas espalhadas se juntam e formam MOKSHA."""
    alvos = np.argwhere(mascara)
    n = len(alvos)
    r = np.random.default_rng(31)
    ini = np.c_[r.random(n) * H, r.random(n) * W]
    atraso = r.random(n) * 0.9
    cinza = Cinza(200, (-20, -4), (200, 170, 160), 0.35, semente=32)

    def f(t, dt):
        img = np.zeros((H, W, 3), np.float32) + np.array([5, 3, 6], np.float32)
        cinza.passo(img, t, dt)
        k = np.clip((t - 0.4 - atraso) / 2.6, 0, 1)
        k = k * k * (3 - 2 * k)
        pos = ini * (1 - k[:, None]) + alvos * k[:, None]
        y, x = np.clip(pos[:, 0].astype(int), 0, H - 1), np.clip(pos[:, 1].astype(int), 0, W - 1)
        chegou = k >= 1
        quente = np.array([255, 120, 50], np.float32)
        ouro = np.array([242, 193, 78], np.float32)
        brilho = ease((t - 3.4) / 0.4)
        cor = quente * (1 - chegou[:, None]) + ouro * chegou[:, None]
        if brilho > 0:
            sy, sx = np.clip(y + 3, 0, H - 1), x
            img[sy[chegou], sx[chegou]] = (122, 74, 16)
        img[y, x] = cor
        if 3.3 < t < 3.6:
            img[:] = img + (1 - abs(t - 3.45) / 0.15) * 90
        return np.clip(img, 0, 255) * (1 - ease((t - dur + 0.6) / 0.6))
    return f


def gravar(nome, funcao, dur, t0=0.0):
    """Desenha a cena quadro a quadro e grava em 1920x1080 com as faixas pretas."""
    arq = os.path.join(TMP, nome + ".mp4")
    if os.path.exists(arq) and "--refazer-cenas" not in sys.argv:
        return arq
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", "%dx%d" % (W, H),
           "-r", str(FPS), "-i", "-", "-vf", "scale=1920:800:flags=neighbor,pad=1920:1080:0:140:black,format=yuv420p"] + \
        tc.QUALIDADE + [arq]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    dt = 1.0 / FPS
    # avança sem gravar até t0 (para pegar um pedaço do meio da cena)
    t = 0.0
    while t < t0 - 1e-6:
        funcao(t, dt)
        t += dt
    for i in range(int(round(dur * FPS))):
        img = funcao(t0 + i * dt, dt)
        p.stdin.write(np.clip(img, 0, 255).astype(np.uint8).tobytes())
    p.stdin.close()
    p.wait()
    print("  cena", nome, "%.1f s" % dur)
    return arq


def legendar(arq, letreiro, dur, ini=0.4):
    out = arq.replace(".mp4", "_leg.mp4")
    tc.ffmpeg("-i", arq, "-loop", "1", "-t", dur, "-i", letreiro, "-filter_complex",
              "[1:v]format=rgba,fade=t=in:st=%g:d=0.5:alpha=1,fade=t=out:st=%g:d=0.5:alpha=1[l];[0:v][l]overlay=0:0,format=yuv420p[v]"
              % (ini, dur - 0.8), "-map", "[v]", "-t", dur, *tc.QUALIDADE, out)
    return out


# ---------------------------------------------------------------- som

def ler_wav(caminho):
    with wave.open(caminho) as w:
        n, ch, sw = w.getnframes(), w.getnchannels(), w.getsampwidth()
        x = np.frombuffer(w.readframes(n), np.int16 if sw == 2 else np.uint8).astype(np.float32)
        sr = w.getframerate()
    x = x / 32768.0
    if ch == 2:
        x = x.reshape(-1, 2).mean(axis=1)
    if sr != SR:
        x = np.interp(np.arange(int(len(x) * SR / sr)) * sr / SR, np.arange(len(x)), x)
    return x


def filtro(x, f_baixo=None, f_alto=None):
    """Passa-faixa por FFT (suave)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    g = np.ones_like(f)
    if f_alto:
        g *= 1 / (1 + (f / f_alto) ** 4)
    if f_baixo:
        g *= 1 / (1 + (f_baixo / np.maximum(f, 1)) ** 4)
    return np.fft.irfft(X * g, len(x))


def serra(freq, n, detune=0.0):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for d in (-detune, 0, detune):
        ph = (t * freq * (1 + d)) % 1.0
        out += 2 * ph - 1
    return out / 3


def braam(dur=4.5, fund=36.7, forca=1.0):
    """O grave de metal dos trailers: serras graves desafinadas, filtro que abre e fecha."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    src = sum(serra(fund * m, n, 0.006 * m) / m ** 0.5 for m in (1, 2, 3, 4))
    escuro, claro = filtro(src, f_alto=260), filtro(src, f_alto=1600)
    abre = np.clip(t / 0.35, 0, 1) * np.exp(-t / 1.1)
    x = escuro * (1 - abre) + claro * abre
    env = np.minimum(t / 0.06, 1) * np.exp(-t / (dur * 0.45))
    x = np.tanh(x * env * 3.0 * forca) * 0.8
    sub = np.sin(2 * np.pi * fund * t) * np.exp(-t / 1.6) * 0.7 * forca
    return x + sub


def tambor(f0=90, f1=42, dur=1.2, forca=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    freq = f1 + (f0 - f1) * np.exp(-t / 0.06)
    ph = 2 * np.pi * np.cumsum(freq) / SR
    corpo = np.sin(ph) * np.exp(-t / 0.35)
    estalo = filtro(RNG.normal(size=n) * np.exp(-t / 0.015), f_alto=2500) * 0.6
    return np.tanh((corpo + estalo) * 1.6 * forca) * 0.9


def coracao():
    a = tambor(60, 38, 0.5, 0.8)
    out = np.zeros(int(0.8 * SR))
    out[:len(a)] += a
    b = tambor(55, 36, 0.5, 0.6)
    k = int(0.2 * SR)
    out[k:k + len(b)] += b[:len(out) - k]
    return out


def coro(dur, nota=110.0, vogal=(450, 800, 2830)):
    """Uma voz grave, sem palavras (pulso filtrado em formantes)."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5 * t)
    ph = np.cumsum(nota * vib) / SR
    src = sum((2 * ((ph * m) % 1) - 1) / m for m in (1, 1.5, 2)) / 2
    X = np.fft.rfft(src)
    f = np.fft.rfftfreq(n, 1 / SR)
    g = sum(np.exp(-((f - c) / (c * 0.12)) ** 2) * a for c, a in zip(vogal, (1.0, 0.6, 0.2)))
    x = np.fft.irfft(X * g, n)
    env = np.minimum(t / (dur * 0.35), 1) * np.minimum((dur - t) / (dur * 0.35), 1)
    return x / (np.abs(x).max() + 1e-9) * env * 0.5


def vento(dur):
    n = int(dur * SR)
    x = filtro(RNG.normal(size=n), f_baixo=120, f_alto=900)
    t = np.arange(n) / SR
    rajada = 0.55 + 0.45 * np.sin(2 * np.pi * t / 7.3) * np.sin(2 * np.pi * t / 3.1 + 1)
    return x / (np.abs(x).max() + 1e-9) * rajada * 0.25


def zumbido(dur, fund=36.7):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = filtro(serra(fund, n, 0.004) + 0.5 * serra(fund * 1.5, n, 0.003), f_alto=180)
    return x * (0.6 + 0.4 * np.sin(2 * np.pi * t / 5)) * 0.5


def subida(dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    pedacos = np.zeros(n)
    passos = 24
    for i in range(passos):
        a, b = int(i * n / passos), int((i + 1) * n / passos)
        c = 200 * (2 ** (i / passos * 4))
        pedacos[a:b] = filtro(RNG.normal(size=b - a), f_baixo=c * 0.7, f_alto=c * 1.4)
    ph = 2 * np.pi * np.cumsum(80 * 2 ** (t / dur * 3)) / SR
    return (pedacos / (np.abs(pedacos).max() + 1e-9) * 0.35 + np.sin(ph) * 0.25) * (t / dur) ** 2


def reverb(x, segundos=3.0, molhado=0.35):
    n = int(segundos * SR)
    t = np.arange(n) / SR
    ir = RNG.normal(size=n) * np.exp(-t / (segundos / 5))
    ir = filtro(ir, f_alto=4000)
    ir /= np.sqrt((ir ** 2).sum())
    m = len(x) + n
    tam = 1 << (m - 1).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, tam) * np.fft.rfft(ir, tam), tam)[:len(x)]
    return x * (1 - molhado) + y * molhado * 3


def trilha(total, eventos, faixas):
    """eventos: [(segundos, array, volume)]; faixas: camadas longas [(ini, array, volume)]."""
    n = int(total * SR) + SR
    mix = np.zeros(n)
    for ini, x, vol in list(eventos) + list(faixas):
        a = int(ini * SR)
        b = min(n, a + len(x))
        if b > a:
            mix[a:b] += x[:b - a] * vol
    mix = reverb(mix, 3.2, 0.3)
    # sem esmagar: só normaliza o pico (o grave forte fica forte porque o resto é baixo)
    mix = mix / (np.abs(mix).max() + 1e-9)
    mix = np.tanh(mix * 1.4) / np.tanh(1.4) * 0.89
    estereo = np.c_[mix, np.roll(mix, int(0.011 * SR))]   # um pouco de largura
    return (estereo[:int(total * SR)] * 32767).astype(np.int16)


def salvar_wav(caminho, dados):
    with wave.open(caminho, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(dados.tobytes())


# ---------------------------------------------------------------- montagem

def mascara_logo(pg):
    pg.set_viewport_size({"width": W, "height": H})
    pg.set_content("<html><head><style>@import url('https://fonts.googleapis.com/css2?family=Silkscreen:wght@700&display=swap');"
                   "html,body{margin:0;background:#000;width:480px;height:200px;display:grid;place-content:center}"
                   "div{font:700 74px 'Silkscreen';color:#fff;letter-spacing:4px}</style></head><body><div>MOKSHA</div></body></html>")
    pg.evaluate("document.fonts.ready")
    pg.wait_for_timeout(400)
    arq = os.path.join(TMP, "logo_mascara.png")
    pg.screenshot(path=arq)
    return np.asarray(Image.open(arq).convert("L")) > 128


def trailer(lang, L, cenas, pg_logo):
    t = TXT[lang]
    m = tc.Montagem()
    ev = []          # (segundos, som, volume)
    sfx = os.path.join(RAIZ, "assets", "sfx")

    def cena(arq, dur, leg=None):
        if leg:
            arq = legendar(arq, leg, dur)
        m.partes.append(arq)
        m.t += dur

    def preto(dur):
        m.cartela(L.cartela("", ""), dur)

    preto(1.6)
    ev.append((0.0, vento(200), 1.0))
    ev.append((0.8, zumbido(32), 0.8))
    cena(cenas["mar"], 8.0)
    ev.append((m.t, braam(5.0), 1.0))
    m.cartela(L.cartela(*t["c1"]), 2.6)
    ev.append((m.t, zumbido(8, 32.7), 0.6))
    for q in APAGAR:
        ev.append((m.t + q, tambor(110, 50, 1.0, 0.8), 0.8))
    cena(cenas["tronos"], 7.0)
    ev.append((m.t, braam(5.0, 32.7), 1.0))
    m.cartela(L.cartela(*t["c2"]), 2.6)
    ev.append((m.t, coro(7.0, 98), 0.9))
    ev.append((m.t + 0.5, coro(6.5, 147, (400, 750, 2600)), 0.5))
    cena(cenas["brasa"], 6.4)
    ev.append((m.t, braam(6.0, 36.7, 1.3), 1.2))
    m.cartela(L.cartela(*t["c3"]), 3.0)
    ev.append((m.t + ACENDE, braam(5.0, 30.9, 1.2), 1.1))
    ev.append((m.t + 0.2, tambor(70, 30, 3.0, 0.6), 0.7))
    cena(cenas["guardiao"], 6.0)
    m.cartela(L.cartela(*t["c4"]), 3.0)

    # Ato 2: cortes rápidos, tambores no pulso
    ato2 = m.t
    seq = [("tormenta", 0.0, 1.4), ("cine_mar_de_cinzas", 6.0, 1.2), ("lento_lobo", 13.5, 1.4), ("tormenta", 1.4, 1.1),
           ("cine_carcosa", 7.5, 1.1), ("lento_dragao_sonhado", 11.5, 1.4), ("q1", 0, 1.3), ("lento_colosso", 9.0, 1.2),
           ("cine_torre_babel", 13.5, 1.0), ("lento_rei_sem_rosto", 18.0, 1.2), ("q2", 0, 1.3), ("lento_astronomo", 11.0, 1.2),
           ("tormenta", 3.0, 1.4), ("lento_mae_raiz", 7.5, 1.0), ("cine_ventre", 10.0, 0.9), ("lento_insaciavel", 10.0, 0.8),
           ("lento_o_que_responde", 14.0, 0.8)]
    braams_em = {0, 5, 12}
    for i, (c, ini, dur) in enumerate(seq):
        if i in braams_em:
            ev.append((m.t, braam(3.5, 36.7, 1.1), 1.0))
        if c == "tormenta":
            cena(cenas["tormenta_%g" % ini], dur)
        elif c in ("q1", "q2"):
            m.cartela(L.cartela(*t[c]), dur)
        else:
            m.tomada(c, ini, dur, flash=i in braams_em)
    fim_ato2 = m.t
    batida = 60 / 100
    k = ato2
    while k < fim_ato2 - 0.05:
        ev.append((k, tambor(95, 45, 0.9, 1.0), 0.9))
        ev.append((k + batida / 2, tambor(160, 90, 0.4, 0.5), 0.45))
        k += batida
    ev.append((fim_ato2 - 3.0, subida(3.0), 1.0))
    # corte seco para o silêncio
    preto(1.2)
    for b in np.arange(0.3, 6.8, 0.9):
        ev.append((m.t + b, coracao(), 0.9))
    ev.append((m.t + 0.4, coro(6.2, 82, (500, 900, 2700)), 0.7))
    cena(cenas["imperador"], 7.0, L.legenda(t["imperador"]))
    preto(1.0)
    ev.append((m.t + 3.35, braam(7.0, 27.5, 1.5), 1.3))
    ev.append((m.t + 3.35, ler_wav(os.path.join(sfx, "bell.wav")), 0.6))
    ev.append((m.t, zumbido(6), 0.5))
    cena(cenas["logo"], 6.0, L.png("<div class='centro' style='padding-top:520px'><div class='genero'>%s</div></div>" % t["genero"]))
    ev.append((m.t, coro(5.5, 110), 0.5))
    m.cartela(L.final(tc.TXT[lang]), 5.5)

    wav = os.path.join(TMP, "trilha_%s.wav" % lang)
    salvar_wav(wav, trilha(m.t, ev, []))
    m.sons = []
    m.fechar(os.path.join(SAIDA, "trailerfilme2_%s.mp4" % lang), [(wav, 0.0, m.t, 0.05, 1.5, 1.0, 0)])


APAGAR = [1.0 + i * 0.36 + (0.12 if i > 8 else 0) * (i - 8) for i in range(13)]
ACENDE = 4.0
RAIOS = [1.7, 2.1, 3.5]


def main():
    langs = [a for a in sys.argv[1:] if a in TXT] or list(TXT)
    os.makedirs(TMP, exist_ok=True)
    with sync_playwright() as p:
        nav = p.chromium.launch(channel="chrome", args=["--headless=new"])
        pg = nav.new_page(viewport={"width": 1920, "height": 1080})
        mascara = mascara_logo(nav.new_page())
        print("desenhando as cenas...")
        cenas = {
            "mar": gravar("mar", cena_mar(8.0), 8.0),
            "tronos": gravar("tronos", cena_tronos(7.0, APAGAR), 7.0),
            "brasa": gravar("brasa", cena_brasa(6.4), 6.4),
            "guardiao": gravar("guardiao", cena_guardiao(6.0, ACENDE), 6.0),
            "imperador": gravar("imperador", cena_imperador(7.0), 7.0),
            "logo": gravar("logo", cena_logo(6.0, mascara), 6.0),
        }
        for ini, dur in ((0.0, 1.4), (1.4, 1.1), (3.0, 1.4)):
            cenas["tormenta_%g" % ini] = gravar("tormenta_%g" % ini, cena_tempestade(5.0, RAIOS), dur, ini)
        for lang in langs:
            tc.os.makedirs(tc.TMP, exist_ok=True)
            trailer(lang, tc.Letreiros(pg), cenas, None)
        nav.close()


if __name__ == "__main__":
    main()
