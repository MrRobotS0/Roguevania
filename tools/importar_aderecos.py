"""Adereços de cenário (árvore, coluna, miudeza de chão, coisa pendurada) tirados de
arte pronta e juntados num atlas.

    python tools/importar_aderecos.py     (depois de tools/baixar_arte.py)

Tudo em 1:1, sem ampliar nem girar: os pacotes são da mesma família da arte do
jogo (Gothicvania e vizinhos, do ansimuz), então a densidade de pixel já bate.
Cada item é um recorte de um arquivo de arte_externa/. A licença vem da tabela
arte_externa/LICENCAS.md (ou do texto de licença do próprio zip, quando ele pede
crédito e a tabela não) e só passa CC0 ou CC-BY.

Grava assets/sprites/decor.png e decor.json (onde cada item mora no atlas e
quais itens cada domínio usa em cada tipo de enfeite de Room._build_decor) e a
prévia build/auditoria/aderecos.png. Lista vazia = o jogo fica com o desenho
antigo daquele tipo. Só entra no atlas o que algum domínio usa: os itens
maiores que a vaga (a árvore morta grande, a cortina do forte, a moita com
cruzes) ficam descritos aqui e é só pôr o nome numa lista de DOMINIOS para
eles entrarem.
"""
import glob
import json
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "arte_externa")
OUT = os.path.join(ROOT, "assets", "sprites")
PREVIA = os.path.join(ROOT, "build", "auditoria", "aderecos.png")
FONTES = os.path.join(ROOT, "tools", "fontes")
LARGURA = 256
TIPOS = ("tree", "column", "bones", "mound", "shards", "banner", "chain")
DO_TETO = ("banner", "chain")
ACESOS = ("vela", "velas_altar", "pedestal_vela", "lanterna", "fornalha", "poste_lanternas")

CEMITERIO = "gothicvania-cemetery-pack/**/PNG/Environment/"
IGREJA = "gothicvania-church-pack/**/ENVIRONMENT/"
VILA = "gothicvania-town/**/PNG/environment/props-sliced/"
FORTE = "fort-of-illusion/**/Layers/"
PANTANO = "gotthicvania-swamp/**/Evironment/"
PASSO = "gothicvania-rocky-pass-environment/**/PNG/Props/"
HORROR = "gothicvania-patreons-collection/**/Gothic-Horror-Files/PNG/layers/tiles.png"
LATERAL = "sideview-fantasy-patreon-collection/**/"
RUINA = LATERAL + "Rocky-Tileset/PNG/layers/rocky-tileset-2.png"
DIA = LATERAL + "Day-Platformer/PNG/tileset.png"
MODULAR = LATERAL + "Modular-tileset/layers/modular-tileset.png"
PRAIA = LATERAL + "Rocky Beach environment/layers/tileset.png"
COLORIDO = LATERAL + "colorful-tileset/PNG/layers/tile-set.png"
TECIDO = "living-tissue-platform-tileset/**/PNG/layers/tileset.png"
PENHASCO = "magic-cliffs-environment/**/PNG/tileset.png"
PINHEIROS = "mountain-at-dusk-background/**/layers/parallax-mountain-foreground-trees.png"

