"""Monta o que vai para a página do itch.io.

- build/itch/moksha-itch.zip: a tela de entrada (itch/index.html + imagens). No itch:
  Kind of project = HTML, marcar "This file will be played in the browser".
- build/itch/capa.png: capa 630x500, recortada de site/img/og.png.

O jogo em si continua em moksha.com.br: a tela só tem o botão JOGAR que abre o site.
Uso: python tools/empacotar_itch.py
"""
import os
import zipfile

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "itch")
SAIDA = os.path.join(RAIZ, "build", "itch")
IMAGENS = {"mar.png": "site/img/mar.png", "heroi.png": "site/img/heroi.png"}


def main() -> None:
    os.makedirs(SAIDA, exist_ok=True)
    zip_path = os.path.join(SAIDA, "moksha-itch.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(os.path.join(ORIGEM, "index.html"), "index.html")
        z.write(os.path.join(RAIZ, IMAGENS["mar.png"]), "mar.png")
        # o heroi.png do site é 256x256 com o boneco num canto: recorta só o boneco
        heroi = Image.open(os.path.join(RAIZ, IMAGENS["heroi.png"])).convert("RGBA")
        heroi = heroi.crop(heroi.getbbox())
        tmp = os.path.join(SAIDA, "heroi.png")
        heroi.save(tmp)
        z.write(tmp, "heroi.png")
        print("heroi", heroi.size)
    print("ok", zip_path, os.path.getsize(zip_path) // 1024, "KB")

    # capa 630x500: o og.png é 1200x630 e mais largo que a capa. Pega a faixa com logo e herói,
    # encaixa na largura e completa em cima e embaixo com a cor da borda (o og já escurece nas bordas)
    og = Image.open(os.path.join(RAIZ, "site", "img", "og.png")).convert("RGB")
    faixa = og.crop((50, 0, 930, og.height))
    alto = round(faixa.height * 630 / faixa.width)
    faixa = faixa.resize((630, alto), Image.LANCZOS)
    capa = Image.new("RGB", (630, 500))
    topo = (500 - alto) // 2
    for y in range(500):
        linha = faixa.crop((0, 0, 630, 1)) if y < topo else faixa.crop((0, alto - 1, 630, alto)) if y >= topo + alto else None
        if linha is not None:
            capa.paste(linha, (0, y))
    capa.paste(faixa, (0, topo))
    capa_path = os.path.join(SAIDA, "capa.png")
    capa.save(capa_path)
    print("ok", capa_path)


if __name__ == "__main__":
    main()
