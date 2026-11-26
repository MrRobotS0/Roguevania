"""Grava cenas do jogo de verdade, sem abrir janela nenhuma.

Exporta a versão Web, serve com COOP/COEP e abre num Chrome sem janela (Playwright,
--headless=new com GPU d3d11). Cada cena abre o jogo em modo vitrine
(scripts/debug/vitrine.gd): o robô joga, imortal, no domínio pedido. A gravação usa
canvas.captureStream + MediaRecorder dentro da página, a 60 qps, em 960x540 (pixel
do jogo 2x). tools/montar_videos.py amplia para 1080p sem borrar.

Uso:
  python tools/filmar.py                    # todas as cenas de CENAS
  python tools/filmar.py forja_rubra lobo   # só essas
  python tools/filmar.py --sem-exportar ... # reaproveita o export de build/filmagem/web

Saída: build/filmagem/cenas/<nome>.webm e <nome>_NN.png (3 fotos em 1920x1080 depois do vídeo).
"""
import functools
import http.server
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time

from playwright.sync_api import sync_playwright

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.path.expanduser("~/Desktop/Godot_v4.7.2-stable_win64_console.exe")
BASE = os.path.join(RAIZ, "build", "filmagem")
WEB = os.path.join(BASE, "web")
CENAS_DIR = os.path.join(BASE, "cenas")
PORTA = 8765
# --lento=0.5: o mundo anda na metade da velocidade e a gravação dura o dobro;
# montar_videos.py lê o <nome>.json e acelera de volta (sai com o dobro de quadros)
LENTO = 1.0
for _a in sys.argv:
    if _a.startswith("--lento="):
        LENTO = float(_a.split("=")[1])

# nome: (domínio/estágio da vitrine, segundos gravando)
CENAS = {
    "titulo": ("titulo", 10),
    "mar_de_cinzas": ("mar_de_cinzas", 24),
    "saloes": ("saloes", 20),
    "forja_rubra": ("forja_rubra", 20),
    "necropole": ("necropole", 20),
    "torre_babel": ("torre_babel", 20),
    "jardim_primordial": ("jardim_primordial", 20),
    "catedral": ("catedral", 20),
    "carcosa": ("carcosa", 20),
    "observatorio": ("observatorio", 20),
    "ventre": ("ventre", 20),
    "penhascos": ("penhascos", 20),
    "cavernas": ("cavernas", 20),
    "bosque": ("bosque", 20),
    "lobo": ("lobo", 26),
    "colosso": ("colosso", 26),
    "mae_raiz": ("mae_raiz", 26),
    "astronomo": ("astronomo", 26),
    "dragao_sonhado": ("dragao_sonhado", 26),
    "trono": ("trono", 30),
}

GRAVAR_JS = """async (segundos) => {
  const c = document.querySelector('#canvas');
  const fluxo = c.captureStream(60);
  const tipo = ['video/webm;codecs=h264', 'video/webm;codecs=vp9', 'video/webm'].find(t => MediaRecorder.isTypeSupported(t));
  const rec = new MediaRecorder(fluxo, {mimeType: tipo, videoBitsPerSecond: 16e6});
  const partes = [];
  rec.ondataavailable = e => { if (e.data.size) partes.push(e.data); };
  const fim = new Promise(r => rec.onstop = r);
  rec.start(1000);
  await new Promise(r => setTimeout(r, segundos * 1000));
  rec.stop();
  await fim;
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob(partes, {type: 'video/webm'}));
  a.download = 'cena.webm';
  document.body.appendChild(a);
  a.click();
  return tipo;
}"""


class Servidor(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *a):
        pass


def exportar():
    if os.path.isdir(WEB):
        shutil.rmtree(WEB)
    os.makedirs(WEB)
    open(os.path.join(BASE, ".gdignore"), "w").close()
    r = subprocess.run([GODOT, "--headless", "--path", RAIZ, "--export-release", "Web", os.path.join(WEB, "index.html")],
                       capture_output=True, text=True)
    if not os.path.exists(os.path.join(WEB, "index.wasm")):
        print(r.stdout[-2000:], r.stderr[-2000:])
        sys.exit("export falhou")


def pagina_da_cena(nome, estagio, segundos):
    html = open(os.path.join(WEB, "index.html"), encoding="utf-8").read()
    args = ["--", "--vitrine", "--dominios=" + estagio, "--segundos=%d" % (segundos + 60)]
    if estagio != "titulo":
        args.append("--robo=1")
    if LENTO != 1.0:
        args.append("--lento=%g" % LENTO)
    html2, n = re.subn(r'"args":\[[^\]]*\]', '"args":' + json.dumps(args), html, count=1)
    if n != 1:
        sys.exit("não achei GODOT_CONFIG.args no index.html")
    arq = "cena_%s.html" % nome
    open(os.path.join(WEB, arq), "w", encoding="utf-8").write(html2)
    return arq


def main():
    nomes = [a for a in sys.argv[1:] if not a.startswith("--")] or list(CENAS)
    if "--sem-exportar" not in sys.argv:
        print("exportando a versão Web...")
        exportar()
    os.makedirs(CENAS_DIR, exist_ok=True)
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORTA), functools.partial(Servidor, directory=WEB))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    with sync_playwright() as p:
        nav = p.chromium.launch(channel="chrome", args=["--headless=new", "--use-angle=d3d11", "--enable-gpu",
                                                        "--ignore-gpu-blocklist", "--autoplay-policy=no-user-gesture-required"])
        for nome in nomes:
            estagio, segundos = CENAS[nome]
            arq = pagina_da_cena(nome, estagio, segundos)
            ctx = nav.new_context(viewport={"width": 960, "height": 540}, accept_downloads=True)
            pg = ctx.new_page()
            pg.goto("http://127.0.0.1:%d/%s" % (PORTA, arq))
            try:
                pg.wait_for_function("document.title.startsWith('VITRINE')", timeout=120000)
            except Exception:
                print("  %s: o jogo não chegou na cena" % nome)
                ctx.close()
                continue
            # o robô precisa de uns segundos para sair da porta e achar briga
            time.sleep(2)
            real = segundos / LENTO
            with pg.expect_download(timeout=(real + 60) * 1000) as dl:
                tipo = pg.evaluate(GRAVAR_JS, real)
            destino = os.path.join(CENAS_DIR, nome + ".webm")
            dl.value.save_as(destino)
            json.dump({"lento": LENTO, "segundos": segundos}, open(os.path.join(CENAS_DIR, nome + ".json"), "w"))
            # foto final em 1080p (o jogo redesenha no tamanho novo: pixel 4x, sem ampliar depois)
            pg.set_viewport_size({"width": 1920, "height": 1080})
            for i in range(3):
                time.sleep(2.5)
                pg.screenshot(path=os.path.join(CENAS_DIR, "%s_%02d.png" % (nome, i)))
            ctx.close()
            print("  %s: %s (%s) %d KB" % (nome, destino, tipo, os.path.getsize(destino) // 1024))
        nav.close()
    srv.shutdown()


if __name__ == "__main__":
    main()
