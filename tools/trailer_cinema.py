"""Trailer de cinema do MOKSHA: história em cartelas, tomadas lentas, guardiões com nome.

  python tools/trailer_cinema.py          # PT e EN
  python tools/trailer_cinema.py pt

Usa as cenas "parado_*", "cine_*" e "lento_*" de tools/filmar.py (sem HUD; os chefes
em câmera lenta de verdade). Saída: build/divulgacao/trailer_cinema_<lang>.mp4,
1920x1080, 60 qps, com faixas pretas de cinema (2.39:1).

Os textos vêm do próprio jogo (a introdução e o subtítulo de cada guardião, com a
tradução de content/lang/en.txt). A virada da história (quem são os guardiões, quem é
o herói) fica de fora de propósito: o trailer só insinua.
"""
import json
import os
import subprocess
import sys

from playwright.sync_api import sync_playwright

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CENAS = os.path.join(RAIZ, "build", "filmagem", "cenas")
TMP = os.path.join(RAIZ, "build", "filmagem", "cinema")
SAIDA = os.path.join(RAIZ, "build", "divulgacao")
MUSICA = os.path.join(RAIZ, "assets", "music")
SFX = os.path.join(RAIZ, "assets", "sfx")
W, H = 1920, 1080
FAIXA = 138            # faixa preta em cima e embaixo: 1920x804 de imagem = 2.39:1

EN = {}
for _l in open(os.path.join(RAIZ, "content", "lang", "en.txt"), encoding="utf-8"):
    if " = " in _l and not _l.startswith(";"):
        _a, _b = _l.rstrip("\n").split(" = ", 1)
        EN[_a.strip()] = _b.strip()


def en(pt):
    return EN.get(pt, pt)


# (cena, título do guardião, subtítulo) — exatamente como no jogo
GUARDIOES = [  # (cena, nome, subtítulo, início no vídeo gravado)
    ("lento_lobo", "O LOBO DA LONGA NOITE", "GUARDA A PORTA DE UM DONO QUE NÃO VOLTA", 13.5),
    ("lento_colosso", "O COLOSSO DA BIGORNA", "O FERREIRO QUE O DEUS ESQUECEU LIGADO", 9),
    ("lento_mae_raiz", "A MÃE-RAIZ", "TUDO QUE CRESCE AQUI NASCEU DELA", 7.5),
    ("lento_rei_sem_rosto", "O REI SEM ROSTO", "TODOS EM CARCOSA USAM A MÁSCARA DELE", 18),
    ("lento_dragao_sonhado", "O DRAGÃO SONHADO", "O DEUS QUE SONHAVA SONHOU UM GUARDA. ELE ACORDOU", 11.5),
    ("lento_astronomo", "O ÚLTIMO ASTRÔNOMO", "CONTOU AS ESTRELAS ATÉ ELAS ACABAREM", 11),
]

