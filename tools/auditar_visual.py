"""Ver e medir o jogo sem abrir janela nenhuma.

Exporta a versão Web, serve com COOP/COEP e abre num Chrome sem janela (Playwright,
--headless=new com GPU d3d11) em modo vitrine (scripts/debug/vitrine.gd): o jogo de
verdade passa pelos domínios com o herói imortal.

  python tools/auditar_visual.py exportar
  python tools/auditar_visual.py fotos estatico robo chefes [--qualidade=alto] [--dominios=a,b] [--rotulo=antes]
  python tools/auditar_visual.py medir [--dominios=a,b]

fotos: build/auditoria/fotos/<rótulo>/<passe>_<domínio>_<n>.png e o tempo de quadro de cada
       domínio (requestAnimationFrame) em medidas_<passe>.json. Passes: estatico (herói parado),
       robo (o robô luta), chefes, pilhas (baús, item e braseiro ao lado do herói), poca.
medir: a mesma cena parada em cada nível de qualidade e em várias resoluções; separa o
       custo de preencher pixels (placa de vídeo) do custo de lógica.

Medir com a máquina livre e sem outra captura rodando: os números se contaminam.
O processador sozinho (sem vídeo) se mede com tools/sonda_cpu.gd.
"""
import functools
import http.server
import json
import os
import re
import subprocess
import sys
import threading
import time

from playwright.sync_api import sync_playwright

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.path.expanduser("~/Desktop/Godot_v4.7.2-stable_win64_console.exe")
BASE = os.path.join(RAIZ, "build", "auditoria")
WEB = os.path.join(BASE, "web")
PORTA = 8791

BIOMAS = ["mar_de_cinzas", "saloes", "forja_rubra", "necropole", "torre_babel", "jardim_primordial",
          "catedral", "carcosa", "observatorio", "ventre", "penhascos", "cavernas", "bosque"]
CHEFES = ["lobo", "colosso", "rei_esquecido", "arquiteto", "mae_raiz", "o_que_responde", "rei_sem_rosto",
          "astronomo", "insaciavel", "dragao_sonhado", "serpe", "raposa", "trono"]

# passe: (estágios, segundos em cada, extras da vitrine, fotos por estágio, intervalo, espera inicial)
PASSES = {
    "estatico": (["beira"] + BIOMAS, 11, [], 2, 3.6, 1.6),
    "robo": (BIOMAS, 19, ["--robo=1"], 4, 3.4, 3.0),
    "chefes": (CHEFES, 15, ["--robo=1"], 3, 3.2, 2.6),
    "pilhas": (["forja_rubra", "catedral", "cavernas", "mar_de_cinzas", "jardim_primordial", "ventre"], 9, ["--pilhas=1"], 2, 2.6, 1.8),
    "poca": (["catedral", "jardim_primordial", "saloes", "bosque"], 8, ["--poca=1"], 2, 2.2, 1.8),
}
# (nome, largura, altura, extras): o que o `medir` compara
CONFIGS = [
    ("1080p alta", 1920, 1080, ["--qualidade=alto"]),
    ("1080p média", 1920, 1080, ["--qualidade=medio"]),
    ("1080p baixa", 1920, 1080, ["--qualidade=baixo"]),
    ("768p média", 1366, 768, ["--qualidade=medio"]),
    ("1440p alta", 2560, 1440, ["--qualidade=alto"]),
    ("1440p média", 2560, 1440, ["--qualidade=medio"]),
]
MEDIR_EM = ["beira", "mar_de_cinzas", "jardim_primordial", "catedral", "forja_rubra", "saloes"]

QUADROS_JS = """(ms) => new Promise(resolve => {
  const d = []; let antes = performance.now(); const t0 = antes;
  function f(agora) {
    d.push(agora - antes); antes = agora;
    if (agora - t0 < ms) requestAnimationFrame(f);
    else {
      d.shift(); d.sort((a, b) => a - b);
      const soma = d.reduce((a, b) => a + b, 0);
      resolve({qps: 1000 * d.length / soma, mediana: d[Math.floor(d.length / 2)], p95: d[Math.floor(d.length * 0.95)],
               pior: d[d.length - 1], lentos: d.filter(x => x > 25).length, n: d.length});
    }
  }
  requestAnimationFrame(f);
})"""


class Servidor(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *a):
        pass


