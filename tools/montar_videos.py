"""Monta trailer, vídeos de rede social e screenshots a partir das cenas de tools/filmar.py.

  python tools/montar_videos.py

Saída em build/divulgacao/:
  trailer_pt.mp4 / trailer_en.mp4      30 s, 1920x1080, 60 qps (YouTube, itch, site)
  vertical_<n>_pt.mp4 / _en.mp4        1080x1920 (Reels, TikTok, Shorts)
  quadrado_pt.mp4 / _en.mp4            1080x1080 (feed do Instagram/Facebook)
  screenshots/*.png                    1920x1080

Os letreiros saem de um HTML com as fontes do site (Silkscreen + Pixelify Sans),
fotografado com fundo transparente num Chrome sem janela. O jogo foi gravado em
960x540 e é ampliado sem borrar (vizinho mais próximo).
"""
import json
import os
import shutil
import subprocess

from playwright.sync_api import sync_playwright

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CENAS = os.path.join(RAIZ, "build", "filmagem", "cenas")
SAIDA = os.path.join(RAIZ, "build", "divulgacao")
LETREIROS = os.path.join(RAIZ, "build", "filmagem", "letreiros")
MUSICA = os.path.join(RAIZ, "assets", "music")

TEXTOS = {
    "pt": {
        "deuses": ("TREZE DEUSES SUMIRAM.", "Você é o que eles deixaram."),
        "dominios": ("13 DOMÍNIOS", "Mapas novos a cada partida."),
        "guardioes": ("13 GUARDIÕES", "Cada um era um deus."),
        "renasce": ("MORREU?", "Renasça na Beira. O que você liberou fica."),
        "cta": ("JOGUE GRÁTIS NO NAVEGADOR", "MOKSHA.COM.BR"),
        "genero": "ROGUELITE DE AÇÃO EM PIXEL ART",
    },
    "en": {
        "deuses": ("THIRTEEN GODS VANISHED.", "You are what they left behind."),
        "dominios": ("13 DOMAINS", "New maps every run."),
        "guardioes": ("13 GUARDIANS", "Each one was a god."),
        "renasce": ("DIED?", "Rise again at the Brink. What you unlocked stays."),
        "cta": ("PLAY FREE IN YOUR BROWSER", "MOKSHA.COM.BR"),
        "genero": "PIXEL-ART ACTION ROGUELITE",
    },
}

CSS = """
@import url('https://fonts.googleapis.com/css2?family=Silkscreen:wght@400;700&family=Pixelify+Sans:wght@400;600&display=swap');
* { margin: 0; box-sizing: border-box; }
html, body { background: transparent; width: %(w)dpx; height: %(h)dpx; overflow: hidden; }
body { position: relative; color: #f2ecff; font-family: 'Pixelify Sans', sans-serif; }
.faixa { position: absolute; left: 0; right: 0; bottom: 0; height: %(faixa)dpx;
  background: linear-gradient(0deg, rgba(7,6,11,.88) 0%%, rgba(7,6,11,.6) 55%%, rgba(7,6,11,0) 100%%); }
.bloco { position: absolute; left: %(margem)dpx; right: %(margem)dpx; bottom: %(baixo)dpx; }
h1 { font: 700 %(h1)dpx/1.05 'Silkscreen', monospace; color: #f2c14e; letter-spacing: .03em;
  text-shadow: 0 %(sombra)dpx 0 #7a4a10, 0 0 24px rgba(0,0,0,.6); }
p { margin-top: %(gap)dpx; font: 400 %(p)dpx/1.3 'Pixelify Sans', sans-serif; text-shadow: 0 3px 0 rgba(0,0,0,.7); }
.logo { font: 700 %(logo)dpx/1 'Silkscreen', monospace; color: #f2c14e; letter-spacing: .04em;
  text-shadow: 0 %(sombra_logo)dpx 0 #7a4a10, 0 0 40px rgba(0,0,0,.7); }
.genero { margin-top: %(gap)dpx; font: 400 %(gen)dpx/1.4 'Silkscreen', monospace; color: #a99dc2; letter-spacing: .08em; }
.fundo { position: absolute; inset: 0; background: rgba(7,6,11,.72); }
.centro { position: absolute; inset: 0; display: grid; place-content: center; text-align: center; }
.botao { display: inline-block; margin-top: %(gap2)dpx; padding: %(bp)dpx %(bp2)dpx; background: #f2c14e; color: #1a0f04;
  font: 700 %(btn)dpx 'Silkscreen', monospace; box-shadow: inset -6px -6px 0 #c08a24, inset 6px 6px 0 #ffe08a, 0 9px 0 #7a4a10; }
.url { margin-top: %(gap)dpx; font: 400 %(url)dpx 'Silkscreen', monospace; color: #f2ecff; letter-spacing: .06em; }
.topo { position: absolute; left: 0; right: 0; top: 0; height: %(topo)dpx; display: grid; place-content: center; text-align: center;
  background: linear-gradient(180deg, rgba(7,6,11,1) 0%%, rgba(7,6,11,.92) 70%%, rgba(7,6,11,0) 100%%); }
"""