TXT = {
    "pt": {
        "c1": ("HOUVE UM TEMPO", "em que treze deuses dividiam o mundo."),
        "c2": ("CADA UM TINHA UM DOMÍNIO", "e cada domínio tinha a cara do seu deus."),
        "c3": ("UM DIA, ELES SUMIRAM.", ""),
        "beira": "Das cinzas, alguém acordou.",
        "c4": ("VOCÊ É O QUE ELES DEIXARAM.", ""),
        "f1": "13 DOMÍNIOS  ·  MAPAS NOVOS A CADA PARTIDA",
        "f2": "45 ARMAS E HABILIDADES",
        "f3": "MUTAÇÕES, RUNAS E BRASAS",
        "f4": "TRÊS CAMINHOS DEPOIS DE CADA GUARDIÃO",
        "c5": ("CADA PORTA TEM UM GUARDIÃO.", "E nenhum deles é um estranho."),
        "c6": ("QUANDO VOCÊ CAIR...", ""),
        "renasce": ("...RENASÇA NA BEIRA.", "O que você liberou fica para sempre."),
        "modos": "DESAFIO DO DIA  ·  DESAFIO DA SEMANA  ·  MODO WAVES  ·  RANKING",
        "trono": ("O IMPERADOR CEGO", "ESPERA NO TRONO"),
        "genero": "ROGUELITE DE AÇÃO EM PIXEL ART",
        "cta": "JOGUE GRÁTIS NO NAVEGADOR",
        "rodape": "PORTUGUÊS · ENGLISH  ·  TECLADO, CONTROLE OU TOQUE",
    },
    "en": {
        "c1": ("THERE WAS A TIME", "when thirteen gods shared the world."),
        "c2": ("EACH HAD A DOMAIN", "and each domain wore its god's face."),
        "c3": ("ONE DAY, THEY VANISHED.", ""),
        "beira": "From the ashes, someone woke.",
        "c4": ("YOU ARE WHAT THEY LEFT BEHIND.", ""),
        "f1": "13 DOMAINS  ·  NEW MAPS EVERY RUN",
        "f2": "45 WEAPONS AND SKILLS",
        "f3": "MUTATIONS, RUNES AND EMBERS",
        "f4": "THREE PATHS AFTER EVERY GUARDIAN",
        "c5": ("EVERY DOOR HAS A GUARDIAN.", "And none of them is a stranger."),
        "c6": ("WHEN YOU FALL...", ""),
        "renasce": ("...RISE AGAIN AT THE BRINK.", "What you unlocked stays forever."),
        "modos": "DAILY CHALLENGE  ·  WEEKLY CHALLENGE  ·  WAVE MODE  ·  LEADERBOARD",
        "trono": (en("O IMPERADOR CEGO"), "WAITS ON THE THRONE"),
        "genero": "PIXEL-ART ACTION ROGUELITE",
        "cta": "PLAY FREE IN YOUR BROWSER",
        "rodape": "ENGLISH · PORTUGUÊS  ·  KEYBOARD, GAMEPAD OR TOUCH",
    },
}

CSS = """
@import url('https://fonts.googleapis.com/css2?family=Silkscreen:wght@400;700&family=Pixelify+Sans:wght@400;600&display=swap');
* { margin: 0; box-sizing: border-box; }
html, body { width: 1920px; height: 1080px; overflow: hidden; background: transparent; color: #f2ecff; }
.preto { background: #000; }
.centro { position: absolute; inset: 0; display: grid; place-content: center; text-align: center; gap: 26px; }
.cartela { font: 400 58px/1.1 'Silkscreen', monospace; letter-spacing: .22em; color: #f2ecff;
  text-shadow: 0 0 28px rgba(242,193,78,.35); }
.linha { font: 400 40px/1.3 'Pixelify Sans', sans-serif; color: #a99dc2; letter-spacing: .02em; }
.legenda { position: absolute; left: 0; right: 0; bottom: 0; height: %(faixa)dpx; display: grid; place-content: center;
  font: 400 34px 'Pixelify Sans', sans-serif; color: #f2ecff; letter-spacing: .03em; }
.selo { position: absolute; left: 0; right: 0; bottom: 0; height: %(faixa)dpx; display: grid; place-content: center;
  font: 400 30px 'Silkscreen', monospace; color: #f2c14e; letter-spacing: .18em; }
.nome { position: absolute; left: 110px; bottom: %(nome)dpx; }
.nome b { display: block; font: 700 64px/1 'Silkscreen', monospace; color: #f2c14e; letter-spacing: .06em;
  text-shadow: 0 6px 0 #7a4a10, 0 0 30px rgba(0,0,0,.85); }
.nome i { display: block; margin-top: 18px; font: 400 30px 'Silkscreen', monospace; font-style: normal; color: #f2ecff;
  letter-spacing: .1em; text-shadow: 0 3px 0 #000, 0 0 18px #000; }
.logo { font: 700 220px/1 'Silkscreen', monospace; color: #f2c14e; letter-spacing: .05em;
  text-shadow: 0 16px 0 #7a4a10, 0 0 80px rgba(242,193,78,.35); }
.genero { font: 400 30px 'Silkscreen', monospace; color: #a99dc2; letter-spacing: .2em; }
.botao { justify-self: center; margin-top: 30px; padding: 26px 56px; background: #f2c14e; color: #1a0f04;
  font: 700 44px 'Silkscreen', monospace; box-shadow: inset -6px -6px 0 #c08a24, inset 6px 6px 0 #ffe08a, 0 10px 0 #7a4a10; }
.url { font: 400 46px 'Silkscreen', monospace; letter-spacing: .1em; }
.rodape { position: absolute; left: 0; right: 0; bottom: 60px; text-align: center; font: 400 24px 'Silkscreen', monospace;
  color: #6f6585; letter-spacing: .14em; }
""" % {"faixa": FAIXA, "nome": FAIXA + 60}


