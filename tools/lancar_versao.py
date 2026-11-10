"""Solta uma versão nova do MOKSHA (Windows, navegador e site), de uma vez.

    python tools/lancar_versao.py 0.8.0 "O que mudou nesta versão"

1. grava a versão em project.godot e nos textos do site;
2. roda os testes (para se algum falhar);
3. exporta build/Moksha.exe + build/Moksha.pck e monta build/Moksha-windows.zip;
4. commit + tag vX.Y.Z + push (confere se o autor é a conta do GitHub);
5. cria o Release no GitHub com o zip (quem baixa pela primeira vez) e o
   Moksha.pck (o que o jogo baixa sozinho para se atualizar);
6. atualiza o gh-pages (site do GitHub Pages) com site/;
7. publica moksha.com.br: site, jogo de navegador e API (tools/publicar.py).

O Release usa o token do GitHub de GITHUB_TOKEN ou, sem ele, o mesmo login
que o git já usa para dar push (git credential). Quem já tem o jogo recebe a
versão nova na próxima vez que abrir: o jogo vê o Release, baixa o .pck e se
reabre com ele.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REPO = "MrRobotS0/Roguevania"
AUTHOR_EMAIL = "guilhermebelinelo@outlook.com"
GODOT_EXE = "Godot_v4.7.2-stable_win64_console.exe"
GODOT = os.environ.get("MOKSHA_GODOT") or next(
    (p for p in (os.path.join(os.path.expanduser("~"), d, GODOT_EXE) for d in ("Desktop", os.path.join("OneDrive", "Desktop"), "Godot"))
     if os.path.exists(p)), os.path.join(os.path.expanduser("~"), "Desktop", GODOT_EXE))
BUILD = os.path.join(ROOT, "build")
# páginas que só funcionam em moksha.com.br (precisam da API): não vão para o GitHub Pages
WEB_ONLY = {"conta.html", "ranking.html", "perfil.html", "admin.html", "privacidade.html", "comum.js", "estilo.css"}


def run(cmd, **kw):
    print(">", " ".join(cmd))
    r = subprocess.run(cmd, cwd=kw.pop("cwd", ROOT), **kw)
    if r.returncode != 0:
        sys.exit("falhou: " + " ".join(cmd))
    return r


def out(cmd, **kw):
    return subprocess.run(cmd, cwd=kw.pop("cwd", ROOT), capture_output=True, text=True, **kw).stdout.strip()


def github_token():
    if os.environ.get("GITHUB_TOKEN"):
        return os.environ["GITHUB_TOKEN"]
    r = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
                       capture_output=True, text=True, cwd=ROOT)
    for line in r.stdout.splitlines():
        if line.startswith("password="):
            return line[len("password="):]
    sys.exit("sem token do GitHub: defina GITHUB_TOKEN")


def api(method, url, token, data=None, content_type="application/json"):
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
        "User-Agent": "moksha-lancar-versao", "Content-Type": content_type})
    with urllib.request.urlopen(req, timeout=600) as r:
        return json.loads(r.read() or b"{}")


def release(version, notes, files):
    token = github_token()
    rel = api("POST", "https://api.github.com/repos/%s/releases" % REPO, token,
              json.dumps({"tag_name": "v" + version, "name": "MOKSHA " + version, "body": notes}).encode())
    upload = rel["upload_url"].split("{")[0]
    for f in files:
        name = os.path.basename(f)
        print("> enviando", name)
        with open(f, "rb") as fh:
            api("POST", upload + "?name=" + name, token, fh.read(), "application/octet-stream")
    print("release:", rel["html_url"])


def update_gh_pages(version):
    tmp = tempfile.mkdtemp(prefix="moksha-pages-")
    try:
        run(["git", "worktree", "add", "-f", tmp, "gh-pages"])
        for name in os.listdir(tmp):
            if name != ".git":
                p = os.path.join(tmp, name)
                shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)
        site = os.path.join(ROOT, "site")
        for d, _, files in os.walk(site):
            for f in files:
                src = os.path.join(d, f)
                rel = os.path.relpath(src, site).replace(os.sep, "/")
                if f.endswith(".import") or rel in WEB_ONLY or rel.startswith("dados/"):
                    continue
                dst = os.path.join(tmp, rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(src, dst)
        run(["git", "add", "-A"], cwd=tmp)
        if out(["git", "status", "--porcelain"], cwd=tmp):
            run(["git", "commit", "-q", "-m", "Site da versão %s" % version], cwd=tmp)
            run(["git", "push", "origin", "gh-pages"], cwd=tmp)
    finally:
        subprocess.run(["git", "worktree", "remove", "--force", tmp], cwd=ROOT)


def main():
    if len(sys.argv) < 3 or not re.fullmatch(r"\d+\.\d+\.\d+", sys.argv[1]):
        sys.exit(__doc__)
    version, notes = sys.argv[1], sys.argv[2]
    if out(["git", "config", "user.email"]) != AUTHOR_EMAIL:
        sys.exit("o autor do git não é %s: rode git config user.email %s" % (AUTHOR_EMAIL, AUTHOR_EMAIL))

    path = os.path.join(ROOT, "project.godot")
    text = open(path, encoding="utf-8").read()
    text = re.sub(r'config/version="[^"]*"', 'config/version="%s"' % version, text)
    open(path, "w", encoding="utf-8", newline="\n").write(text)
    # a versão que aparece no site (landing)
    page = os.path.join(ROOT, "site", "index.html")
    html = open(page, encoding="utf-8").read()
    html = re.sub(r"V\d+\.\d+\.\d+", "V" + version, html)
    html = re.sub(r"v\d+\.\d+\.\d+", "v" + version, html)
    open(page, "w", encoding="utf-8", newline="").write(html)

    subprocess.run([GODOT, "--headless", "--import", "--path", "."], cwd=ROOT, capture_output=True)
    tests = subprocess.run([GODOT, "--headless", "--fixed-fps", "60", "--path", ".", "res://tests/run_tests.tscn"],
                           cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    summary = [l for l in tests.stdout.splitlines() if "falhas" in l]
    print(summary[-1] if summary else tests.stdout[-500:])
    if not summary or " 0 falhas" not in summary[-1]:
        sys.exit("testes falharam; nada foi lançado")

    os.makedirs(BUILD, exist_ok=True)
    open(os.path.join(BUILD, ".gdignore"), "w").close()
    run([GODOT, "--headless", "--path", ".", "--export-release", "Windows Desktop", "build/Moksha.exe"], capture_output=True)
    zip_path = os.path.join(BUILD, "Moksha-windows.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        z.write(os.path.join(BUILD, "Moksha.exe"), "Moksha/Moksha.exe")
        z.write(os.path.join(BUILD, "Moksha.pck"), "Moksha/Moksha.pck")
    print("zip: %d MB" % (os.path.getsize(zip_path) // 1048576))

    run(["git", "add", "-A"])
    run(["git", "commit", "-q", "-m", "Versão %s: %s" % (version, notes)])
    run(["git", "tag", "v" + version])
    run(["git", "push", "origin", "master", "--tags"])
    release(version, notes, [zip_path, os.path.join(BUILD, "Moksha.pck")])
    update_gh_pages(version)
    run([sys.executable, os.path.join("tools", "publicar.py"), "--sem-testes"])
    print("pronto: v" + version)


if __name__ == "__main__":
    main()