# nome: (arquivo, caixa x y w h no arquivo — None = a imagem toda; uma lista = pedaços
#        empilhados de cima para baixo —, o que o desenho mostra)
ITENS = {
    "lapide_pontuda": (CEMITERIO + "sliced-objects/stone-1.png", None, "lápide de topo pontudo, lascada"),
    "cruz_torta": (CEMITERIO + "sliced-objects/stone-2.png", None, "cruz de pedra tombando de lado"),
    "lapide_inclinada": (CEMITERIO + "sliced-objects/stone-3.png", None, "lápide quadrada afundada de banda"),
    "lapide_estreita": (CEMITERIO + "sliced-objects/stone-4.png", None, "lápide alta e estreita de topo redondo"),
    "estatua_encapuzada": (CEMITERIO + "sliced-objects/statue.png", None,
                           "estátua de um vulto encapuzado, sem rosto, com uma espada apontada para o chão"),
    "moita": (CEMITERIO + "sliced-objects/bush-small.png", None, "moita de capim alto"),
    "moita_cruzes": (CEMITERIO + "sliced-objects/bush-large.png", None, "moita com duas cruzes de galho fincadas"),
    "arvore_morta": (CEMITERIO + "sliced-objects/tree-1.png", None, "árvore morta grande, de galhos abertos, com caveiras no tronco"),
    "coluna_ruina": (CEMITERIO + "tileset.png", (224, 48, 32, 48), "coluna de pedra escura com capitel"),
    "tronco_hera": (CEMITERIO + "tileset.png", (260, 64, 25, 32), "toco de tronco escuro enrolado em hera"),
    "mato_roxo": (CEMITERIO + "tileset.png", (142, 69, 17, 13), "fiapos de mato seco arroxeado"),
    "raiz_pendente": (CEMITERIO + "objects.png", (822, 106, 15, 19), "dois fios de raiz que se juntam numa gota"),
    "arvore_seca": (CEMITERIO + "graveyard.png", (118, 0, 23, 31), "arvorezinha morta, só galhos, em silhueta escura"),
    "arvore_torta": (CEMITERIO + "graveyard.png", (72, 4, 25, 29), "arvorezinha morta de tronco torto, em silhueta escura"),

    "barril": (VILA + "barrel.png", None, "barril de madeira com cintas vermelhas"),
    "caixote": (VILA + "crate.png", None, "caixote de madeira"),
    # o poste tem 108 px: sai um trecho liso do mastro para ele caber na vaga da árvore
    "poste_lanternas": (VILA + "street-lamp.png", [(0, 0, 35, 59), (0, 95, 35, 13)], "poste de ferro com três lanternas acesas"),
    "placa": (VILA + "sign.png", (7, 12, 21, 32), "placa de madeira lisa pendurada numa barra de ferro"),

    "bandeira": (FORTE + "Props/flag.png", None, "bandeira vermelha num mastro dourado"),
    "pilar_forte": (FORTE + "tileset.png", (160, 16, 32, 72), "pilar de pedra azulada com capitel"),
    "cortina_grande": (FORTE + "Props/banner.png", None, "cortina vermelha num varão dourado"),

    "pedestal": (IGREJA + "tileset.png", (192, 103, 16, 41), "pedestal torneado de pedra lilás"),
    "pedestal_vela": (IGREJA + "tileset.png", (256, 92, 16, 52), "pedestal de pedra com uma vela acesa em cima"),
    "vela": (IGREJA + "tileset.png", (262, 92, 5, 11), "vela acesa num pires"),
    "velas_altar": (IGREJA + "tileset.png", (196, 43, 26, 14), "castiçal em cruz com velas acesas dos lados"),
    "lanterna": (IGREJA + "column.png", (30, 96, 14, 20), "lanterna de ferro com brasa vermelha dentro"),
    "pilar_rostos": (IGREJA + "column.png", (39, 68, 49, 72), "pilar de pedra com três rostos esculpidos no alto"),

    "samambaia": (PANTANO + "props.png", (8, 4, 38, 35), "touceira de folhas compridas e pontudas"),
    "cipo_rasteiro": (PANTANO + "props.png", (60, 20, 55, 21), "cipó grosso enrolado rastejando no chão"),
    "arbusto_folhudo": (PANTANO + "props.png", (128, 10, 45, 32), "arbusto baixo de folhas largas"),
    "cipo_laco": (PANTANO + "trees.png", (73, 125, 17, 25), "laço de cipó fino com a ponta pingando"),

    "cristal_rubro": (PASSO + "crystal-1.png", None, "cristais vermelhos e rosados brotando do chão"),
    "cristal_baixo": (PASSO + "crystal-2.png", None, "três cristais vermelhos baixos"),
    "arbusto_seco": (PASSO + "plant-1.png", None, "arbusto seco cor de ferrugem"),
    "arbusto_seco_alto": (PASSO + "plant-2.png", None, "arbusto seco cor de ferrugem, de pontas compridas"),

    "ossada": (HORROR, (80, 112, 32, 16), "caveira com costelas e ossos espalhados"),
    "fornalha": (HORROR, (272, 96, 32, 64), "nicho de pedra em arco com uma chama acesa sobre um braseiro"),
    "nicho_mascara": (HORROR, (224, 112, 32, 48), "nicho em arco com uma máscara de chifres no escuro"),
    "gargula": (HORROR, (461, 37, 27, 35), "gárgula em forma de abutre encolhida numa laje"),
    "coluneta": (HORROR, (277, 64, 21, 32), "coluna curta e canelada com capitel largo"),

    "coluna_quebrada": (RUINA, (177, 88, 15, 48), "coluna de mármore rosado quebrada no topo"),
    "coluna_hera": (RUINA, (145, 81, 15, 55), "coluna quebrada tomada por uma trepadeira"),
    "bloco_rosto": (RUINA, (32, 16, 32, 32), "bloco de pedra com um rosto esculpido em relevo"),
    "raminho": (RUINA, (336, 58, 15, 10), "raminho de trepadeira de folhas claras"),

    "arbusto_redondo": (DIA, (208, 32, 32, 16), "arbusto redondo e baixo"),
    "arbusto_flores": (DIA, (256, 32, 32, 16), "arbusto baixo com flores brancas"),
    "capim": (DIA, (304, 39, 16, 9), "tufo de capim verde"),
    "cerca": (DIA, (336, 35, 16, 13), "pedaço de cerca de madeira, duas estacas"),
    "cristais_rosa": (DIA, (52, 142, 34, 6), "três cristais rosa entre pedras escuras"),
    "cristal_rosa": (DIA, (57, 131, 6, 7), "cristal rosa de ponta para cima"),
    "pedra_cristal": (DIA, (37, 147, 16, 12), "pedra escura com um cristal rosa encravado"),
    "tufo": (MODULAR, (16, 44, 15, 4), "tufo rasteiro de grama"),
    "broto": (MODULAR, (83, 39, 11, 9), "broto de duas folhas"),
    "caco_tijolo": (MODULAR, (114, 178, 12, 11), "pedaço de tijolo vermelho com farelos"),
    "pedra_clara": (PRAIA, (16, 118, 16, 10), "pedra esverdeada"),
    "pedra_areia": (PRAIA, (48, 118, 16, 10), "pedra cor de areia"),
    "cortina": (COLORIDO, (80, 112, 16, 32), "pano vermelho com barra dourada recortada e dois losangos"),

    "presa": (TECIDO, (130, 26, 12, 32), "presa comprida descendo da gengiva"),
    "dente_pendente": (TECIDO, (118, 22, 8, 20), "dente pendendo de um naco de gengiva"),
    "dentes_pendentes": (TECIDO, (96, 22, 16, 21), "dois dentes pendendo da gengiva"),
    "dentes": (TECIDO, (96, 69, 32, 23), "fileira de quatro dentes saindo da gengiva"),
    "par_dentes": (TECIDO, (96, 69, 16, 23), "dois dentes saindo da gengiva"),
    "dente": (TECIDO, (110, 70, 8, 13), "um dente saindo da gengiva"),
    "pustula": (TECIDO, (144, 84, 33, 28), "bolha de carne inchada num pescoço de tendões"),

    "estalactite": (PENHASCO, (400, 119, 12, 20), "estalactite de pedra azul-esverdeada"),
    "estalactites": (PENHASCO, (352, 119, 16, 21), "três pontas de estalactite juntas"),
    "pedra_musgo": (PENHASCO, (48, 121, 48, 30), "pedregulho com musgo e brotos em cima"),
    "moita_amarela": (PENHASCO, (256, 180, 32, 16), "moita de capim amarelo espetado"),
    "tufo_amarelo": (PENHASCO, (352, 183, 16, 13), "tufo de capim amarelo"),
    "capim_rasteiro": (PENHASCO, (307, 186, 29, 6), "faixa rasteira de capim amarelo"),

    "pinheiro_alto": (PINHEIROS, (114, 105, 31, 55), "pinheiro em silhueta escura com reflexo de ferrugem"),
    "pinheiro": (PINHEIROS, (242, 115, 23, 45), "pinheiro escuro meio torto"),
    "pinheiro_fino": (PINHEIROS, (76, 118, 18, 42), "pinheiro escuro e fino"),
}