class Letreiros:
    def __init__(self, pg):
        self.pg = pg
        self.n = 0

    def png(self, corpo, preto=False):
        self.n += 1
        arq = os.path.join(TMP, "l%03d.png" % self.n)
        self.pg.set_content("<!doctype html><html><head><meta charset='utf-8'><style>" + CSS + "</style></head>"
                            "<body class='%s'>%s</body></html>" % ("preto" if preto else "", corpo))
        self.pg.evaluate("document.fonts.ready")
        self.pg.wait_for_timeout(250)
        self.pg.screenshot(path=arq, omit_background=not preto)
        return arq

    def cartela(self, a, b=""):
        return self.png("<div class='centro'><div class='cartela'>%s</div>%s</div>"
                        % (a, "<div class='linha'>%s</div>" % b if b else ""), preto=True)

    def legenda(self, t):
        return self.png("<div class='legenda'>%s</div>" % t)

    def selo(self, t):
        return self.png("<div class='selo'>%s</div>" % t)

    def nome(self, a, b):
        return self.png("<div class='nome'><b>%s</b><i>%s</i></div>" % (a, b))

    def logo(self, genero):
        return self.png("<div class='centro'><div class='logo'>MOKSHA</div><div class='genero'>%s</div></div>" % genero, preto=True)

    def final(self, t):
        return self.png("<div class='centro'><div class='logo' style='font-size:150px'>MOKSHA</div>"
                        "<div class='botao'>%s</div><div class='url'>MOKSHA.COM.BR</div></div>"
                        "<div class='rodape'>%s</div>" % (t["cta"], t["rodape"]), preto=True)


def ffmpeg(*args):
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error"] + [str(a) for a in args]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit("ffmpeg falhou:\n" + " ".join(cmd) + "\n" + r.stderr[-3000:])


QUALIDADE = ["-c:v", "libx264", "-preset", "medium", "-crf", "14", "-pix_fmt", "yuv420p", "-r", "60", "-an"]