def medidas(w, h):
    vertical = h > w
    k = w / 1920 if not vertical else w / 1080 * 0.82
    return {"w": w, "h": h, "faixa": int(h * (0.40 if not vertical else 0.30)), "margem": int(96 * k), "baixo": int(80 * k),
            "h1": int(76 * k), "p": int(40 * k), "gap": int(16 * k), "gap2": int(44 * k), "sombra": max(4, int(6 * k)),
            "logo": int(170 * k), "sombra_logo": int(12 * k), "gen": int(28 * k), "bp": int(24 * k), "bp2": int(48 * k),
            "btn": int(40 * k), "url": int(34 * k), "topo": int(h * 0.22)}


def letreiros(pg, lang, w, h, sufixo):
    """Gera os PNGs transparentes de um idioma e tamanho. Devolve {nome: caminho}."""
    t = TEXTOS[lang]
    css = "<style>" + CSS % medidas(w, h) + "</style>"
    paginas = {}
    for chave in ("deuses", "dominios", "guardioes", "renasce"):
        a, b = t[chave]
        paginas[chave] = '<div class="faixa"></div><div class="bloco"><h1>%s</h1><p>%s</p></div>' % (a, b)
    a, b = t["cta"]
    paginas["final"] = ('<div class="fundo"></div><div class="centro"><div class="logo">MOKSHA</div>'
                        '<div class="genero">%s</div><div><span class="botao">%s</span></div><div class="url">%s</div></div>'
                        % (t["genero"], a, b))
    # vertical/quadrado: logo fixo em cima e chamada embaixo, durante o vídeo todo
    paginas["moldura"] = ('<div class="topo"><div class="logo">MOKSHA</div><div class="genero">%s</div></div>'
                          '<div class="faixa"></div><div class="bloco" style="text-align:center"><h1>%s</h1><div class="url">%s</div></div>'
                          % (t["genero"], a, b))
    caminhos = {}
    pg.set_viewport_size({"width": w, "height": h})
    for nome, corpo in paginas.items():
        pg.set_content("<!doctype html><html><head><meta charset='utf-8'>" + css + "</head><body>" + corpo + "</body></html>")
        pg.evaluate("document.fonts.ready")
        pg.wait_for_timeout(300)
        arq = os.path.join(LETREIROS, "%s_%s_%s.png" % (nome, lang, sufixo))
        pg.screenshot(path=arq, omit_background=True)
        caminhos[nome] = arq
    return caminhos


def ffmpeg(*args):
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error"] + [str(a) for a in args]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit("ffmpeg falhou:\n" + " ".join(cmd) + "\n" + r.stderr[-3000:])


def cena(nome):
    """Entrada de uma cena já na velocidade do jogo (desfaz o --lento) e a 60 qps."""
    meta = json.load(open(os.path.join(CENAS, nome + ".json")))
    return os.path.join(CENAS, nome + ".webm"), float(meta.get("lento", 1.0))