# Sobras do desenho vizinho que vêm junto no recorte (x, y, w, h no arquivo).
APAGAR = {
    "pedestal": [(204, 118, 4, 5)],
    "pedestal_vela": [(256, 118, 3, 5)],
    "lanterna": [(42, 113, 2, 3)],
    "pilar_rostos": [(39, 94, 7, 46), (83, 94, 5, 46)],
    "arvore_torta": [(72, 30, 2, 3)],
}

# Itens pintados em cima de um fundo opaco: as cores desse fundo, tiradas de fora
# para dentro (o escuro fechado dentro do desenho fica).
PAREDE_IGREJA = [(22, 22, 51), (31, 30, 71), (45, 44, 86), (25, 24, 59), (58, 57, 104), (38, 37, 78), (65, 64, 111)]
MURO_RUINA = [(214, 180, 193), (236, 217, 223), (169, 105, 130), (179, 150, 161)]
FUNDO = {
    "ossada": [(24, 18, 32)],
    "cristais_rosa": [(23, 21, 32)],
    "cristal_rosa": [(23, 21, 32)],
    "pedra_cristal": [(23, 21, 32)],
    "velas_altar": PAREDE_IGREJA,
    "raminho": MURO_RUINA,
}

DOMINIOS = {
    "mar_de_cinzas": dict(tree=["arbusto_seco", "arbusto_seco_alto", "arvore_seca", "arvore_torta"],
                          column=["coluna_quebrada", "coluna_ruina", "cristal_rubro", "cristal_baixo"],
                          bones=["ossada", "mato_roxo"]),
    "saloes": dict(tree=["pilar_forte"], column=["pedestal", "coluna_quebrada"], bones=["ossada"],
                   banner=["estalactites"], chain=["estalactite"]),
    "forja_rubra": dict(tree=["fornalha", "coluna_ruina"], column=["barril", "coluneta"], bones=["caco_tijolo"]),
    "necropole": dict(tree=["estatua_encapuzada", "arvore_seca", "arvore_torta", "moita"],
                      column=["lapide_pontuda", "cruz_torta", "lapide_inclinada", "lapide_estreita", "coluna_ruina"],
                      bones=["ossada", "mato_roxo"], shards=["vela", "velas_altar"], chain=["raiz_pendente", "lanterna"]),
    "torre_babel": dict(tree=["caixote", "pilar_forte"], column=["barril", "pedestal", "coluneta"],
                        bones=["caco_tijolo"], shards=["vela"], banner=["placa"], chain=["lanterna"]),
    "jardim_primordial": dict(tree=["samambaia", "arbusto_folhudo", "cipo_rasteiro"], column=["tronco_hera"],
                              bones=["broto", "raminho"], mound=["tufo"], banner=["cipo_laco"],
                              chain=["raiz_pendente", "cipo_laco"]),
    "catedral": dict(tree=["pilar_rostos", "estatua_encapuzada"],
                     column=["pedestal", "pedestal_vela", "coluna_quebrada", "coluna_hera", "gargula"],
                     bones=["ossada"], shards=["vela", "velas_altar"], chain=["lanterna"]),
    "carcosa": dict(tree=["poste_lanternas", "nicho_mascara", "pilar_rostos"], column=["gargula", "bloco_rosto", "bandeira"],
                    banner=["cortina"], chain=["lanterna"]),
    "observatorio": dict(tree=["cristal_rubro"], column=["cristal_baixo"], bones=["pedra_clara"],
                         shards=["cristais_rosa", "cristal_rosa", "pedra_cristal"]),
    "ventre": dict(tree=["pustula", "dentes"], column=["par_dentes"], bones=["dente", "ossada"],
                   banner=["dentes_pendentes"], chain=["presa", "dente_pendente"]),
    "penhascos": dict(tree=["pedra_musgo"], column=["moita_amarela"], bones=["pedra_clara", "pedra_areia", "tufo_amarelo"],
                      mound=["capim_rasteiro"], banner=["estalactites"], chain=["estalactite", "raiz_pendente"]),
    "cavernas": dict(tree=["cristal_rubro"], column=["cristal_baixo"], bones=["pedra_clara", "pedra_areia"],
                     shards=["cristais_rosa", "cristal_rosa", "pedra_cristal"], banner=["estalactites"], chain=["estalactite"]),
    "bosque": dict(tree=["pinheiro_alto", "pinheiro", "pinheiro_fino", "moita", "arbusto_flores"],
                   column=["tronco_hera", "arbusto_redondo"], bones=["cerca", "capim"], mound=["tufo"],
                   chain=["raiz_pendente", "cipo_laco"]),
}

