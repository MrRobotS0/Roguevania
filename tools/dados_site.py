"""Gera site/dados/jogo.json: conquistas, aparências e guardiões, em PT e EN,
para as páginas de perfil e ranking de moksha.com.br.

    python tools/dados_site.py

Lê os dados do próprio jogo (catalog.gd, content/skins, content/lang/en.txt):
rodar de novo sempre que mudar conquista ou aparência.
"""
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def english():
    out = {}
    with open(os.path.join(ROOT, "content", "lang", "en.txt"), encoding="utf-8") as f:
        for line in f:
            if line.startswith(";") or " = " not in line:
                continue
            pt, en = line.rstrip("\n").split(" = ", 1)
            out[pt.strip().upper()] = en.strip()
    return out


def main():
    en = english()
    tr = lambda pt: en.get(pt.upper(), pt)
    catalog = open(os.path.join(ROOT, "scripts", "combat", "catalog.gd"), encoding="utf-8").read()
    block = catalog[catalog.index("const FEATS := ["):]
    block = block[:block.index("\n]")]
    feats = []
    for m in re.finditer(r"\{[^{}]*\}", block):
        d = {k: v for k, v in re.findall(r'"(\w+)":\s*"([^"]*)"', m.group(0))}
        if "id" not in d:
            continue
        feats.append({"id": d["id"], "pt": d["title"], "en": tr(d["title"]).capitalize(),
                      "detalhe_pt": d.get("detail", "").capitalize(), "detalhe_en": tr(d.get("detail", "")).capitalize(),
                      "secreta": '"secret": true' in m.group(0)})
    skins = []
    folder = os.path.join(ROOT, "content", "skins")
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".tres"):
            continue
        txt = open(os.path.join(folder, name), encoding="utf-8").read()
        sid = re.search(r'^id = "([^"]+)"', txt, re.M).group(1)
        title = re.search(r'^title = "([^"]+)"', txt, re.M).group(1)
        skins.append({"id": sid, "pt": title, "en": tr(title).capitalize()})
    g = re.search(r"const GUARDIANS := \[(.*?)\]", catalog, re.S).group(1)
    guardians = [{"pt": t, "en": tr(t)} for t in re.findall(r'"([^"]+)"', g)]
    os.makedirs(os.path.join(ROOT, "site", "dados"), exist_ok=True)
    with open(os.path.join(ROOT, "site", "dados", "jogo.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"conquistas": feats, "aparencias": skins, "guardioes": guardians}, f, ensure_ascii=False, indent=1)
    print("%d conquistas, %d aparências, %d guardiões" % (len(feats), len(skins), len(guardians)))


if __name__ == "__main__":
    main()
