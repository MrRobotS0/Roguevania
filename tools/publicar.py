"""Publica tudo em moksha.com.br: testes, export web, dados do site, site, jogo e API.

    python tools/publicar.py            # tudo (testes antes; para se falharem)
    python tools/publicar.py --sem-testes
    python tools/publicar.py --so-site  # só as páginas (sem exportar o jogo nem mexer na API)

Destino em .publicar_web (fora do git), uma linha: usuario@host. A chave SSH é
~/.ssh/moksha_ed25519 (ou MOKSHA_SSH_KEY). Antes de trocar qualquer coisa, o
servidor guarda uma cópia do site em /root/backups/. Precisa de paramiko
(pip install paramiko).
"""
import io
import os
import subprocess
import sys
import tarfile

import paramiko

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WEB = os.path.join(ROOT, "build", "web")
HOST_FILE = os.path.join(ROOT, ".publicar_web")
KEY = os.environ.get("MOKSHA_SSH_KEY") or os.path.join(os.path.expanduser("~"), ".ssh", "moksha_ed25519")
GODOT_EXE = "Godot_v4.7.2-stable_win64_console.exe"
GODOT = os.environ.get("MOKSHA_GODOT") or next(
    (p for p in (os.path.join(os.path.expanduser("~"), d, GODOT_EXE) for d in ("Desktop", os.path.join("OneDrive", "Desktop"), "Godot"))
     if os.path.exists(p)), os.path.join(os.path.expanduser("~"), "Desktop", GODOT_EXE))

REMOTE = r"""set -euo pipefail
U=/root/moksha-upload
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p /root/backups
tar -czf /root/backups/moksha-site-$TS.tgz -C /var/www moksha
ls -1t /root/backups/moksha-site-*.tgz | tail -n +11 | xargs -r rm --
rm -rf $U.d && mkdir $U.d && tar -xzf $U.tgz -C $U.d --no-same-owner
# site: copia por cima (não apaga jogar/ nem o que só existe lá)
cp -r $U.d/site/. /var/www/moksha/
chmod -R u=rwX,go=rX /var/www/moksha
if [ -d $U.d/jogar ]; then
  D=/var/www/moksha/jogar
  rm -rf $D.new && cp -r $U.d/jogar $D.new && chmod -R u=rwX,go=rX $D.new
  rm -rf $D.old && mv $D $D.old && mv $D.new $D && rm -rf $D.old
  echo "jogo trocado"
fi
if [ -d $U.d/api ]; then
  cp $U.d/api/server.js $U.d/api/package.json $U.d/api/schema.sql /opt/moksha-api/
  cd /opt/moksha-api && npm install --omit=dev --no-audit --no-fund --silent
  chown -R root:moksha /opt/moksha-api && chmod -R g+rX,o-rwx /opt/moksha-api
  DBURL=$(grep ^DATABASE_URL= /etc/moksha-api.env | cut -d= -f2-)
  psql "$DBURL" -q -v ON_ERROR_STOP=1 -f /opt/moksha-api/schema.sql
  systemctl restart moksha-api
  sleep 2
  systemctl is-active moksha-api
  echo "api trocada"
fi
rm -rf $U.d $U.tgz
curl -fsS -o /dev/null -w "site %{http_code}\n" https://moksha.com.br/
curl -fsS -o /dev/null -w "api %{http_code}\n" https://moksha.com.br/api/me
"""


def run(cmd, **kw):
    print("$", " ".join(cmd))
    r = subprocess.run(cmd, cwd=ROOT, **kw)
    if r.returncode != 0:
        sys.exit("falhou: " + " ".join(cmd))


def main():
    only_site = "--so-site" in sys.argv
    env = dict(os.environ, PYTHONIOENCODING="utf-8", MOKSHA_GODOT=GODOT)
    if not only_site and "--sem-testes" not in sys.argv:
        run([sys.executable, "tools/validar_salas.py"], env=env, stdout=subprocess.DEVNULL)
        run([sys.executable, "tools/validar_mapas.py"], env=env)
        out = subprocess.run([GODOT, "--headless", "--fixed-fps", "60", "--path", ".", "res://tests/run_tests.tscn"],
                             cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
        line = next((l for l in out.stdout.splitlines() if "falhas" in l), "")
        print(line or out.stdout[-500:])
        if " 0 falhas" not in line:
            sys.exit("os testes falharam: nada foi publicado")
    run([sys.executable, "tools/dados_site.py"], env=env)
    if not only_site:
        os.makedirs(WEB, exist_ok=True)
        open(os.path.join(ROOT, "build", ".gdignore"), "w").close()
        for f in os.listdir(WEB):
            os.remove(os.path.join(WEB, f))
        run([GODOT, "--headless", "--path", ".", "--export-release", "Web", "build/web/index.html"], capture_output=True)
        if not os.path.exists(os.path.join(WEB, "index.wasm")):
            sys.exit("a exportação web falhou")

    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz", compresslevel=6) as t:
        site = os.path.join(ROOT, "site")
        for d, _, files in os.walk(site):
            for f in files:
                if f.endswith(".import") or f == ".gdignore":
                    continue
                p = os.path.join(d, f)
                t.add(p, "site/" + os.path.relpath(p, site).replace(os.sep, "/"))
        if not only_site:
            for f in os.listdir(WEB):
                t.add(os.path.join(WEB, f), "jogar/" + f)
            for f in ("server.js", "package.json", "schema.sql"):
                t.add(os.path.join(ROOT, "servidor", "api", f), "api/" + f)
    if not os.path.exists(HOST_FILE):
        sys.exit("sem .publicar_web (uma linha: usuario@host): nada foi enviado")
    user, host = open(HOST_FILE, encoding="utf-8").read().strip().split("@", 1)
    print("enviando %d MB para %s" % (buf.tell() // 1048576, host))
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(host, username=user, key_filename=KEY, look_for_keys=False, allow_agent=False, timeout=20)
    sftp = c.open_sftp()
    buf.seek(0)
    sftp.putfo(buf, "/root/moksha-upload.tgz")
    sftp.close()
    _, o, e = c.exec_command(REMOTE, timeout=900)
    out = o.read().decode("utf-8", "replace")
    err = e.read().decode("utf-8", "replace")
    print(out, err)
    if o.channel.recv_exit_status() != 0:
        sys.exit("a troca no servidor falhou (o site anterior está em /root/backups/)")
    print("publicado")


if __name__ == "__main__":
    main()