VULTO = [
    ".....###.....",
    "....#####....",
    "....#####....",
    "....#####....",
    ".....###.....",
    ".....###.....",
    "...#######...",
    "..#########..",
    "..#########..",
    ".###########.",
    ".##.#####.##.",
    ".##.#####.##.",
    ".##.#####.##.",
    ".##.#####.##.",
    ".##.#####.##.",
    ".##.#####.##.",
    "..#.#####.#..",
    "....#####....",
    "....#####....",
    "....##.##....",
    "....##.##....",
    "....##.##....",
    "....##.##....",
    "....##.##....",
    "....##.##....",
    "....##.##....",
    "....##.##....",
    "....##.##....",
    "...###.###...",
    "...###.###...",
]


def licencas():
    tabela = {}
    with open(os.path.join(ART, "LICENCAS.md"), encoding="utf-8") as f:
        for line in f:
            cols = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cols) == 4 and cols[0] not in ("Pacote", "---"):
                tabela[cols[0]] = (cols[1], cols[2])
    return tabela


def licenca(pacote, tabela):
    """A da tabela, que vem da página do OpenGameArt. Se o próprio zip traz um texto de
    licença pedindo crédito, vale o mais exigente dos dois."""
    autor, nome = tabela.get(pacote, ("", "sem registro em LICENCAS.md"))
    for path in glob.glob(os.path.join(ART, pacote, "**", "*licen*.txt"), recursive=True):
        if "__MACOSX" in path or os.path.basename(path).startswith("._"):
            continue
        with open(path, encoding="utf-8", errors="replace") as f:
            dentro = re.search(r"CC-BY-(\d\.\d)", f.read())
        if dentro and nome == "CC0":
            nome = "CC-BY " + dentro.group(1)
    if not nome.startswith(("CC0", "CC-BY ")):
        raise SystemExit("%s: licença %s não entra" % (pacote, nome))
    return nome if nome == "CC0" else "%s (%s)" % (nome, autor)


