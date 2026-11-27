"""Regrava no tamanho final as folhas que o jogo desenhava com escala.

    python tools/reescalar_folhas.py                    regrava as que ainda têm draw_scale no .json
    python tools/reescalar_folhas.py --previa           só monta build/auditoria/reescala.png
    python tools/reescalar_folhas.py --previa --de P    idem, lendo as folhas originais da pasta P

Folha com "draw_scale" no .json é ampliada ou reduzida pelo jogo na hora de
desenhar, com filtro nearest: o pixel dela sai dobrado, ou falhado, ao lado do
resto do jogo. Aqui cada quadro é refeito já no tamanho em que aparece
(round(w*s) x round(h*s)); a grade continua a mesma, o pé continua no centro
de baixo da célula (duas linhas acima do fundo, que é onde o jogo o procura)
e o draw_scale sai do .json. Rodar de novo não muda nada.

Cada faixa de escala tem duas candidatas (a prévia mostra as duas ao lado do
que o jogo mostrava; ESCOLHA guarda a que ficou):
  2x          A Scale2x, B MMPX: ampliadores de pixel art, alisam o degrau em
              vez de dobrar o pixel
  1,x         A Scale3x, B MMPX; depois cada pixel leva a cor que mais o cobre
  0,5 a 0,8   A média por área levada de volta à paleta da folha, B a cor que
              mais cobre o pixel. Nas duas: traço de 1 px que se destaca entra
              inteiro num pixel só (não some nem borra), o limiar de 50% não
              parte o que é fino, e folha contornada tem o contorno tirado
              antes e passado de novo, com 1 px, em volta do que sobrou
O resultado só tem alfa 0 ou 255 e cores que a folha já tinha.

O relevo (_n.png) das folhas regravadas é refeito por gen_normais. A emissão
(_e.png) é levada junto: brilha o pixel novo cuja cor veio de um pixel que
brilhava. gen_emissao.py refaz do zero, mas escolhe outros pixels na folha
nova (o critério dele depende do tamanho do desenho).

importar_inimigos.py chama regravar() no fim, para a folha recém-importada
não voltar a depender do draw_scale.
"""
import argparse
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import gen_normais

RAIZ = os.path.join(os.path.dirname(__file__), "..")
SPR = os.path.join(RAIZ, "assets", "sprites")
PREVIA = os.path.join(RAIZ, "build", "auditoria", "reescala.png")

# candidata que ficou em cada folha, decidida olhando a prévia
ESCOLHA = {
    # o astronomer fica como está (pixel dobrado na hora de desenhar): em escala inteira a
    # folha passa de 6 milhões de pixels, 23 MB por textura, e ele usa cinco
    "faceless_king": "B",
    "boss_answer": "A", "boss_forgotten": "A",
    "elite_glutton": "B", "highwayman": "B", "incubus": "B", "nightmare": "B", "prayer": "B",
}
ROTULOS = {
    "dobro": ("Scale2x", "MMPX"),
    "amplia": ("Scale3x + voto", "MMPX + voto"),
    "reduz": ("média por área + paleta", "voto por área"),
}
CONTRASTE_DO_TRACO = 0.14     # distância Oklab a partir da qual um traço de 1 px é preservado
COBERTURA_MINIMA = 0.15       # abaixo disso o pixel nem concorre a ficar opaco
# os oito vizinhos, em volta, a partir da direita (afina() depende da ordem)
ANEL = [(0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1)]


def arred(x):
    return int(x + 0.5)


def empacota(a):
    """RGBA -> um inteiro por pixel. Alfa abaixo da metade vira 0 (vazio); o resto fica opaco."""
    c = a.astype(np.uint32)
    rgb = c[..., 0] | (c[..., 1] << 8) | (c[..., 2] << 16)
    return np.where(a[..., 3] >= 128, rgb | np.uint32(0xFF000000), np.uint32(0))


def desempacota(u):
    return np.stack([(u >> k) & 255 for k in (0, 8, 16, 24)], axis=-1).astype(np.uint8)


def luz(u):
    return 0.299 * (u & 255) + 0.587 * ((u >> 8) & 255) + 0.114 * ((u >> 16) & 255)


def viz(m, dy, dx):
    """m deslocada: o vizinho (dy, dx) de cada pixel. Fora da célula é vazio."""
    p = np.pad(m, 3)
    h, w = m.shape
    return p[3 + dy:3 + dy + h, 3 + dx:3 + dx + w]