class Montagem:
    def __init__(self):
        self.partes = []   # arquivos .mp4 sem som, na ordem
        self.t = 0.0       # duração acumulada
        self.sons = []     # (arquivo, início em s, volume)

    def _novo(self):
        return os.path.join(TMP, "p%03d.mp4" % len(self.partes))

    def cartela(self, png, dur, som=None):
        arq = self._novo()
        ffmpeg("-loop", "1", "-t", dur, "-i", png, "-vf",
               "fps=60,format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st=%g:d=0.5" % (dur - 0.5), *QUALIDADE, arq)
        if som:
            self.sons.append((som, self.t + 0.05, 1.0))
        self.partes.append(arq)
        self.t += dur

    def tomada(self, cena, inicio, dur, zoom=0.0, letreiro=None, fundir=False, som=None, flash=False):
        """inicio/dur em segundos do vídeo gravado (os chefes em câmera lenta continuam lentos).
        zoom: quanto a imagem cresce ao longo da tomada (0.1 = aproxima 10%)."""
        src = os.path.join(CENAS, cena + ".webm")
        f = "fps=60,trim=start=%g:duration=%g,setpts=PTS-STARTPTS," % (inicio, dur)
        # amplia sem borrar para 3840x2160 e só então aproxima suave (o pixel fica nítido)
        f += "scale=3840:2160:flags=neighbor,"
        if zoom:
            f += ("scale=w='trunc(1920*(1+%g*t/%g)/2)*2':h='trunc(1080*(1+%g*t/%g)/2)*2':eval=frame:flags=bicubic,"
                  "crop=1920:1080:(iw-1920)/2:(ih-1080)/2," % (zoom, dur, zoom, dur))
        else:
            f += "scale=1920:1080:flags=area,"
        f += "drawbox=x=0:y=0:w=iw:h=%d:color=black:t=fill,drawbox=x=0:y=ih-%d:w=iw:h=%d:color=black:t=fill" % (FAIXA, FAIXA, FAIXA)
        if fundir:
            f += ",fade=t=in:st=0:d=0.5,fade=t=out:st=%g:d=0.5" % (dur - 0.5)
        if flash:
            f += ",fade=t=in:st=0:d=0.25:color=white"
        f += ",format=yuv420p[v]"
        entradas = ["-i", src]
        if letreiro:
            entradas += ["-loop", "1", "-t", dur, "-i", letreiro]
            f = "[0:v]" + f.replace("[v]", "[b]") + (";[1:v]format=rgba,fade=t=in:st=0.3:d=0.4:alpha=1,"
                                                     "fade=t=out:st=%g:d=0.4:alpha=1[l];[b][l]overlay=0:0,format=yuv420p[v]" % (dur - 0.5))
        else:
            f = "[0:v]" + f
        arq = self._novo()
        ffmpeg(*entradas, "-filter_complex", f, "-map", "[v]", "-t", dur, *QUALIDADE, arq)
        if som:
            self.sons.append((som, self.t, 0.9))
        self.partes.append(arq)
        self.t += dur

    def fechar(self, saida, musicas):
        lista = os.path.join(TMP, "lista.txt")
        with open(lista, "w") as fh:
            for p in self.partes:
                fh.write("file '%s'\n" % p.replace("\\", "/"))
        video = os.path.join(TMP, "video.mp4")
        ffmpeg("-f", "concat", "-safe", "0", "-i", lista, "-c", "copy", video)
        entradas, filtros, rot = ["-i", video], [], []
        k = 1
        for arq, ini, fim, ent, sai, vol, desde in musicas:
            entradas += ["-ss", desde, "-i", arq]
            filtros.append("[%d:a]aformat=channel_layouts=stereo,atrim=0:%g,afade=t=in:st=0:d=%g,afade=t=out:st=%g:d=%g,"
                           "volume=%g,adelay=%d|%d[a%d]" % (k, fim - ini, ent, fim - ini - sai, sai, vol,
                                                            ini * 1000, ini * 1000, k))
            rot.append("[a%d]" % k)
            k += 1
        for arq, ini, vol in self.sons:
            entradas += ["-i", arq]
            filtros.append("[%d:a]aformat=channel_layouts=stereo,volume=%g,adelay=%d|%d[a%d]" % (k, vol, ini * 1000, ini * 1000, k))
            rot.append("[a%d]" % k)
            k += 1
        filtros.append("%samix=inputs=%d:normalize=0,alimiter=limit=0.95[aout]" % ("".join(rot), len(rot)))
        ffmpeg(*entradas, "-filter_complex", ";".join(filtros), "-map", "0:v", "-map", "[aout]", "-c:v", "copy",
               "-c:a", "aac", "-b:a", "256k", "-t", self.t, "-movflags", "+faststart", saida)
        print("ok", saida, "%.1f s" % self.t)