def exportar():
    os.makedirs(WEB, exist_ok=True)
    open(os.path.join(RAIZ, "build", ".gdignore"), "a").close()
    r = subprocess.run([GODOT, "--headless", "--path", RAIZ, "--export-release", "Web", os.path.join(WEB, "index.html")],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if not os.path.exists(os.path.join(WEB, "index.wasm")):
        print(r.stdout[-2000:], r.stderr[-2000:])
        sys.exit("export falhou")
    print("exportado em", WEB)


def pagina(nome, args):
    html = open(os.path.join(WEB, "index.html"), encoding="utf-8").read()
    html2, n = re.subn(r'"args":\[[^\]]*\]', '"args":' + json.dumps(args), html, count=1)
    if n != 1:
        sys.exit("não achei GODOT_CONFIG.args no index.html")
    arq = "vitrine_%s.html" % re.sub(r"[^a-z0-9_]", "_", nome.lower())
    open(os.path.join(WEB, arq), "w", encoding="utf-8", newline="").write(html2)
    return arq


def esperar(pg, estagio):
    try:
        pg.wait_for_function("document.title === 'VITRINE %s'" % estagio, timeout=150000)
        return True
    except Exception:
        print("  %s: não chegou" % estagio, flush=True)
        return False


def fotos(nav, nome, opcoes):
    estagios, segundos, extras, quantas, intervalo, espera = PASSES[nome]
    if opcoes.get("dominios"):
        estagios = opcoes["dominios"].split(",")
    pasta = os.path.join(BASE, "fotos", opcoes.get("rotulo", "atual"))
    os.makedirs(pasta, exist_ok=True)
    args = ["--", "--vitrine", "--dominios=" + ",".join(estagios), "--segundos=%d" % segundos] + extras
    if opcoes.get("qualidade"):
        args.append("--qualidade=" + opcoes["qualidade"])
    ctx = nav.new_context(viewport={"width": int(opcoes.get("largura", 1920)), "height": int(opcoes.get("altura", 1080))})
    pg = ctx.new_page()
    erros = []
    pg.on("console", lambda m: erros.append(m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:%d/%s" % (PORTA, pagina(nome, args)))
    medidas = {}
    for est in estagios:
        if not esperar(pg, est):
            break
        entrada = pg.evaluate(QUADROS_JS, int(espera * 1000))
        regime = entrada
        for i in range(quantas):
            pg.screenshot(path=os.path.join(pasta, "%s_%s_%d.png" % (nome, est, i)))
            if i == 0:
                regime = pg.evaluate(QUADROS_JS, int(intervalo * 1000) - 300)
            elif i < quantas - 1:
                time.sleep(intervalo)
        medidas[est] = {"entrada": entrada, "regime": regime}
        print("  %s/%s: %.0f qps (p95 %.0f ms) | ao entrar: pior quadro %.0f ms" % (nome, est, regime["qps"], regime["p95"], entrada["pior"]), flush=True)
    json.dump(medidas, open(os.path.join(pasta, "medidas_%s.json" % nome), "w"), indent=1)
    do_jogo = [e for e in erros if "404" not in e and "legado da conta" not in e and "push_warning" not in e]
    for e in do_jogo[:12]:
        print("  console: " + e[:300], flush=True)
    ctx.close()


def medir(nav, opcoes):
    estagios = opcoes["dominios"].split(",") if opcoes.get("dominios") else MEDIR_EM
    saida = {}
    for nome, w, h, extras in CONFIGS:
        args = ["--", "--vitrine", "--dominios=" + ",".join(estagios), "--segundos=9"] + extras
        ctx = nav.new_context(viewport={"width": w, "height": h})
        pg = ctx.new_page()
        pg.goto("http://127.0.0.1:%d/%s" % (PORTA, pagina("medir_" + nome, args)))
        linha = {}
        for est in estagios:
            if not esperar(pg, est):
                break
            time.sleep(1.2)
            linha[est] = pg.evaluate(QUADROS_JS, 5000)
        tela = pg.evaluate("(() => { const c = document.querySelector('#canvas'); return [c.width, c.height]; })()")
        saida[nome] = {"canvas": tela, "qps": {e: round(linha[e]["qps"], 1) for e in linha}}
        print("%-12s canvas %4dx%-4d  %s" % (nome, tela[0], tela[1], "  ".join("%s %.0f" % (e[:8], linha[e]["qps"]) for e in linha)), flush=True)
        ctx.close()
    json.dump(saida, open(os.path.join(BASE, "medidas_qualidade.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opcoes = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if not args:
        sys.exit(__doc__)
    if args[0] == "exportar":
        return exportar()
    if not os.path.exists(os.path.join(WEB, "index.wasm")):
        exportar()
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORTA), functools.partial(Servidor, directory=WEB))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    with sync_playwright() as p:
        nav = p.chromium.launch(channel="chrome", args=["--headless=new", "--use-angle=d3d11", "--enable-gpu",
                                                        "--ignore-gpu-blocklist", "--autoplay-policy=no-user-gesture-required"])
        if args[0] == "medir":
            medir(nav, opcoes)
        elif args[0] == "fotos":
            for nome in args[1:] or ["estatico"]:
                fotos(nav, nome, opcoes)
        else:
            sys.exit(__doc__)
        nav.close()
    srv.shutdown()


if __name__ == "__main__":
    main()