def scale2x(u):
    a, b, c, d = viz(u, -1, 0), viz(u, 0, 1), viz(u, 0, -1), viz(u, 1, 0)
    o = np.empty((u.shape[0] * 2, u.shape[1] * 2), u.dtype)
    o[0::2, 0::2] = np.where((c == a) & (c != d) & (a != b), a, u)
    o[0::2, 1::2] = np.where((a == b) & (a != c) & (b != d), b, u)
    o[1::2, 0::2] = np.where((d == c) & (d != b) & (c != a), c, u)
    o[1::2, 1::2] = np.where((b == d) & (b != a) & (d != c), d, u)
    return o


def scale3x(u):
    a, b, c = viz(u, -1, -1), viz(u, -1, 0), viz(u, -1, 1)
    d, e, f = viz(u, 0, -1), u, viz(u, 0, 1)
    g, h, i = viz(u, 1, -1), viz(u, 1, 0), viz(u, 1, 1)
    db = (d == b) & (d != h) & (b != f)
    bf = (b == f) & (b != d) & (f != h)
    hd = (h == d) & (h != f) & (d != b)
    fh = (f == h) & (f != b) & (h != d)
    o = np.empty((u.shape[0] * 3, u.shape[1] * 3), u.dtype)
    o[0::3, 0::3] = np.where(db, d, e)
    o[0::3, 1::3] = np.where((db & (e != c)) | (bf & (e != a)), b, e)
    o[0::3, 2::3] = np.where(bf, f, e)
    o[1::3, 0::3] = np.where((hd & (e != a)) | (db & (e != g)), d, e)
    o[1::3, 1::3] = e
    o[1::3, 2::3] = np.where((bf & (e != i)) | (fh & (e != c)), f, e)
    o[2::3, 0::3] = np.where(hd, d, e)
    o[2::3, 1::3] = np.where((fh & (e != g)) | (hd & (e != i)), h, e)
    o[2::3, 2::3] = np.where(fh, f, e)
    return o