def trailer(lang, L):
    t = TXT[lang]
    nome = (lambda s: s) if lang == "pt" else en
    m = Montagem()
    boom, sino, chefe = os.path.join(SFX, "boom.wav"), os.path.join(SFX, "bell.wav"), os.path.join(SFX, "boss_intro.wav")

    # Ato 1: o mundo (música do título)
    m.cartela(L.cartela(*t["c1"]), 4.2, som=sino)
    m.tomada("parado_mar_de_cinzas", 1.0, 5.0, zoom=0.12, fundir=True)
    m.tomada("parado_catedral", 1.0, 3.6, zoom=0.10, fundir=True)
    m.tomada("parado_observatorio", 1.0, 3.6, zoom=0.10, fundir=True)
    m.cartela(L.cartela(*t["c2"]), 4.0)
    m.tomada("parado_penhascos", 1.0, 3.0, zoom=0.08, fundir=True)
    m.tomada("parado_carcosa", 1.0, 3.0, zoom=0.08, fundir=True)
    m.tomada("parado_jardim_primordial", 1.0, 3.0, zoom=0.08, fundir=True)
    m.cartela(L.cartela(*t["c3"]), 3.4, som=boom)
    m.tomada("parado_beira", 1.0, 4.0, zoom=0.10, letreiro=L.legenda(t["beira"]), fundir=True)
    m.cartela(L.cartela(*t["c4"]), 3.0)
    virada = m.t

    # Ato 2: o herói (a música vira a do chefe final)
    acao = [("cine_mar_de_cinzas", 6.0, "f1"), ("cine_forja_rubra", 10.0, None), ("cine_carcosa", 7.5, "f2"),
            ("cine_ventre", 10.0, None), ("cine_torre_babel", 13.5, "f3"), ("cine_jardim_primordial", 2.0, None),
            ("cine_necropole", 3.0, "f4"), ("cine_catedral", 12.0, None)]
    for i, (c, ini, f) in enumerate(acao):
        # tomada com selo dura o bastante para ler; a do meio é um corte rápido
        m.tomada(c, ini, 2.4 if f else 1.2, letreiro=L.selo(t[f]) if f else None, som=boom if i == 0 else None, flash=i == 0)
    # Ato 3: os guardiões, em câmera lenta
    m.cartela(L.cartela(*t["c5"]), 3.6, som=chefe)
    for c, a, b, ini in GUARDIOES:
        m.tomada(c, ini, 2.6, letreiro=L.nome(nome(a), nome(b)), zoom=0.05)
    for c, ini in (("lento_insaciavel", 10.0), ("lento_raposa", 2.0), ("lento_o_que_responde", 14.0)):
        m.tomada(c, ini, 0.8)
    m.cartela(L.cartela(*t["c6"]), 2.4, som=boom)
    m.tomada("parado_beira", 3.0, 3.4, letreiro=L.legenda("<b style='color:#f2c14e'>%s</b>&nbsp;&nbsp;%s" % t["renasce"]))
    m.tomada("cine_saloes", 9.5, 3.2, letreiro=L.selo(t["modos"]))
    m.tomada("lento_trono", 2.5, 3.6, letreiro=L.nome(*t["trono"]), zoom=0.06, som=chefe)
    fim_acao = m.t
    # Fecho
    m.cartela(L.logo(t["genero"]), 4.2, som=sino)
    m.cartela(L.final(t), 5.0)

    musicas = [
        # (arquivo, início, fim, fade de entrada, fade de saída, volume, começar a música em)
        (os.path.join(MUSICA, "titulo.wav"), 0.0, virada + 0.4, 1.5, 1.2, 0.9, 0),
        (os.path.join(MUSICA, "chefe_final.wav"), virada, fim_acao + 0.6, 0.1, 1.0, 0.9, 0),
        (os.path.join(MUSICA, "titulo.wav"), fim_acao, m.t, 0.8, 2.0, 0.8, 20),
    ]
    m.fechar(os.path.join(SAIDA, "trailer_cinema_%s.mp4" % lang), musicas)


def main():
    langs = [a for a in sys.argv[1:] if a in TXT] or list(TXT)
    os.makedirs(TMP, exist_ok=True)
    os.makedirs(SAIDA, exist_ok=True)
    with sync_playwright() as p:
        nav = p.chromium.launch(channel="chrome", args=["--headless=new"])
        pg = nav.new_page(viewport={"width": W, "height": H})
        for lang in langs:
            trailer(lang, Letreiros(pg))
        nav.close()


if __name__ == "__main__":
    main()
