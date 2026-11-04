"""Junta todo texto que o jogador vê (código e conteúdo) para traduzir.

    python tools/textos.py            lista o que ainda não tem tradução
    python tools/textos.py --tudo     lista tudo

A tradução fica em content/lang/en.txt, uma linha por texto:
    TEXTO EM PORTUGUÊS = TEXT IN ENGLISH
Chaves com %d ou %s valem para qualquer número/texto naquele lugar.
"""
import glob
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..")
QUOTED = re.compile(r'"((?:[^"\\]|\\.)*)"')
SKIP_FILES = ("tests", "debug")


def is_text(t):
    if not re.search(r"[A-Za-zÀ-ú]{2}", t):
        return False
    if t.startswith(("res://", "user://", "#")) or re.fullmatch(r"[a-z0-9_\-./%]+", t):
        return False
    if re.fullmatch(r"[A-Za-z_]+", t) and not t.isupper():
        return False
    return True


def gather():
    out = {}
    for f in glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True):
        if any(s in f for s in SKIP_FILES):
            continue
        for line in open(f, encoding="utf-8"):
            code = line.split("#")[0] if not line.strip().startswith("#") else ""
            for m in QUOTED.finditer(code):
                t = m.group(1).replace('\\"', '"').replace("\\n", "\n")
                if is_text(t):
                    for part in t.split("\n"):
                        if is_text(part):
                            out.setdefault(part.upper(), os.path.relpath(f, ROOT))
    for f in glob.glob(os.path.join(ROOT, "content", "**", "*.tres"), recursive=True):
        s = open(f, encoding="utf-8").read()
        for key in ("title", "subtitle", "lore", "detail", "feat_text"):
            for m in re.finditer(r"^%s = \"((?:[^\"\\]|\\.)*)\"" % key, s, re.M):
                out.setdefault(m.group(1).replace('\\"', '"').upper(), os.path.relpath(f, ROOT))
        m = re.search(r"^lore = \[(.*)\]", s, re.M)
        if m:
            for x in QUOTED.findall(m.group(1)):
                out.setdefault(x.replace('\\"', '"').upper(), os.path.relpath(f, ROOT))
    return out


def known():
    path = os.path.join(ROOT, "content", "lang", "en.txt")
    done = {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            if " = " in line and not line.startswith(";"):
                k, v = line.rstrip("\n").split(" = ", 1)
                done[k] = v
    return done


if __name__ == "__main__":
    texts = gather()
    done = known()
    todo = sorted(t for t in texts if t not in done or "--tudo" in sys.argv)
    for t in todo:
        print(t)
    print("--", len(texts), "textos,", len(todo), "sem tradução", file=sys.stderr)