def mmpx(u):
    """MMPX (McGuire e Gagiu, 2021): um EPX que respeita quem é mais escuro e alisa também o degrau 2:1."""
    def v(dy, dx):
        return viz(u, dy, dx)

    def peso(c):   # o vazio conta como claro: é o desenho que avança sobre ele
        return ((c & 255).astype(np.int64) + ((c >> 8) & 255) + ((c >> 16) & 255) + 1) * (256 - ((c >> 24) & 255).astype(np.int64))

    def algum(x, a, b, c):
        return (x == a) | (x == b) | (x == c)

    def todos(x, *outros):
        r = x == outros[0]
        for o in outros[1:]:
            r = r & (x == o)
        return r

    def nenhum(x, *outros):
        r = x != outros[0]
        for o in outros[1:]:
            r = r & (x != o)
        return r

    a, b, c = v(-1, -1), v(-1, 0), v(-1, 1)
    d, e, f = v(0, -1), u, v(0, 1)
    g, h, i = v(1, -1), v(1, 0), v(1, 1)
    p, s, q, r = v(-2, 0), v(2, 0), v(0, -2), v(0, 2)
    bl, dl, el, fl, hl = peso(b), peso(d), peso(e), peso(f), peso(h)
    j, k, l, m = e, e, e, e

    # degrau 1:1
    j = np.where((d == b) & (d != h) & (d != f) & ((el >= dl) | (e == a)) & algum(e, a, c, g) & ((el < dl) | (a != d) | (e != p) | (e != q)), d, j)
    k = np.where((b == f) & (b != d) & (b != h) & ((el >= bl) | (e == c)) & algum(e, a, c, i) & ((el < bl) | (c != b) | (e != p) | (e != r)), b, k)
    l = np.where((h == d) & (h != f) & (h != b) & ((el >= hl) | (e == g)) & algum(e, a, g, i) & ((el < hl) | (g != h) | (e != s) | (e != q)), h, l)
    m = np.where((f == h) & (f != b) & (f != d) & ((el >= fl) | (e == i)) & algum(e, c, g, i) & ((el < fl) | (i != h) | (e != r) | (e != s)), f, m)

    # cruzamentos
    t = (e != f) & todos(e, c, i, d, q) & todos(f, b, h) & (f != v(0, 3))
    k, m = np.where(t, f, k), np.where(t, f, m)
    t = (e != d) & todos(e, a, g, f, r) & todos(d, b, h) & (d != v(0, -3))
    j, l = np.where(t, d, j), np.where(t, d, l)
    t = (e != h) & todos(e, g, i, b, p) & todos(h, d, f) & (h != v(3, 0))
    l, m = np.where(t, h, l), np.where(t, h, m)
    t = (e != b) & todos(e, a, c, h, s) & todos(b, d, f) & (b != v(-3, 0))
    j, k = np.where(t, b, j), np.where(t, b, k)
    t = (bl < el) & todos(e, g, h, i, s) & nenhum(e, a, d, c, f)
    j, k = np.where(t, b, j), np.where(t, b, k)
    t = (hl < el) & todos(e, a, b, c, p) & nenhum(e, d, g, i, f)
    l, m = np.where(t, h, l), np.where(t, h, m)
    t = (fl < el) & todos(e, a, d, g, q) & nenhum(e, b, c, i, h)
    k, m = np.where(t, f, k), np.where(t, f, m)
    t = (dl < el) & todos(e, c, f, i, r) & nenhum(e, b, a, g, h)
    j, l = np.where(t, d, j), np.where(t, d, l)

    # degrau 2:1
    t = (h != b) & nenhum(h, a, e, c)
    l = np.where(t & todos(h, g, f, r) & nenhum(h, d, v(-1, 2)), m, l)
    m = np.where(t & todos(h, i, d, q) & nenhum(h, f, v(-1, -2)), l, m)
    t = (h != b) & nenhum(b, i, g, e)
    j = np.where(t & todos(b, a, f, r) & nenhum(b, d, v(1, 2)), k, j)
    k = np.where(t & todos(b, c, d, q) & nenhum(b, f, v(1, -2)), j, k)
    t = (f != d) & nenhum(d, i, e, c)
    j = np.where(t & todos(d, a, h, s) & nenhum(d, b, v(2, 1)), l, j)
    l = np.where(t & todos(d, g, b, p) & nenhum(d, h, v(-2, 1)), j, l)
    t = (f != d) & nenhum(f, e, a, g)
    k = np.where(t & todos(f, c, h, s) & nenhum(f, b, v(2, -1)), m, k)
    m = np.where(t & todos(f, i, b, p) & nenhum(f, h, v(-2, -1)), k, m)

    o = np.empty((u.shape[0] * 2, u.shape[1] * 2), u.dtype)
    o[0::2, 0::2], o[0::2, 1::2], o[1::2, 0::2], o[1::2, 1::2] = j, k, l, m
    return o


class Pegada:
    """Para cada pixel de destino, os pixels de origem que ele cobre.

    iy, ix   índices na origem, (H, W, K)
    peso     fração da área do pixel de destino que cada um ocupa (fora da célula = 0)
    centro   True onde o centro do pixel de origem cai dentro do de destino
    `folga` alarga a pegada, em pixels de origem, para cada lado.
    """

    def __init__(self, forma, tam, s, anc_src, anc_dst, folga=0.0):
        ey = self._eixo(forma[0], tam[1], s, anc_src[1], anc_dst[1], folga)
        ex = self._eixo(forma[1], tam[0], s, anc_src[0], anc_dst[0], folga)

        def junta(y, x, op):
            return op(y[:, None, :, None], x[None, :, None, :]).reshape(tam[1], tam[0], -1)

        self.iy = junta(ey[0], np.zeros_like(ex[0]), np.add)
        self.ix = junta(np.zeros_like(ey[0]), ex[0], np.add)
        self.peso = junta(ey[1], ex[1], np.multiply)
        self.centro = junta(ey[2], ex[2], np.logical_and)

    @staticmethod
    def _eixo(n_src, n_dst, s, a_src, a_dst, folga):
        ini = (np.arange(n_dst) - a_dst) / s + a_src
        lo, hi = ini - folga, ini + 1 / s + folga
        idx = np.floor(lo + 1e-9).astype(int)[:, None] + np.arange(int(np.ceil(1 / s + 2 * folga - 1e-9)) + 1)[None, :]
        peso = np.clip(np.minimum(hi[:, None], idx + 1) - np.maximum(lo[:, None], idx), 0, None) * s
        centro = (idx + 0.5 >= ini[:, None] - 1e-9) & (idx + 0.5 < ini[:, None] + 1 / s - 1e-9)
        dentro = (idx >= 0) & (idx < n_src)
        return np.clip(idx, 0, n_src - 1), peso * dentro, centro & dentro

    def de(self, m):
        return m[self.iy, self.ix]