def achar(padrao):
    hits = sorted(f for f in glob.glob(os.path.join(ART, padrao), recursive=True)
                  if "__MACOSX" not in f and not os.path.basename(f).startswith("._"))
    if not hits:
        raise SystemExit("não achei: " + padrao)
    return hits[0]


def ancoras():
    """De que lado cada item usado se prende: sai do tipo das listas em que ele aparece."""
    lado = {}
    for dom, listas in DOMINIOS.items():
        for tipo, nomes in listas.items():
            if tipo not in TIPOS:
                raise SystemExit("%s: tipo desconhecido %s" % (dom, tipo))
            ancora = "teto" if tipo in DO_TETO else "chao"
            for nome in nomes:
                if nome not in ITENS:
                    raise SystemExit("%s.%s: não existe o item %s" % (dom, tipo, nome))
                if lado.setdefault(nome, ancora) != ancora:
                    raise SystemExit("%s está em lista de chão e de teto ao mesmo tempo" % nome)
    return lado


def sem_fundo(img, cores):
    px = img.load()
    w, h = img.size
    fila = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    while fila:
        x, y = fila.pop()
        if not (0 <= x < w and 0 <= y < h) or px[x, y][3] == 0 or px[x, y][:3] not in cores:
            continue
        px[x, y] = (0, 0, 0, 0)
        fila += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]


def recortar(nome, abertos):
    padrao, caixa, _ = ITENS[nome]
    path = achar(padrao)
    if path not in abertos:
        abertos[path] = Image.open(path).convert("RGBA")
    folha = abertos[path].copy()
    for x, y, w, h in APAGAR.get(nome, ()):
        folha.paste((0, 0, 0, 0), (x, y, x + w, y + h))
    pedacos = caixa if isinstance(caixa, list) else [caixa or (0, 0) + folha.size]
    img = Image.new("RGBA", (max(p[2] for p in pedacos), sum(p[3] for p in pedacos)), (0, 0, 0, 0))
    top = 0
    for x, y, w, h in pedacos:
        img.paste(folha.crop((x, y, x + w, y + h)), (0, top))
        top += h
    if nome in FUNDO:
        sem_fundo(img, set(FUNDO[nome]))
    img = img.crop(img.getchannel("A").getbbox())
    return img, os.path.relpath(path, ART).replace(os.sep, "/")


