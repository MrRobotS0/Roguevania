"""Solta uma versão nova do MOKSHA.

    python tools/lancar_versao.py 0.2.0 "O que mudou nesta versão"

1. grava a versão em project.godot (application/config/version);
2. roda os testes (para se algum falhar);
3. exporta build/Moksha.exe + build/Moksha.pck e monta build/Moksha-windows.zip;
4. commit + tag vX.Y.Z + push;
5. cria o Release no GitHub com o zip (quem baixa pela primeira vez) e o
   Moksha.pck (o que o jogo baixa sozinho para se atualizar).
6. exporta a versão de navegador e troca os arquivos no servidor (publicar_web.py).

Quem já tem o jogo recebe a versão nova na próxima vez que abrir: o jogo vê
o Release, baixa o .pck e se reabre com ele.
"""
import os
import re
import subprocess
import sys
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GODOT = os.path.join(os.path.expanduser("~"), "Desktop", "Godot_v4.7.2-stable_win64_console.exe")
BUILD = os.path.join(ROOT, "build")


def run(cmd, **kw):
    print(">", " ".join(cmd))
    r = subprocess.run(cmd, cwd=ROOT, **kw)
    if r.returncode != 0:
        sys.exit("falhou: " + " ".join(cmd))
    return r


def main():
    if len(sys.argv) < 3 or not re.fullmatch(r"\d+\.\d+\.\d+", sys.argv[1]):
        sys.exit(__doc__)
    version, notes = sys.argv[1], sys.argv[2]

    path = os.path.join(ROOT, "project.godot")
    text = open(path, encoding="utf-8").read()
    text = re.sub(r'config/version="[^"]*"', 'config/version="%s"' % version, text)
    open(path, "w", encoding="utf-8", newline="\n").write(text)

    subprocess.run([GODOT, "--headless", "--import", "--path", "."], cwd=ROOT, capture_output=True)
    tests = subprocess.run([GODOT, "--headless", "--fixed-fps", "60", "--path", ".", "res://tests/run_tests.tscn"],
                           cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    summary = [l for l in tests.stdout.splitlines() if "falhas" in l]
    print(summary[-1] if summary else tests.stdout[-500:])
    if tests.returncode != 0:
        sys.exit("testes falharam; nada foi lançado")

    os.makedirs(BUILD, exist_ok=True)
    run([GODOT, "--headless", "--path", ".", "--export-release", "Windows Desktop", "build/Moksha.exe"], capture_output=True)
    zip_path = os.path.join(BUILD, "Moksha-windows.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        z.write(os.path.join(BUILD, "Moksha.exe"), "Moksha/Moksha.exe")
        z.write(os.path.join(BUILD, "Moksha.pck"), "Moksha/Moksha.pck")
    print("zip: %d MB" % (os.path.getsize(zip_path) // 1048576))

    run(["git", "add", "-A"])
    run(["git", "commit", "-m", "Versão %s: %s" % (version, notes)])
    run(["git", "tag", "v" + version])
    run(["git", "push", "origin", "master", "--tags"])
    run(["gh", "release", "create", "v" + version, zip_path, os.path.join(BUILD, "Moksha.pck"),
         "--title", "MOKSHA " + version, "--notes", notes])
    run([sys.executable, os.path.join("tools", "publicar_web.py")])
    print("pronto: v" + version)


if __name__ == "__main__":
    main()