def mais_votada(cor, peso, clara_ganha):
    """A cor com mais peso somado em cada pixel (o vazio não concorre). Empate: a mais clara, ou a mais escura."""
    total = (peso[..., None, :] * (cor[..., :, None] == cor[..., None, :])).sum(-1)
    total += luz(cor) * (1e-7 if clara_ganha else -1e-7)
    total[(cor == 0) | (peso <= 0)] = -1.0
    k = total.argmax(-1)[..., None]
    ganhou = np.take_along_axis(cor, k, -1)[..., 0]
    ganhou[np.take_along_axis(total, k, -1)[..., 0] < 0] = 0
    return ganhou


def ponto(u, s, tam, anc_src, anc_dst):
    """Nearest: o texel debaixo do centro de cada pixel. É o que o jogo fazia."""
    h, w = u.shape
    x = np.floor((np.arange(tam[0]) + 0.5 - anc_dst[0]) / s + anc_src[0]).astype(int)
    y = np.floor((np.arange(tam[1]) + 0.5 - anc_dst[1]) / s + anc_src[1]).astype(int)
    o = u[np.clip(y, 0, h - 1)[:, None], np.clip(x, 0, w - 1)[None, :]].copy()
    o[(y < 0) | (y >= h), :] = 0
    o[:, (x < 0) | (x >= w)] = 0
    return o


def amplia(u, s, tam, anc_src, anc_dst, candidata):
    if s == 2:
        grande = scale2x(u) if candidata == "A" else mmpx(u)
        return ponto(grande, 1.0, tam, (anc_src[0] * 2, anc_src[1] * 2), anc_dst)
    grande, n = (scale3x(u), 3) if candidata == "A" else (mmpx(u), 2)
    p = Pegada(grande.shape, tam, s / n, (anc_src[0] * n, anc_src[1] * n), anc_dst)
    cor = p.de(grande)
    o = mais_votada(cor, p.peso, clara_ganha=False)
    o[(p.peso * (cor != 0)).sum(-1) < 0.5 - 1e-6] = 0
    return o


def oklab(rgb):
    c = np.asarray(rgb, np.float64) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    l = np.cbrt(0.4122214708 * c[..., 0] + 0.5363325363 * c[..., 1] + 0.0514459929 * c[..., 2])
    m = np.cbrt(0.2119034982 * c[..., 0] + 0.6806995451 * c[..., 1] + 0.1073969566 * c[..., 2])
    s = np.cbrt(0.0883024619 * c[..., 0] + 0.2817188376 * c[..., 1] + 0.6299787005 * c[..., 2])
    return np.stack([0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                     1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                     0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s], axis=-1)


def paleta(u):
    """Cores da folha, da mais usada para a menos. Folha com degradê fica só com as que destoam entre si."""
    cores, cont = np.unique(u[u != 0], return_counts=True)
    cores = cores[np.argsort(-cont)]
    if len(cores) > 64:
        lab = oklab(desempacota(cores)[:, :3])
        fica = [0]
        for k in range(1, len(cores)):
            if np.sqrt(((lab[fica] - lab[k]) ** 2).sum(-1)).min() > 0.035:
                fica.append(k)
        cores = cores[fica]
    return cores


def para_paleta(rgb, pal):
    lab, lp = oklab(rgb).reshape(-1, 3), oklab(desempacota(pal)[:, :3])
    perto = np.concatenate([((lab[k:k + 4096, None] - lp[None]) ** 2).sum(-1).argmin(1) for k in range(0, len(lab), 4096)])
    return pal[perto].reshape(rgb.shape[:-1])


def beira(m):
    """Pixels de m encostados (pelos 4 lados) em algo fora de m."""
    return m & ~(viz(m, 0, -1) & viz(m, 0, 1) & viz(m, -1, 0) & viz(m, 1, 0))


def contraste(u):
    """Distância Oklab entre cada pixel e a média dos vizinhos opacos."""
    lab = oklab(desempacota(u)[..., :3])
    opaco = (u != 0).astype(np.float64)
    soma, n = np.zeros(lab.shape), np.zeros(u.shape)
    for dy, dx in ANEL:
        n += viz(opaco, dy, dx)
        for k in range(3):
            soma[..., k] += viz(lab[..., k] * opaco, dy, dx)
    c = np.sqrt(((lab - soma / np.maximum(n, 1)[..., None]) ** 2).sum(-1))
    return c * (n > 0) * (u != 0)