def trecho(nome, inicio, dur, w=1920, h=1080, recorte=None):
    """Filtro de um trecho: [inicio, inicio+dur) em segundos de jogo, ampliado sem borrar."""
    arq, lento = cena(nome)
    f = "setpts=(PTS-STARTPTS)*%g,fps=60,trim=start=%g:duration=%g,setpts=PTS-STARTPTS" % (lento, inicio, dur)
    f += ",scale=1920:1080:flags=neighbor"
    if recorte:
        f += ",crop=%d:%d:(in_w-%d)/2:(in_h-%d)/2" % (recorte[0], recorte[1], recorte[0], recorte[1])
        if (recorte[0], recorte[1]) != (w, h):
            f += ",scale=%d:%d:flags=neighbor" % (w, h)
    f += ",setsar=1,format=yuv420p"
    return arq, f


def montar(saida, partes, letreiros_por_parte, musica, w, h, moldura=None, final=None, dur_final=0.0):
    """partes: [(cena, inicio, dur, recorte)]. Corte seco entre as partes; letreiro por cima de cada uma.
    final: PNG por cima dos últimos dur_final segundos. moldura: PNG por cima do vídeo inteiro."""
    entradas, filtros, rotulos = [], [], []
    for i, (nome, ini, dur, recorte) in enumerate(partes):
        arq, f = trecho(nome, ini, dur, w, h, recorte)
        entradas += ["-i", arq]
        filtros.append("[%d:v]%s[v%d]" % (i, f, i))
        rotulos.append("[v%d]" % i)
    n = len(partes)
    filtros.append("%sconcat=n=%d:v=1:a=0[base]" % ("".join(rotulos), n))
    total = sum(p[2] for p in partes)
    atual, idx = "[base]", n
    t = 0.0
    for i, (nome, ini, dur, recorte) in enumerate(partes):
        let = letreiros_por_parte[i] if i < len(letreiros_por_parte) else None
        if let:
            entradas += ["-loop", "1", "-t", "%g" % total, "-i", let]
            # entra um pouco depois do corte e some antes do próximo, com fade
            a, b = t + 0.25, t + dur - 0.2
            filtros.append("[%d:v]format=rgba,fade=t=in:st=%g:d=0.3:alpha=1,fade=t=out:st=%g:d=0.3:alpha=1[l%d]" % (idx, a, b - 0.3, idx))
            filtros.append("%s[l%d]overlay=0:0:enable='between(t,%g,%g)'[o%d]" % (atual, idx, a, b, idx))
            atual = "[o%d]" % idx
            idx += 1
        t += dur
    if moldura:
        entradas += ["-loop", "1", "-t", "%g" % total, "-i", moldura]
        filtros.append("%s[%d:v]overlay=0:0[o%d]" % (atual, idx, idx))
        atual = "[o%d]" % idx
        idx += 1
    if final:
        entradas += ["-loop", "1", "-t", "%g" % total, "-i", final]
        a = total - dur_final
        filtros.append("[%d:v]format=rgba,fade=t=in:st=%g:d=0.5:alpha=1[l%d]" % (idx, a, idx))
        filtros.append("%s[l%d]overlay=0:0:enable='gte(t,%g)'[o%d]" % (atual, idx, a, idx))
        atual = "[o%d]" % idx
        idx += 1
    filtros.append("%sfade=t=in:st=0:d=0.4,fade=t=out:st=%g:d=0.6[vout]" % (atual, total - 0.6))
    entradas += ["-i", musica]
    filtros.append("[%d:a]atrim=0:%g,afade=t=in:st=0:d=0.3,afade=t=out:st=%g:d=1.5[aout]" % (idx, total, total - 1.5))
    ffmpeg(*entradas, "-filter_complex", ";".join(filtros), "-map", "[vout]", "-map", "[aout]",
           "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p", "-r", "60",
           "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-t", "%g" % total, saida)
    print("ok", saida)


