"""Desenho de personagens em pixel art a partir de poses.

Cada quadro é montado com formas simples (membros, elipses, polígonos) direto
na resolução final, sem reduzir imagem grande (isso borra). Depois vêm duas
passadas automáticas:
  - luz: em cada parte, o pixel que tem vazio em cima/à esquerda clareia e o
    que tem vazio embaixo/à direita escurece (luz vindo de cima, da frente);
  - contorno: todo pixel vazio encostado no personagem vira contorno.

A imagem guarda ÍNDICES de paleta (canal vermelho = índice * 16 + 8), não
cores: o jogo troca a paleta num shader. Assim uma folha serve para todas as
aparências e o fogo/luz do jogo continuam funcionando por cima.
"""
import math
from PIL import Image

EMPTY = 0
OUTLINE = 1


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.idx = [[EMPTY] * w for _ in range(h)]
        self.part = [[-1] * w for _ in range(h)]
        self.shades = {}          # parte -> (claro, base, escuro)
        self._next = 0

    def new_part(self, base, hi=None, dark=None):
        pid = self._next
        self._next += 1
        self.shades[pid] = (hi if hi is not None else base, base, dark if dark is not None else base)
        return pid

    def put(self, x, y, pid):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.part[y][x] = pid
            self.idx[y][x] = self.shades[pid][1]

    def mark(self, x, y, index):
        """Pixel de detalhe com cor fixa (olho, fivela); não recebe luz."""
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.idx[y][x] = index
            self.part[y][x] = -2

    # --- formas -------------------------------------------------------------
    def limb(self, a, b, width, pid):
        ax, ay = a
        bx, by = b
        r = width / 2.0
        x0, x1 = int(min(ax, bx) - r - 1), int(max(ax, bx) + r + 2)
        y0, y1 = int(min(ay, by) - r - 1), int(max(ay, by) + r + 2)
        dx, dy = bx - ax, by - ay
        ll = dx * dx + dy * dy or 1e-6
        for y in range(y0, y1):
            for x in range(x0, x1):
                px, py = x + 0.5, y + 0.5
                t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / ll))
                cx, cy = ax + dx * t, ay + dy * t
                if (px - cx) ** 2 + (py - cy) ** 2 <= r * r + 0.15:
                    self.put(x, y, pid)

    def ellipse(self, c, rx, ry, pid):
        cx, cy = c
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                px, py = x + 0.5, y + 0.5
                if ((px - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1.0:
                    self.put(x, y, pid)

    def poly(self, pts, pid):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            py = y + 0.5
            xs = []
            n = len(pts)
            for i in range(n):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
                if (y0 <= py < y1) or (y1 <= py < y0):
                    xs.append(x0 + (py - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for k in range(0, len(xs) - 1, 2):
                for x in range(int(math.floor(xs[k] + 0.5)), int(math.floor(xs[k + 1] + 0.5))):
                    self.put(x, y, pid)

    def rect(self, x, y, w, h, pid):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.put(xx, yy, pid)

    # --- passadas finais ----------------------------------------------------
    def finish(self, light=True, outline=True):
        if light:
            out = [row[:] for row in self.idx]
            for y in range(self.h):
                for x in range(self.w):
                    pid = self.part[y][x]
                    if pid < 0:
                        continue
                    hi, base, dark = self.shades[pid]
                    same = lambda xx, yy: 0 <= xx < self.w and 0 <= yy < self.h and self.part[yy][xx] == pid
                    if not same(x, y - 1) or (not same(x - 1, y) and not same(x - 1, y - 1)):
                        out[y][x] = hi
                    elif not same(x, y + 1) or not same(x + 1, y):
                        out[y][x] = dark
            self.idx = out
        if outline:
            out = [row[:] for row in self.idx]
            for y in range(self.h):
                for x in range(self.w):
                    if self.idx[y][x] != EMPTY:
                        continue
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < self.w and 0 <= yy < self.h and self.idx[yy][xx] not in (EMPTY, OUTLINE):
                            out[y][x] = OUTLINE
                            break
            self.idx = out
        return self


def sheet(frames_by_row, size):
    """frames_by_row: lista de listas de Canvas -> imagem de índices."""
    cols = max(len(r) for r in frames_by_row)
    img = Image.new("RGBA", (cols * size, len(frames_by_row) * size), (0, 0, 0, 0))
    px = img.load()
    for r, row in enumerate(frames_by_row):
        for c, cv in enumerate(row):
            for y in range(size):
                for x in range(size):
                    i = cv.idx[y][x]
                    if i != EMPTY:
                        px[c * size + x, r * size + y] = (i * 16 + 8, 0, 0, 255)
    return img


def preview(index_img, palettes, scale=4, bg=(52, 40, 38)):
    """Pinta a folha de índices com cada paleta, uma embaixo da outra."""
    w, h = index_img.size
    out = Image.new("RGB", (w * scale, h * scale * len(palettes)), bg)
    src = index_img.load()
    for k, pal in enumerate(palettes):
        layer = Image.new("RGB", (w, h), bg)
        lp = layer.load()
        for y in range(h):
            for x in range(w):
                r, _, _, a = src[x, y]
                if a:
                    lp[x, y] = pal[r // 16]
        out.paste(layer.resize((w * scale, h * scale), Image.NEAREST), (0, k * h * scale))
    return out


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, k):
    """k > 0 clareia, k < 0 escurece."""
    if k >= 0:
        return tuple(int(v + (255 - v) * k) for v in c)
    return tuple(int(v * (1 + k)) for v in c)