def tracos(u, destoa):
    """Pixels de traço de 1 px que se destaca do que há em volta: contorno, fio, friso.

    Traço é o que não cabe em nenhum bloco 2x2 da mesma cor. Ponto solto
    precisa destoar o dobro: um olho fica, um pontilhado de textura não.
    """
    bloco = (u == viz(u, 0, 1)) & (u == viz(u, 1, 0)) & (u == viz(u, 1, 1))
    fino = (u != 0) & ~(bloco | viz(bloco, 0, -1) | viz(bloco, -1, 0) | viz(bloco, -1, -1))
    acompanhado = np.zeros(u.shape, bool)
    for dy, dx in ANEL:
        acompanhado |= viz(u, dy, dx) == u
    return fino & (destoa >= CONTRASTE_DO_TRACO * np.where(acompanhado, 1, 2))


def tem_contorno(celulas):
    """A folha é contornada quando boa parte da beira da silhueta é traço (nas outras isso não passa de um oitavo)."""
    na_beira = no_traco = 0
    for u in celulas:
        b = beira(u != 0)
        na_beira += b.sum()
        no_traco += (b & tracos(u, contraste(u))).sum()
    return no_traco > na_beira / 3


def afina(cob, clareza):
    """Limiar de 50% que não parte o que é fino.

    Pixel coberto até a metade só continua opaco se tirá-lo quebrar a forma
    (um fio que racha, uma faísca que some). O resto sai, do menos coberto
    para o mais coberto e, no empate, do mais escuro para o mais claro.
    """
    m = np.pad(cob >= COBERTURA_MINIMA, 1)
    ys, xs = np.nonzero((cob >= COBERTURA_MINIMA) & (cob <= 0.5 + 1e-6))
    for k in np.lexsort((clareza[ys, xs], np.round(cob[ys, xs], 6))):
        y, x = ys[k] + 1, xs[k] + 1
        vazio = [not m[y + dy, x + dx] for dy, dx in ANEL]
        if sum(vazio) > 6:
            continue    # ponta de fio ou pixel solto: fica
        # número de conectividade de Yokoi: com 1, tirar o pixel não parte nem fura nada
        if sum(vazio[i] and not (vazio[i + 1] and vazio[(i + 2) % 8]) for i in (0, 2, 4, 6)) == 1:
            m[y, x] = False
    return m[1:-1, 1:-1]


def reduz(u, p, candidata, pal, contornada):
    cor = p.de(u)
    destoa = contraste(u)
    traco = tracos(u, destoa)
    borda = beira(u != 0)
    junto_da_borda = borda.copy()
    for dy, dx in ANEL:
        junto_da_borda |= viz(borda, dy, dx)
    # traço de dentro do desenho: entra inteiro no pixel onde cai o centro dele
    linha = p.de(traco & ~junto_da_borda)
    # contorno: sai antes de reduzir e é passado de novo, com 1 px, em volta do que sobrar
    contorno = p.de(traco & borda) if contornada else np.zeros(cor.shape, bool)
    miolo = (cor != 0) & ~contorno

    peso = p.peso * (miolo & ~linha)
    if candidata == "A":
        soma = peso.sum(-1)
        media = (desempacota(cor)[..., :3] * peso[..., None]).sum(-2) / np.maximum(soma, 1e-9)[..., None]
        out = np.where(soma > 1e-9, para_paleta(media, pal), 0).astype(np.uint32)
    else:
        out = mais_votada(cor, peso, clara_ganha=True)
    so_linha = out == 0
    out[so_linha] = mais_votada(cor, p.peso * miolo, clara_ganha=True)[so_linha]
    da_linha = mais_votada(cor, p.de(destoa) * linha * p.centro, clara_ganha=True)
    out = np.where(da_linha != 0, da_linha, out)
    cob = (p.peso * miolo).sum(-1)
    alfa = afina(cob, luz(out))

    if contornada:
        cor_contorno = mais_votada(cor, p.peso * contorno, clara_ganha=True)
        por_fora = np.where(cor_contorno != 0, cor_contorno, out)
        # a silhueta inteira decide o que é fio de verdade; o que é só contorno na origem aparece por ela
        inteira = afina((p.peso * (cor != 0)).sum(-1), luz(por_fora))
        alfa &= inteira | (cob > 0.5 + 1e-6)
        em_volta = (viz(alfa, 0, -1) | viz(alfa, 0, 1) | viz(alfa, -1, 0) | viz(alfa, 1, 0)) & (cor_contorno != 0)
        out = np.where(alfa, out, por_fora)
        alfa = alfa | em_volta | inteira
    out[~alfa] = 0
    return out