def empacotar(imgs):
    """Prateleiras: do mais alto para o mais baixo, 1 px transparente em volta de cada um."""
    pos = {}
    x, y, shelf = 0, 0, 0
    for nome in sorted(imgs, key=lambda n: (-imgs[n].height, -imgs[n].width, n)):
        w, h = imgs[nome].width + 2, imgs[nome].height + 2
        if x + w > LARGURA:
            x, y, shelf = 0, y + shelf, 0
        pos[nome] = (x + 1, y + 1)
        x += w
        shelf = max(shelf, h)
    atlas = Image.new("RGBA", (LARGURA, y + shelf), (0, 0, 0, 0))
    for nome, p in pos.items():
        atlas.alpha_composite(imgs[nome], p)
    return atlas, pos


def fonte(nome, tamanho):
    try:
        return ImageFont.truetype(os.path.join(FONTES, nome), tamanho)
    except OSError:
        return ImageFont.load_default()


def heroi_parado():
    """O herói como está na folha do jogo, para comparar tamanho e cor."""
    try:
        with open(os.path.join(OUT, "hero_g.json"), encoding="utf-8") as f:
            m = json.load(f)
        folha = Image.open(os.path.join(OUT, "hero_g.png")).convert("RGBA")
    except OSError:
        return None
    top = m["anims"]["idle"]["row"] * m["h"]
    quadro = folha.crop((0, top, m["w"], top + m["h"]))
    return quadro.crop(quadro.getchannel("A").getbbox())