# Roteiro do trailer (30 s). Os inícios foram escolhidos olhando as cenas gravadas.
TRAILER = [
    ("titulo", 1.0, 3.0, None, None),
    ("mar_de_cinzas", 4.0, 5.0, None, "deuses"),
    ("forja_rubra", 10.0, 2.0, None, "dominios"),
    ("carcosa", 5.5, 2.0, None, None),
    ("observatorio", 2.0, 2.0, None, None),
    ("ventre", 9.5, 2.0, None, None),
    ("jardim_primordial", 4.0, 2.0, None, None),
    ("lobo", 12.0, 3.0, None, "guardioes"),
    ("colosso", 16.5, 3.0, None, None),
    ("dragao_sonhado", 7.0, 3.0, None, None),
]
FINAL = ("trono", 14.0, 4.0, None)   # embaixo do letreiro final
# vertical e quadrado: o meio da tela do jogo, pixel 4x sem distorcer
VERTICAIS = {
    "1": [("mar_de_cinzas", 4.0, 4.0), ("forja_rubra", 10.0, 3.0), ("carcosa", 5.0, 3.0), ("lobo", 12.0, 4.0), ("torre_babel", 13.0, 4.0)],
    "2": [("observatorio", 2.0, 4.0), ("ventre", 9.0, 3.0), ("penhascos", 0.0, 3.0), ("colosso", 16.0, 4.0), ("astronomo", 8.0, 4.0)],
}


def main():
    # python tools/montar_videos.py vertical_1  -> só os vídeos cujo nome começa assim
    import sys
    so = sys.argv[1:]
    quer = lambda nome: not so or any(nome.startswith(x) for x in so)
    os.makedirs(SAIDA, exist_ok=True)
    os.makedirs(LETREIROS, exist_ok=True)
    with sync_playwright() as p:
        nav = p.chromium.launch(channel="chrome", args=["--headless=new"])
        pg = nav.new_page()
        let = {(lang, s): letreiros(pg, lang, w, h, s) for lang in TEXTOS for (s, w, h) in
               (("h", 1920, 1080), ("v", 1080, 1920), ("q", 1080, 1080))}
        nav.close()

    for lang in TEXTOS:
        L = let[(lang, "h")]
        partes = [(c, i, d, r) for c, i, d, r, _ in TRAILER]
        textos = [L[x] if x else None for *_, x in TRAILER]
        if quer("trailer"):
            montar(os.path.join(SAIDA, "trailer_%s.mp4" % lang), partes + [FINAL], textos,
                   os.path.join(MUSICA, "chefe_final.wav"), 1920, 1080, final=L["final"], dur_final=4.0)
        for n, roteiro in VERTICAIS.items():
            if not quer("vertical_" + n):
                continue
            partes = [(c, i, d, (1080, 1080)) for c, i, d in roteiro]
            # 1080x1080 do meio da tela 1080p (pixel 4x), posto no centro de 1080x1920 com o logo e a chamada
            montar(os.path.join(SAIDA, "vertical_%s_%s.mp4" % (n, lang)), partes, [], os.path.join(MUSICA, "chefe.wav"),
                   1080, 1080, moldura=None)
            tmp = os.path.join(SAIDA, "vertical_%s_%s.mp4" % (n, lang))
            emoldurar(tmp, let[(lang, "v")]["moldura"], 1080, 1920)
        partes = [(c, i, d, (1080, 1080)) for c, i, d in VERTICAIS["1"]]
        if quer("quadrado"):
            montar(os.path.join(SAIDA, "quadrado_%s.mp4" % lang), partes, [], os.path.join(MUSICA, "chefe.wav"),
                   1080, 1080, moldura=let[(lang, "q")]["moldura"])

    fotos = os.path.join(SAIDA, "screenshots")
    os.makedirs(fotos, exist_ok=True)
    for arq in sorted(os.listdir(CENAS)):
        if arq.endswith(".png"):
            shutil.copy(os.path.join(CENAS, arq), os.path.join(fotos, arq))
    print("ok", fotos)


def emoldurar(arq, moldura, w, h):
    """Põe o vídeo quadrado no meio de um quadro vertical escuro, com a moldura por cima."""
    tmp = arq + ".tmp.mp4"
    os.replace(arq, tmp)
    ffmpeg("-i", tmp, "-loop", "1", "-i", moldura, "-filter_complex",
           "[0:v]pad=%d:%d:0:(oh-ih)/2:color=0x07060b[b];[b][1:v]overlay=0:0:shortest=1,format=yuv420p[v]" % (w, h),
           "-map", "[v]", "-map", "0:a", "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-r", "60",
           "-c:a", "copy", "-movflags", "+faststart", arq)
    os.remove(tmp)
    print("ok", arq)


if __name__ == "__main__":
    main()