class Folha:
    """Uma folha que ainda tem draw_scale: a imagem, a grade e a conta de onde cada quadro vai parar."""

    def __init__(self, nome, pasta):
        self.nome, self.pasta = nome, pasta
        with open(os.path.join(pasta, nome + ".json"), encoding="utf-8") as f:
            self.meta = json.load(f)
        self.s = self.meta.get("draw_scale") or 1
        if self.s == 1:
            return
        self.u = empacota(np.array(Image.open(os.path.join(pasta, nome + ".png")).convert("RGBA")))
        self.w, self.h = int(self.meta["w"]), int(self.meta["h"])
        self.tam = (arred(self.w * self.s), arred(self.h * self.s))
        # o jogo põe o chão duas linhas acima do fundo da célula, no meio dela
        self.anc_src = (self.w / 2, self.h - 2)
        self.anc_dst = (self.tam[0] / 2, self.tam[1] - 2)
        self.faixa = "dobro" if self.s == 2 else "amplia" if self.s > 1 else "reduz"
        if self.faixa == "reduz":
            self.pegada = Pegada((self.h, self.w), self.tam, self.s, self.anc_src, self.anc_dst)
            self.pal = paleta(self.u)
            self.contornada = tem_contorno(u for _, _, u in self.celulas())

    def celulas(self):
        """(linha, coluna, célula) de toda a grade, menos as vazias."""
        for r in range(self.u.shape[0] // self.h):
            for c in range(self.u.shape[1] // self.w):
                u = self.u[r * self.h:(r + 1) * self.h, c * self.w:(c + 1) * self.w]
                if u.any():
                    yield r, c, u

    def hoje(self, u):
        return ponto(u, self.s, self.tam, self.anc_src, self.anc_dst)

    def refaz(self, u, candidata):
        if self.faixa == "reduz":
            return reduz(u, self.pegada, candidata, self.pal, self.contornada)
        return amplia(u, self.s, self.tam, self.anc_src, self.anc_dst, candidata)

    def regrava(self, candidata):
        W, H = self.tam
        nova = np.zeros((self.u.shape[0] // self.h * H, self.u.shape[1] // self.w * W), np.uint32)
        brilho, brilha = self._emissao(), np.zeros(nova.shape, bool)
        larga = Pegada((self.h, self.w), self.tam, self.s, self.anc_src, self.anc_dst, folga=0.5)
        for r, c, u in self.celulas():
            n = self.refaz(u, candidata)
            nova[r * H:(r + 1) * H, c * W:(c + 1) * W] = n
            if brilho is not None:
                # brilha o pixel novo cuja cor veio, na maior parte, de pixels que brilhavam
                mesma = larga.peso * (larga.de(u) == n[..., None])
                antes = larga.de(brilho[r * self.h:(r + 1) * self.h, c * self.w:(c + 1) * self.w])
                brilha[r * H:(r + 1) * H, c * W:(c + 1) * W] = (n != 0) & ((mesma * antes).sum(-1) > 0.5 * mesma.sum(-1))
        meta = dict(self.meta, w=W, h=H)
        if "size" in meta:
            meta["size"] = max(W, H)
        del meta["draw_scale"]
        Image.fromarray(desempacota(nova)).save(self._arquivo(".png"))
        with open(self._arquivo(".json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump(meta, f, indent=1)
        if brilho is not None:
            Image.fromarray(desempacota(np.where(brilha, nova, 0))).save(self._arquivo("_e.png"))

    def _arquivo(self, sufixo):
        return os.path.join(self.pasta, self.nome + sufixo)

    def _emissao(self):
        """Onde a folha brilha hoje, se o _e.png existir e ainda for do tamanho dela."""
        if not os.path.exists(self._arquivo("_e.png")):
            return None
        e = np.array(Image.open(self._arquivo("_e.png")).convert("RGBA"))[..., 3] >= 128
        return e if e.shape == self.u.shape else None


def regravar(nomes=None):
    """Regrava as folhas de ESCOLHA que ainda têm draw_scale. Devolve os nomes das que mudaram."""
    feitas = []
    for nome in nomes or ESCOLHA:
        if nome not in ESCOLHA or not os.path.exists(os.path.join(SPR, nome + ".json")):
            continue
        folha = Folha(nome, SPR)
        if folha.s == 1:
            continue
        folha.regrava(ESCOLHA[nome])
        gen_normais.processar(nome)
        print("reescala %-15s x%-4g %dx%d -> %dx%d  %s" % (nome, folha.s, folha.w, folha.h, *folha.tam, ROTULOS[folha.faixa]["AB".index(ESCOLHA[nome])]))
        feitas.append(nome)
    return feitas


def previa(nomes=None, pasta=None, zoom=4):
    """Primeiro quadro de idle de cada folha: como o jogo mostra hoje, candidata A, candidata B."""
    fundo, margem, linha = (44, 40, 54, 255), 6, 15
    pasta = pasta or SPR
    faixas = []
    for nome in nomes or ESCOLHA:
        folha = Folha(nome, pasta)
        if folha.s == 1:
            continue
        anim = folha.meta["anims"].get("idle") or next(iter(folha.meta["anims"].values()))
        u = folha.u[anim["row"] * folha.h:(anim["row"] + 1) * folha.h, :folha.w]
        colunas = [("hoje: nearest x%g" % folha.s, folha.hoje(u))]
        for k, rotulo in zip("AB", ROTULOS[folha.faixa]):
            colunas.append(("%s: %s%s" % (k, rotulo, "  <- ficou" if ESCOLHA.get(nome) == k else ""), folha.refaz(u, k)))
        ys, xs = np.nonzero(np.any([c != 0 for _, c in colunas], axis=0))
        x0, x1, y0, y1 = max(xs.min() - 2, 0), xs.max() + 3, max(ys.min() - 2, 0), ys.max() + 3
        tiras = []
        for rotulo, c in colunas:
            im = Image.new("RGBA", (x1 - x0, y1 - y0), fundo)
            im.alpha_composite(Image.fromarray(desempacota(c[y0:y1, x0:x1])))
            tiras.append((rotulo, im.resize((im.width * zoom, im.height * zoom), Image.NEAREST)))
        faixas.append(("%s    quadro %dx%d -> %dx%d" % (nome, folha.w, folha.h, *folha.tam), tiras))
    if not faixas:
        print("nenhuma folha com draw_scale em", os.path.normpath(pasta))
        return
    try:
        fonte = ImageFont.truetype(os.path.join(RAIZ, "tools", "fontes", "PixelifySans[wght].ttf"), 14)
    except OSError:
        fonte = ImageFont.load_default()
    passos = [max(tiras[0][1].width, 250) + 2 * margem for _, tiras in faixas]
    tela = Image.new("RGBA", (3 * max(passos) + margem, sum(tiras[0][1].height + 2 * linha + 4 * margem for _, tiras in faixas)), (24, 22, 30, 255))
    d = ImageDraw.Draw(tela)
    y = margem
    for (titulo, tiras), passo in zip(faixas, passos):
        d.text((margem, y), titulo, fill=(255, 230, 140, 255), font=fonte)
        for k, (rotulo, t) in enumerate(tiras):
            d.text((margem + k * passo, y + linha + 2), rotulo, fill=(200, 200, 215, 255), font=fonte)
            tela.paste(t, (margem + k * passo, y + 2 * linha + 6))
        y += tiras[0][1].height + 2 * linha + 4 * margem
    os.makedirs(os.path.dirname(PREVIA), exist_ok=True)
    tela.save(PREVIA)
    print("prévia em", os.path.normpath(PREVIA))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Regrava no tamanho final as folhas que o jogo desenhava com draw_scale.")
    ap.add_argument("folhas", nargs="*", help="só estas (padrão: todas as de ESCOLHA)")
    ap.add_argument("--previa", action="store_true", help="não regrava: monta a comparação em build/auditoria/reescala.png")
    ap.add_argument("--de", metavar="PASTA", help="de onde a prévia lê as folhas (padrão: assets/sprites)")
    a = ap.parse_args()
    if a.previa:
        previa(a.folhas, a.de)
    else:
        regravar(a.folhas)