def previa(atlas, meta):
    """Uma faixa por domínio: os itens em 3x, de pé no chão ou pendurados no teto,
    com nome, tipo e tamanho embaixo. Na ponta, para dar escala, um vulto de 30 px
    e o herói do jogo."""
    z = 3
    fundo, linha, tinta, apagada = (0x2a, 0x24, 0x30, 255), (74, 66, 84, 255), (232, 222, 200, 255), (150, 140, 160, 255)
    titulo, letra = fonte("PixelifySans[wght].ttf", 20), fonte("Tiny5.ttf", 16)
    vulto = Image.new("RGBA", (len(VULTO[0]), len(VULTO)), (0, 0, 0, 0))
    for y, row in enumerate(VULTO):
        for x, c in enumerate(row):
            if c == "#":
                vulto.putpixel((x, y), (126, 116, 140, 255))
    escala = [("30 px", "", vulto, "chao")]
    heroi = heroi_parado()
    if heroi:
        escala.append(("heroi", "%dx%d" % heroi.size, heroi, "chao"))
    faixas = []
    for dom, listas in DOMINIOS.items():
        vazios = [tipo for tipo in TIPOS if not listas.get(tipo)]
        aviso = "sem arte (fica o desenho antigo): " + ", ".join(vazios) if vazios else ""
        cells = list(escala)
        for tipo in TIPOS:
            for nome in listas.get(tipo, ()):
                m = meta[nome]
                recorte = atlas.crop((m["x"], m["y"], m["x"] + m["w"], m["y"] + m["h"]))
                cells.append((nome, "%s %dx%d" % (tipo, m["w"], m["h"]), recorte, m["ancora"]))
        alto = max(im.height for _, _, im, _ in cells) * z
        widths = [max(im.width * z, int(letra.getlength(a)), int(letra.getlength(b))) + 18 for a, b, im, _ in cells]
        cabeca = 24 + int(titulo.getlength(dom)) + int(letra.getlength(aviso))
        faixa = Image.new("RGBA", (max(sum(widths) + 12, cabeca), alto + 86), fundo)
        d = ImageDraw.Draw(faixa)
        d.fontmode = "1"
        d.text((8, 4), dom, font=titulo, fill=tinta)
        d.text((16 + int(titulo.getlength(dom)), 9), aviso, font=letra, fill=apagada)
        teto, chao = 34, 34 + alto + 6
        d.line((0, teto - 1, faixa.width, teto - 1), fill=linha)
        d.line((0, chao, faixa.width, chao), fill=linha)
        x = 6
        for (a, b, im, ancora), w in zip(cells, widths):
            big = im.resize((im.width * z, im.height * z), Image.NEAREST)
            faixa.alpha_composite(big, (x + (w - big.width) // 2, teto if ancora == "teto" else chao - big.height))
            d.text((x + (w - int(letra.getlength(a))) // 2, chao + 5), a, font=letra, fill=tinta)
            d.text((x + (w - int(letra.getlength(b))) // 2, chao + 23), b, font=letra, fill=apagada)
            x += w
        faixas.append(faixa)
    sheet = Image.new("RGBA", (max(f.width for f in faixas), sum(f.height for f in faixas)), fundo)
    y = 0
    for f in faixas:
        sheet.paste(f, (0, y))
        y += f.height
    os.makedirs(os.path.dirname(PREVIA), exist_ok=True)
    sheet.save(PREVIA)
    return sheet.size


def chamas(img):
    """Onde ficam as chamas de um desenho: centro e raio de cada mancha de pixels
    claros e quentes, e a cor média delas. O jogo põe um halo em cada uma."""
    px = img.convert("RGBA").load()
    w, h = img.size

    def quente(x, y):
        r, g, b, a = px[x, y]
        # fogo e brasa são quentes e sem azul; o amarelo da chama tem mais verde que vermelho.
        # Pedra clara e cera (com azul no meio) ficam de fora.
        return a > 128 and ((r >= 180 and b <= 60) or (g >= r >= 170 and b <= 140) or (r >= 215 and g >= 150 and b <= 90))

    visto, manchas = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in visto or not quente(x, y):
                continue
            pilha, grupo = [(x, y)], []
            visto.add((x, y))
            while pilha:
                cx, cy = pilha.pop()
                grupo.append((cx, cy))
                for nx in (cx - 1, cx, cx + 1):
                    for ny in (cy - 1, cy, cy + 1):
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visto and quente(nx, ny):
                            visto.add((nx, ny))
                            pilha.append((nx, ny))
            manchas.append(grupo)
    manchas.sort(key=len, reverse=True)
    luzes, soma, n = [], [0, 0, 0], 0
    for grupo in manchas[:4]:
        if len(grupo) < 2:
            continue
        mx = sum(q[0] for q in grupo) / len(grupo) + 0.5
        my = sum(q[1] for q in grupo) / len(grupo) + 0.5
        luzes.append([round(mx, 1), round(my, 1), round(9 + 2.2 * len(grupo) ** 0.5, 1)])
        for q in grupo:
            soma = [s + c for s, c in zip(soma, px[q][:3])]
        n += len(grupo)
    return luzes, ("%02x%02x%02x" % tuple(s // n for s in soma) if n else "")


def main():
    lado = ancoras()
    tabela = licencas()
    abertos, imgs, origem = {}, {}, {}
    for nome in ITENS:
        if nome in lado:
            imgs[nome], origem[nome] = recortar(nome, abertos)
    atlas, pos = empacotar(imgs)
    meta, do_pacote = {}, {}
    for nome in imgs:
        pacote = origem[nome].split("/")[0]
        if pacote not in do_pacote:
            do_pacote[pacote] = licenca(pacote, tabela)
        meta[nome] = {"x": pos[nome][0], "y": pos[nome][1], "w": imgs[nome].width, "h": imgs[nome].height,
                      "ancora": lado[nome], "origem": origem[nome], "licenca": do_pacote[pacote], "mostra": ITENS[nome][2]}
        if nome in ACESOS:
            luzes, cor = chamas(imgs[nome])
            if luzes:
                meta[nome]["luzes"] = luzes
                meta[nome]["cor_luz"] = cor
    dominios = {dom: {tipo: list(listas.get(tipo, ())) for tipo in TIPOS} for dom, listas in DOMINIOS.items()}
    atlas.save(os.path.join(OUT, "decor.png"))
    with open(os.path.join(OUT, "decor.json"), "w", encoding="utf-8", newline="\n") as f:
        f.write('{\n  "itens": {\n')
        f.write(",\n".join("    %s: %s" % (json.dumps(n), json.dumps(m, ensure_ascii=False)) for n, m in meta.items()))
        f.write('\n  },\n  "dominios": {\n')
        f.write(",\n".join("    %s: %s" % (json.dumps(d), json.dumps(l)) for d, l in dominios.items()))
        f.write("\n  }\n}\n")
    print("decor.png", atlas.size, "·", len(meta), "itens · prévia", previa(atlas, meta))
    fora = [n for n in ITENS if n not in lado]
    if fora:
        print("fora do atlas (nenhum domínio usa):", ", ".join(fora))


if __name__ == "__main__":
    main()
