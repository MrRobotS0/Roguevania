"""Exporta o jogo para navegador e troca os arquivos no servidor.

    python tools/publicar_web.py

O destino (usuário@host) fica em .publicar_web, fora do git. Sem esse arquivo,
só exporta. A troca é por renomeação: quem está carregando não pega metade de
uma versão.
"""
import io
import os
import subprocess
import sys
import tarfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GODOT = os.path.join(os.path.expanduser("~"), "Desktop", "Godot_v4.7.2-stable_win64_console.exe")
WEB = os.path.join(ROOT, "build", "web")
HOST_FILE = os.path.join(ROOT, ".publicar_web")
KEY = os.path.join(os.path.expanduser("~"), ".ssh", "id_ed25519")
SWAP = ("set -e; rm -rf /var/www/moksha.new; mkdir -p /var/www/moksha.new; "
        "tar -xzf - --no-same-owner -C /var/www/moksha.new; chmod -R u=rwX,go=rX /var/www/moksha.new; "
        "rm -rf /var/www/moksha.old; if [ -d /var/www/moksha ]; then mv /var/www/moksha /var/www/moksha.old; fi; "
        "mv /var/www/moksha.new /var/www/moksha; rm -rf /var/www/moksha.old")


def main():
    os.makedirs(WEB, exist_ok=True)
    # sem isto o Godot trata os PNGs do build como parte do projeto e cria .import ao lado deles
    open(os.path.join(ROOT, "build", ".gdignore"), "w").close()
    r = subprocess.run([GODOT, "--headless", "--path", ".", "--export-release", "Web", "build/web/index.html"],
                       cwd=ROOT, capture_output=True)
    if r.returncode != 0 or not os.path.exists(os.path.join(WEB, "index.wasm")):
        sys.exit("a exportação web falhou")
    if not os.path.exists(HOST_FILE):
        print("sem .publicar_web: exportado em build/web, nada foi enviado")
        return
    host = open(HOST_FILE, encoding="utf-8").read().strip()
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz", compresslevel=6) as t:
        for name in sorted(os.listdir(WEB)):
            if not name.endswith(".import"):
                t.add(os.path.join(WEB, name), name)
    r = subprocess.run(["ssh", "-i", KEY, "-o", "IdentitiesOnly=yes", "-o", "PreferredAuthentications=publickey",
                        host, SWAP], input=buf.getvalue())
    if r.returncode != 0:
        sys.exit("o envio falhou")
    print("web publicada: %d MB enviados" % (buf.tell() // 1048576))


if __name__ == "__main__":
    main()
