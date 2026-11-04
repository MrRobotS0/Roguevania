"""Baixa os pacotes de arte do OpenGameArt usados no jogo, conferindo a
licença de cada página antes (só entra o que permite uso comercial).

    python tools/baixar_arte.py

Os zips vão para arte_externa/<pacote>/ (fora do git e do Godot), e
arte_externa/LICENCAS.md registra autor, licença e endereço de cada um.
"""
import os
import re
import urllib.parse
import urllib.request
import zipfile

ROOT = os.path.join(os.path.dirname(__file__), "..")
DEST = os.path.join(ROOT, "arte_externa")
UA = {"User-Agent": "Mozilla/5.0 (MOKSHA asset fetch)"}
OK = ("CC0", "CC-BY 3.0", "CC-BY 4.0", "OGA-BY 3.0", "CC-BY-SA 3.0", "CC-BY-SA 4.0")

PACKS = [
    "gothicvania-church-pack", "gothicvania-cemetery-pack", "gotthicvania-swamp", "gothicvania-town",
    "gothicvania-patreons-collection", "gothicvania-bridge-expansion-pack-1", "gothicvania-rocky-pass-environment",
    "gothicvania-junk-wasteland-environment", "gothicvania-magic-pack-9", "hell-hound-character",
    "dark-fantasy-platformer-bestiary", "dark-emperor", "magic-cliffs-environment", "mountain-at-dusk-background",
    "forest-background", "industrial-parallax-background", "horror-tile-set", "cavern-tile-set",
    "living-tissue-platform-tileset", "living-tissue-background", "sideview-fantasy-patreon-collection",
    "animated-explosions", "space-background-3", "fort-of-illusion", "magical-road-pixel-art-environment",
    # kits de interface (HUD por domínio), todos CC0
    "fantasy-ui-borders", "pixel-ui-pack-750-assets", "1-bit-pack", "golden-ui", "tiny-rpg-dragon-regalia-gui",
    "tiny-rpg-mana-soul-gui", "pixel-uihud-pack", "pixel-uihud-pack-2", "retropixel-icons-v1-9x9", "pixel-hearts",
    "scroll-themed-hud-bars", "pixui-asset-pack-1-ctatz", "pixel-ui-kit", "sci-fi-user-interface", "health-orb-11",
    "retro-pixel-art-guihud-elements-including-dialogue-box", "basic-hud-tiles-alphabet",
    # personagens que casam com a história (garimpo de 04/11): Lobo Pálido, Espinheiro, Colosso
    "pixel-wolf", "pixel-predator-plant-mob-character", "animated-statue",
    # ícones dos itens (armas, habilidades, mutações): pixel art pronta
    "496-pixel-art-icons-for-medievalfantasy-rpg", "fantasy-icon-pack-by-ravenmore-0",
]


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60).read()


def main():
    os.makedirs(DEST, exist_ok=True)
    open(os.path.join(DEST, ".gdignore"), "w").close()
    log = ["# Arte de terceiros", "", "| Pacote | Autor | Licença | Página |", "|---|---|---|---|"]
    only = [a for a in __import__('sys').argv[1:]]
    for slug in PACKS:
        if only and slug not in only:
            continue
        page = "https://opengameart.org/content/" + slug
        html = get(page).decode("utf-8", "ignore")
        lic = re.findall(r"license-name[^>]*>([^<]+)", html)
        lic = [l.strip() for l in lic]
        author = (re.findall(r'field-name-author-submitter.*?<a[^>]*>([^<]+)</a>', html, re.S) or ["?"])[0].strip()
        if not lic or not all(any(l.startswith(o) for o in OK) for l in lic):
            print("PULADO (licença %s): %s" % (lic, slug))
            continue
        files = sorted(set(re.findall(r'href="(https://opengameart.org/sites/default/files/[^"]+\.(?:zip|rar|7z|png|gif))"', html)))
        files = [f for f in files if "/css/" not in f]
        zips = [f for f in files if f.endswith(".zip")] or files
        folder = os.path.join(DEST, slug)
        os.makedirs(folder, exist_ok=True)
        for url in zips:
            name = urllib.parse.unquote(url.rsplit("/", 1)[1])
            path = os.path.join(folder, name)
            if not os.path.exists(path):
                open(path, "wb").write(get(url))
            if name.endswith(".zip"):
                try:
                    zipfile.ZipFile(path).extractall(folder)
                except zipfile.BadZipFile:
                    print("zip ruim:", name)
        log.append("| %s | %s | %s | %s |" % (slug, author, ", ".join(lic), page))
        print("ok %-42s %s  %s" % (slug, ", ".join(lic), author))
    if only:
        # baixando só alguns: soma ao registro que já existe em vez de apagá-lo
        path = os.path.join(DEST, "LICENCAS.md")
        old = open(path, encoding="utf-8").read().splitlines() if os.path.exists(path) else log[:4]
        keep = [l for l in old if not any(l.startswith("| %s |" % o) for o in only)]
        log = keep + log[4:]
    open(os.path.join(DEST, "LICENCAS.md"), "w", encoding="utf-8").write("\n".join(log) + "\n")


if __name__ == "__main__":
    main()
