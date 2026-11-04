"""Inimigos e chefes com arte pronta (Gothicvania, bestiário do OpenGameArt etc.).

    python tools/importar_inimigos.py     (depois de tools/baixar_arte.py)

Cada folha do jogo (assets/sprites/<nome>.png + .json) é refeita em cor cheia
("color": true) com os MESMOS nomes de animação que o script do inimigo pede
(sprite_anim). Idle/andar/voar ganham vários quadros; preparo e golpe ficam
com o quadro-chave, porque os scripts mostram o quadro 0 nesses estados.

Fontes:
  ("strip", caminho, n)          tira com n quadros iguais
  ("grid", caminho, fw, fh)      grade; o quadro é (coluna, linha)
  ("files", padrão)              um arquivo por quadro (ordem numérica)
Opções da folha: scale (inteiro), hue (graus), sat, bright, flip (a arte olha
para a esquerda; o jogo espera direita), key (cor de fundo a apagar).

Os pés ficam no fundo da célula, no centro: o alinhamento que o artista deu
dentro de cada tira é mantido (a âncora é o centro da célula de origem e o pé
mais baixo da tira).
"""
import colorsys
import glob
import json
import os
import re

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "arte_externa")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(ROOT, "tools", "previews")
GPC = "gothicvania-patreons-collection/ gothicvania patreon collection/"
BEST = "dark-fantasy-platformer-bestiary/"
CEM = "gothicvania-cemetery-pack/gothicvania-cemetery-files/PNG/Sprites/"
CHURCH = "gothicvania-church-pack/gothicvania church files/SPRITES/"
SWAMP = "gotthicvania-swamp/Gothicvania Swamp files/Sprites/"
GROTTO = "sideview-fantasy-patreon-collection/Sideview Fantasy Patreon Collection/Sprites/"

SOURCES = {
    "emperor": ("grid", "dark-emperor/darkemperor.png", 96, 48),
    "skel": ("files", CEM + "skeleton/skeleton-[0-9]*.png"),
    "skel_c": ("files", CEM + "skeleton-clothed/skeleton-clothed-[0-9]*.png"),
    "rise": ("files", CEM + "skeleton-rise/skeleton-rise-[0-9]*.png"),
    "rise_c": ("files", CEM + "skeleton-rise-clothed/skeleton-rise-clothed-[0-9]*.png"),
    "gato": ("files", CEM + "hell-gato/hell-gato-[0-9]*.png"),
    "ghost_h": ("files", CEM + "ghost-halo/ghost-halo-[0-9]*.png"),
    "angel": ("files", CHURCH + "angel/sprites/idle/angel[0-9]*.png"),
    "angel_atk": ("files", CHURCH + "angel/sprites/angel-attack/angel-attack-[0-9]*.png"),
    "wizard": ("strip", CHURCH + "wizard/spritesheet/wizard.png", 15),
    "ghoul": ("strip", CHURCH + "burning-ghoul/spritesheet/v1/burning-ghoul.png", 8),
    "hound_idle": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-idle.png", 6),
    "hound_walk": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-walk.png", 12),
    "hound_run": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-run.png", 5),
    "hound_jump": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-jump.png", 6),
    "wolf": ("strip", GPC + "wolf-runing-cycle/Sprites/wolf-runing-cycle.png", 4),
    "fskull": ("strip", GPC + "Fire-Skull-Files/PNG/fire-skull.png", 8),
    "ghost_idle": ("strip", GPC + "Ghost-Files/PNG/ghost-idle.png", 7),
    "ghost_shriek": ("strip", GPC + "Ghost-Files/PNG/ghost-shriek.png", 4),
    "ghost_appear": ("strip", GPC + "Ghost-Files/PNG/ghost-appears.png", 6),
    "beast_idle": ("strip", GPC + "Hell-Beast-Files/PNG/with-stroke/hell-beast-idle.png", 6),
    "beast_breath": ("strip", GPC + "Hell-Beast-Files/PNG/with-stroke/hell-beast-breath.png", 4),
    "beast_burn": ("strip", GPC + "Hell-Beast-Files/PNG/with-stroke/hell-beast-burn.png", 6),
    "mare_idle": ("strip", GPC + "Nightmare-Files/PNG/nightmare-idle.png", 4),
    "mare_run": ("strip", GPC + "Nightmare-Files/PNG/nightmare-galloping.png", 4),
    "demon_idle": ("strip", GPC + "demon-Files/PNG/demon-idle.png", 6),
    "demon_atk": ("strip", GPC + "demon-Files/PNG/demon-attack-no-breath.png", 8),
    "dragon_idle": ("strip", GROTTO + "Grotto-escape-2-boss-dragon/PNG/spritesheets/idle.png", 6),
    "dragon_breath": ("strip", GROTTO + "Grotto-escape-2-boss-dragon/PNG/spritesheets/breath.png", 7),
    "dragon_tail": ("strip", GROTTO + "Grotto-escape-2-boss-dragon/PNG/spritesheets/tail.png", 8),
    "lizard_walk": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/walk.png", 6),
    "lizard_idle": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/idle.png", 4),
    "lizard_tongue": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/tongue.png", 5),
    "lizard_jump": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/jump.png", 3),
    "spider": ("files", SWAMP + "Spider/walk/spider[0-9]*.png"),
    "thing": ("files", SWAMP + "Thing/walk thing/thing[0-9]*.png"),
    "golem": ("grid", BEST + "redshrike-thompson-golem-pal2-alpha.png", 64, 72),
    "wartaur": ("grid", BEST + "redshrike-wartaur-alpha.png", 80, 80),
    "frog": ("grid", BEST + "redshrike-evert-pufalotti-frogman-pal2-alpha.png", 80, 40),
    "eyewasp": ("grid", BEST + "redshrike-emceeflesher-eyewasp-alpha.png", 36, 36),
    "snail": ("grid", BEST + "surt-emceeflesher-spitsnail-alpha_0.png", 32, 32),
    "bat": ("grid", BEST + "redshrike-blatty-alpha.png", 64, 64),
    "worm": ("grid", BEST + "calciumtrice-emceeflesher-worm-alpha.png", 32, 32),
    "shambler": ("strip", BEST + "ansimuz-shambler-pal2-alpha_0.png", 4),
    "andro": ("grid", BEST + "balmer-andromalius-57x88-alpha.png", 57, 88),
    "minion": ("grid", BEST + "balmer-minion-45x66-alpha.png", 45, 66),
    # garimpo de 04/11 (escolhidos pelo que o desenho mostra x a história do personagem)
    "pwolf_sit": ("strip", "pixel-wolf/wolf_sit.png", 4),
    "pwolf_run": ("strip", "pixel-wolf/wolf_run.png", 5),
    "pwolf_jump": ("strip", "pixel-wolf/wolf_jump.png", 4),
    "pwolf_tail": ("strip", "pixel-wolf/wolf_tail.png", 2),
    "plant_idle": ("grid", "pixel-predator-plant-mob-character/Idle/Plant3_Idle_full.png", 64, 64),
    "plant_atk": ("grid", "pixel-predator-plant-mob-character/Attack/Plant3_Attack_full.png", 64, 64),
    "statue": ("grid", "animated-statue/statue spritesheet no green.png", 64, 64),
}


def seq(src, idx):
    return [(src, i) for i in idx]


def grid_row(src, row, cols):
    return [(src, (c, row)) for c in cols]


# Os "humanoides" de 6 animações (idle, walk, windup, attack, cast, rest).
def six(idle, walk, windup, attack, cast, rest):
    return {"idle": idle, "walk": walk, "windup": windup, "attack": attack, "cast": cast, "rest": rest}


SHEETS = {
    # ---- Mar de Cinzas
    "penitent": ({"idle": seq("skel_c", [0, 1]), "walk": seq("skel_c", range(8)), "windup": seq("skel_c", [3]),
                  "attack": seq("skel_c", [6]), "stun": seq("rise_c", [2])}, {"flip": True}),
    "assassin": ({"idle": seq("skel", [0, 1]), "walk": seq("skel", range(8)), "crouch": seq("rise", [1]),
                  "windup": seq("skel", [3]), "slash": seq("skel", [6])}, {"flip": True}),
    "archer": ({"idle": seq("wizard", range(5)), "walk": seq("wizard", range(5)), "aim": seq("wizard", [8]),
                "aim_lock": seq("wizard", [11])}, {}),
    "pilgrim": ({"walk": seq("ghoul", range(8)), "ignite": seq("ghoul", [3, 6])}, {"flip": True}),
    # Lobo Pálido: "guarda a porta de um dono que não volta" — lobo cinza-claro (alizard, CC0)
    "wolf": ({"idle": seq("pwolf_tail", [0, 1]), "run": seq("pwolf_run", range(5)), "crouch": seq("pwolf_sit", [0]),
              "lunge": seq("pwolf_jump", [1]), "stun": seq("pwolf_jump", [3])}, {"key": (12, 98, 98), "flip": True}),
    "gargoyle": ({"fly": grid_row("bat", 1, range(4)), "windup": grid_row("bat", 0, [0]), "dive": grid_row("bat", 1, [2])}, {}),
    "star": ({"idle": seq("fskull", range(8)), "windup": seq("fskull", [2, 5])}, {}),
    "emperor": ({"idle": grid_row("emperor", 0, range(4)), "walk": grid_row("emperor", 4, range(6)), "windup": grid_row("emperor", 1, [1]),
                 "sweep": grid_row("emperor", 1, [3]), "cast": grid_row("emperor", 2, [0, 1]), "kneel": grid_row("emperor", 6, [2]),
                 "summon": grid_row("emperor", 3, [0])}, {"scale": 2, "key": (0, 255, 255)}),
    # ---- Salões
    "guard": ({"idle": grid_row("wartaur", 0, range(4)), "walk": grid_row("wartaur", 0, range(4)), "windup": grid_row("wartaur", 1, [0]),
               "attack": grid_row("wartaur", 1, [2]), "recover": grid_row("wartaur", 1, [3]), "stun": grid_row("wartaur", 2, [1])},
              {"flip": True, "hue": 175, "sat": 0.45}),
    "inquisitor": ({"idle": seq("gato", [0, 1]), "walk": seq("gato", range(4)), "windup": seq("gato", [0]), "slash": seq("gato", [2]),
                    "crouch": seq("gato", [3]), "leap": seq("gato", [2])}, {"flip": True, "hue": 200, "sat": 0.6}),
    "herald": (six(seq("angel", range(8)), seq("angel", range(8)), seq("angel_atk", [0]), seq("angel_atk", [2]),
                   seq("angel_atk", [0, 1]), seq("angel", [0])), {}),
    "wolf_king": (six(seq("hound_idle", range(6)), seq("hound_walk", range(12)), seq("hound_jump", [0]), seq("hound_jump", [2]),
                      seq("hound_idle", [0, 3]), seq("hound_jump", [5])), {"flip": True, "scale": 2, "hue": 195, "sat": 0.55, "bright": 1.15}),
    # ---- Forja
    "automaton": (six(grid_row("golem", 0, [0, 2]), grid_row("golem", 1, range(6)), grid_row("golem", 2, [1]),
                      grid_row("golem", 2, [3]), grid_row("golem", 2, [1, 2]), grid_row("golem", 2, [5])), {"hue": 20, "sat": 0.6}),
    "smith": ({"idle": grid_row("andro", 0, range(8)), "walk": grid_row("andro", 1, range(8)), "windup": grid_row("andro", 2, [1]),
               "slam": grid_row("andro", 2, [4]), "stun": grid_row("andro", 2, [7])}, {"flip": True}),
    "slag": ({"idle": grid_row("worm", 1, [0, 1, 2]), "hop": grid_row("worm", 2, [3]), "land": grid_row("worm", 1, [4])}, {"hue": -40, "sat": 1.3}),
    "mason": (six(grid_row("minion", 0, [0, 1]), grid_row("minion", 0, range(4)), grid_row("minion", 0, [1]),
                  grid_row("minion", 1, [0]), grid_row("minion", 0, [2, 3]), grid_row("minion", 0, [0])), {"flip": True}),
    # Colosso da Bigorna: "o ferreiro que o deus esqueceu ligado" — estátua com martelo (Calciumtrice, CC-BY),
    # em 2x e puxada para bronze; o golpe bate o martelo e solta a onda no chão
    "colossus": (six(grid_row("statue", 0, range(4)), grid_row("statue", 1, range(8)), grid_row("statue", 2, [1]),
                     grid_row("statue", 2, [3]), grid_row("statue", 2, [0, 1]), grid_row("statue", 3, [2])),
                 {"scale": 2, "sat": 2.2, "bright": 0.8}),
    # ---- Jardim
    "moss_beast": ({"idle": grid_row("frog", 0, range(6)), "walk": grid_row("frog", 0, range(6)), "windup": grid_row("frog", 1, [0]),
                    "charge": grid_row("frog", 1, [1]), "rest": grid_row("frog", 2, [0])}, {"flip": True}),
    "seed_pod": ({"idle": grid_row("snail", 0, range(4)), "walk": grid_row("snail", 1, range(10)), "windup": grid_row("snail", 1, [4, 5]),
                  "attack": grid_row("snail", 1, [7])}, {"flip": True}),
    # Espinheiro: "abre a flor antes de atirar" — flor carnívora (CraftPix, OGA-BY), linha de perfil
    "thorn": ({"idle": grid_row("plant_idle", 3, range(4)), "windup": grid_row("plant_atk", 3, [2]),
               "attack": grid_row("plant_atk", 3, [5])}, {}),
    "mother_root": (six(seq("dragon_idle", range(6)), seq("dragon_idle", range(6)), seq("dragon_breath", [1]), seq("dragon_breath", [4]),
                        seq("dragon_tail", range(8)), seq("dragon_idle", [0])), {"flip": True, "scale": 2}),
    # ---- Torre de Babel
    "scribe": (six(seq("wizard", range(5)), seq("wizard", range(5)), seq("wizard", [8]), seq("wizard", [11]),
                   seq("wizard", [9, 10]), seq("wizard", [0])), {"hue": 230, "sat": 0.8}),
    "architect": (six(seq("demon_idle", range(6)), seq("demon_idle", range(6)), seq("demon_atk", [2]), seq("demon_atk", [5]),
                      seq("demon_atk", [0, 1]), seq("demon_idle", [0])), {"hue": 25, "sat": 0.7}),
    # ---- Carcosa
    "dancer": (six(seq("ghost_h", range(4)), seq("ghost_h", range(4)), seq("ghost_h", [1]), seq("ghost_h", [3]),
                   seq("ghost_h", [0, 2]), seq("ghost_h", [0])), {"hue": 40}),
    "masked": (six(seq("shambler", [0, 1]), seq("shambler", range(4)), seq("shambler", [1]), seq("shambler", [3]),
                   seq("shambler", [0, 2]), seq("shambler", [0])), {"hue": 30}),
    "faceless_king": (six(seq("mare_idle", range(4)), seq("mare_run", range(4)), seq("mare_idle", [1]), seq("mare_run", [2]),
                          seq("mare_idle", [2, 3]), seq("mare_idle", [0])), {"flip": True, "hue": 45, "sat": 0.9}),
    # ---- Observatório
    "lens": ({"idle": grid_row("eyewasp", 0, range(4)), "windup": grid_row("eyewasp", 1, [0, 2]), "attack": grid_row("eyewasp", 0, [1])},
             {"flip": True, "hue": 160}),
    "astronomer": (six(seq("ghost_idle", range(7)), seq("ghost_idle", range(7)), seq("ghost_shriek", [1]), seq("ghost_shriek", [3]),
                       seq("ghost_appear", range(6)), seq("ghost_idle", [0])), {"scale": 2, "hue": 200, "sat": 1.2}),
    # ---- elites (variações recoloridas)
    "elite_brass": (six(grid_row("golem", 0, [0, 2]), grid_row("golem", 1, range(6)), grid_row("golem", 2, [1]),
                        grid_row("golem", 2, [3]), grid_row("golem", 2, [1, 2]), grid_row("golem", 2, [5])), {"hue": 60, "sat": 1.4, "bright": 1.1}),
    "elite_duelist": (six(grid_row("wartaur", 0, range(4)), grid_row("wartaur", 0, range(4)), grid_row("wartaur", 1, [0]),
                          grid_row("wartaur", 1, [2]), grid_row("wartaur", 1, [1, 3]), grid_row("wartaur", 2, [1])), {"flip": True, "hue": -30}),
    "elite_forgemaster": (six(grid_row("andro", 0, range(8)), grid_row("andro", 1, range(8)), grid_row("andro", 2, [1]),
                              grid_row("andro", 2, [4]), grid_row("andro", 2, [2, 3]), grid_row("andro", 2, [7])), {"flip": True, "hue": -25, "sat": 1.3}),
    "elite_hunter": (six(seq("lizard_idle", range(4)), seq("lizard_walk", range(6)), seq("lizard_jump", [0]), seq("lizard_tongue", [3]),
                         seq("lizard_tongue", [1, 2]), seq("lizard_idle", [0])), {"scale": 2}),
    "elite_librarian": (six(seq("wizard", range(5)), seq("wizard", range(5)), seq("wizard", [8]), seq("wizard", [11]),
                            seq("wizard", [9, 10]), seq("wizard", [0])), {"hue": 120}),
    "elite_thornkeeper": (six(seq("spider", range(4)), seq("spider", range(4)), seq("spider", [1]), seq("spider", [3]),
                              seq("spider", [0, 2]), seq("spider", [0])), {"hue": 90, "scale": 2}),
}

# ---------------------------------------------------------------------------
# Garimpo de 04/11 (itch.io, baixados pelo Chrome dele; ver docs/ACERVO_ARTE.md).
# Cada troca foi escolhida pelo que o desenho mostra x a frase do personagem.
IT = "itch/"
LM = {  # Luiz Melo, CC0 — uma tira por animação
    "king_idle": ("fw", IT + "medieval_king_pack_2/**/Idle.png", 160), "king_run": ("fw", IT + "medieval_king_pack_2/**/Run.png", 160),
    "king_a1": ("fw", IT + "medieval_king_pack_2/**/Attack1.png", 160), "king_a3": ("fw", IT + "medieval_king_pack_2/**/Attack3.png", 160),
    "king_hit": ("fw", IT + "medieval_king_pack_2/**/Take Hit.png", 160),
    "ew2_idle": ("sq", IT + "evil_wizard_2/**/Idle.png"), "ew2_run": ("sq", IT + "evil_wizard_2/**/Run.png"),
    "ew2_a1": ("sq", IT + "evil_wizard_2/**/Attack1.png"), "ew2_a2": ("sq", IT + "evil_wizard_2/**/Attack2.png"),
    "ew2_hit": ("sq", IT + "evil_wizard_2/**/Take hit.png"),
    "ew3_idle": ("sq", IT + "evil_wizard_3/**/Idle.png"), "ew3_walk": ("sq", IT + "evil_wizard_3/**/Walk.png"),
    "ew3_atk": ("sq", IT + "evil_wizard_3/**/Attack.png"), "ew3_hit": ("sq", IT + "evil_wizard_3/**/Get hit.png"),
    "wiz_idle": ("fw", IT + "wizard_pack/**/Idle.png", 231), "wiz_run": ("fw", IT + "wizard_pack/**/Run.png", 231),
    "wiz_a1": ("fw", IT + "wizard_pack/**/Attack1.png", 231), "wiz_a2": ("fw", IT + "wizard_pack/**/Attack2.png", 231),
    "wiz_hit": ("fw", IT + "wizard_pack/**/Hit.png", 231),
    "ew_idle": ("sq", IT + "evil_wizard/**/Idle.png"), "ew_move": ("sq", IT + "evil_wizard/**/Move.png"),
    "ew_atk": ("sq", IT + "evil_wizard/**/Attack.png"),
    "hk_idle": ("sq", IT + "hero_knight/**/Idle.png"), "hk_run": ("sq", IT + "hero_knight/**/Run.png"),
    "hk_a1": ("sq", IT + "hero_knight/**/Attack1.png"), "hk_a2": ("sq", IT + "hero_knight/**/Attack2.png"),
    "hk_jump": ("sq", IT + "hero_knight/**/Jump.png"),
    "hu_idle": ("sq", IT + "huntress/**/Idle.png"), "hu_run": ("sq", IT + "huntress/**/Run.png"),
    "hu_a1": ("sq", IT + "huntress/**/Attack1.png"), "hu_a3": ("sq", IT + "huntress/**/Attack3.png"),
    "hu_hit": ("sq", IT + "huntress/**/Take hit.png"),
    "mh2_idle": ("sq", IT + "martial_hero_2/**/Idle.png"), "mh2_run": ("sq", IT + "martial_hero_2/**/Run.png"),
    "mh2_a1": ("sq", IT + "martial_hero_2/**/Attack1.png"), "mh2_a2": ("sq", IT + "martial_hero_2/**/Attack2.png"),
    "mh2_hit": ("sq", IT + "martial_hero_2/**/Take hit.png"),
    "mh_idle": ("sq", IT + "martial_hero/**/Idle.png"), "mh_run": ("sq", IT + "martial_hero/**/Run.png"),
    "mh_a1": ("sq", IT + "martial_hero/**/Attack1.png"), "mh_a2": ("sq", IT + "martial_hero/**/Attack2.png"),
    "mh_hit": ("sq", IT + "martial_hero/**/Take Hit.png"),
    "fw_idle": ("sq", IT + "fire_worm/**/Idle.png"), "fw_atk": ("sq", IT + "fire_worm/**/Attack.png"),
    "fw_hit": ("sq", IT + "fire_worm/**/Get Hit.png"),
    "mush_idle": ("sq", IT + "monsters_creatures_fantasy/**/Mushroom/Idle.png"),
    "mush_run": ("sq", IT + "monsters_creatures_fantasy/**/Mushroom/Run.png"),
    "mush_atk": ("sq", IT + "monsters_creatures_fantasy/**/Mushroom/Attack.png"),
    "eye_fly": ("sq", IT + "monsters_creatures_fantasy/**/Flying eye/Flight.png"),
    "eye_atk": ("sq", IT + "monsters_creatures_fantasy/**/Flying eye/Attack.png"),
    "sk_idle": ("sq", IT + "monsters_creatures_fantasy/**/Skeleton/Idle.png"), "sk_walk": ("sq", IT + "monsters_creatures_fantasy/**/Skeleton/Walk.png"),
    "sk_atk": ("sq", IT + "monsters_creatures_fantasy/**/Skeleton/Attack.png"), "sk_shield": ("sq", IT + "monsters_creatures_fantasy/**/Skeleton/Shield.png"),
    "sk_hit": ("sq", IT + "monsters_creatures_fantasy/**/Skeleton/Take Hit.png"),
    "mw3_idle": ("sq", IT + "medieval_warrior_pack_3/**/Idle.png"), "mw3_run": ("sq", IT + "medieval_warrior_pack_3/**/Run.png"),
    "mw3_a1": ("sq", IT + "medieval_warrior_pack_3/**/Attack1.png"), "mw3_hit": ("sq", IT + "medieval_warrior_pack_3/**/Get Hit.png"),
    "fwr_idle": ("sq", IT + "fantasy_warrior/**/Idle.png"), "fwr_run": ("sq", IT + "fantasy_warrior/**/Run.png"),
    "fwr_a1": ("sq", IT + "fantasy_warrior/**/Attack1.png"), "fwr_hit": ("sq", IT + "fantasy_warrior/**/Take hit.png"),
}
CH = IT + "elementals_"
EL = {  # chierit, CC-BY 4.0 — um arquivo por quadro
    "cm_idle": ("files", CH + "crystal_mauler*/**/PNG/idle/*.png"), "cm_run": ("files", CH + "crystal_mauler*/**/PNG/run/*.png"),
    "cm_a1": ("files", CH + "crystal_mauler*/**/PNG/1_atk/*.png"), "cm_hit": ("files", CH + "crystal_mauler*/**/PNG/take_hit/*.png"),
    "gm_idle": ("files", CH + "ground_monk*/**/png/idle/*.png"), "gm_run": ("files", CH + "ground_monk*/**/png/run/*.png"),
    "gm_a2": ("files", CH + "ground_monk*/**/png/2_atk/*.png"), "gm_sp": ("files", CH + "ground_monk*/**/png/sp_atk/*.png"),
    "gm_hit": ("files", CH + "ground_monk*/**/png/take_hit/*.png"),
    "fk_idle": ("files", CH + "fire_knight*/**/01_idle/*.png"), "fk_run": ("files", CH + "fire_knight*/**/02_run/*.png"),
    "fk_a1": ("files", CH + "fire_knight*/**/05_1_atk/*.png"), "fk_sp": ("files", CH + "fire_knight*/**/08_sp_atk/*.png"),
    "fk_hit": ("files", CH + "fire_knight*/**/10_take_hit/*.png"),
    "wh_idle": ("files", CH + "wind_hashashin*/**/PNG/idle/*.png"), "wh_run": ("files", CH + "wind_hashashin*/**/PNG/run/*.png"),
    "wh_a2": ("files", CH + "wind_hashashin*/**/PNG/2_atk/*.png"), "wh_a3": ("files", CH + "wind_hashashin*/**/PNG/3_atk/*.png"),
    "wh_hit": ("files", CH + "wind_hashashin*/**/PNG/take_hit/*.png"),
    "lr_idle": ("files", CH + "leaf_ranger*/**/PNG/idle/*.png"), "lr_run": ("files", CH + "leaf_ranger*/**/PNG/run/*.png"),
    "lr_a1": ("files", CH + "leaf_ranger*/**/PNG/1_atk/*.png"), "lr_sp": ("files", CH + "leaf_ranger*/**/PNG/sp_atk/*.png"),
    "lr_hit": ("files", CH + "leaf_ranger*/**/PNG/take_hit/*.png"),
}
FG = IT + "frost_guardian_free_v1.0/**/PNG files/"
EL.update({  # chierit, CC-BY 4.0 — Frost Guardian vira a Fera-Musgo
    "fg_idle": ("files", FG + "idle/*.png"), "fg_walk": ("files", FG + "walk/*.png"),
    "fg_atk": ("files", FG + "1_atk/*.png"), "fg_hit": ("files", FG + "take_hit/*.png"),
})
RG = IT + "fantasy_creatures_bundle/**/Rune_Golem/crystal/"
PC = {  # PulsarCP, CC0
    "rg_idle": ("fw", RG + "idle_sheet.png", 208), "rg_walk": ("fw", RG + "walk_sheet.png", 208),
    "rg_slam": ("fw", RG + "slam_sheet.png", 208), "rg_beam": ("fw", RG + "beam_sheet.png", 208),
    "rg_hurt": ("fw", RG + "hurt_sheet.png", 208),
}
SOURCES.update(LM)
SOURCES.update(EL)
SOURCES.update(PC)
BLUE_TO_YELLOW = [(0.5, 0.75, -165, 1.0)]
SHEETS.update({
    # Rei sem Rosto: "a máscara caiu; não havia nada embaixo" — rei de coroa (Luiz Melo), rosto vazio;
    # a capa azul vira amarela: o Rei de Amarelo de Carcosa
    "faceless_king": (six(seq("king_idle", range(8)), seq("king_run", range(8)), seq("king_a1", [1]), seq("king_a1", [2]),
                          seq("king_a3", [0, 1]), seq("king_hit", [1])), {"draw_scale": 2, "void_face": True, "remap": [(0.5, 0.78, 48, 1.1, "=")]}),
    # Arquiteto Mudo: "ergueu a torre e esqueceu a própria língua" — golem coberto de runas (PulsarCP);
    # os cristais rosados viram glifos dourados da Torre
    "architect": (six(seq("rg_idle", range(8)), seq("rg_walk", range(8)), seq("rg_slam", [2]), seq("rg_slam", [5]),
                      seq("rg_beam", [2, 4]), seq("rg_hurt", [1])), {"remap": [(0.42, 0.6, 44, 1.0, "=")]}),
    # Último Astrônomo: "contou as estrelas até elas acabarem" — mago de capuz com o orbe escuro
    "astronomer": (six(seq("ew2_idle", range(8)), seq("ew2_run", range(8)), seq("ew2_a1", [2]), seq("ew2_a1", [5]),
                       seq("ew2_a2", [2, 4]), seq("ew2_hit", [1])), {"draw_scale": 2}),
    # Bibliotecário Cego: mago pálido com cajado de caveira
    "elite_librarian": (six(seq("ew3_idle", range(10)), seq("ew3_walk", range(8)), seq("ew3_atk", [3]), seq("ew3_atk", [7]),
                            seq("ew3_atk", [4, 5]), seq("ew3_hit", [1])), {}),
    # Escriba Mudo: mago de túnica
    "scribe": (six(seq("wiz_idle", range(6)), seq("wiz_run", range(8)), seq("wiz_a1", [2]), seq("wiz_a1", [5]),
                   seq("wiz_a2", [2, 4]), seq("wiz_hit", [1])), {}),
    # Atirador de Vidro: mago que arremessa; o fogo vira lasca de vidro
    "archer": ({"idle": seq("ew_idle", range(8)), "walk": seq("ew_move", range(8)), "aim": seq("ew_atk", [3]),
                "aim_lock": seq("ew_atk", [5])}, {"remap": [(0.95, 0.15, 175, 0.9)]}),
    # Inquisidor Profeta: "salta e cai onde você está" — cavaleiro que salta
    "inquisitor": ({"idle": seq("hk_idle", range(11)), "walk": seq("hk_run", range(8)), "windup": seq("hk_a1", [1]),
                    "slash": seq("hk_a1", [3]), "crouch": seq("hk_a2", [0]), "leap": seq("hk_jump", [1])}, {}),
    # Caçador do Inverno: lanças de gelo — caçadora de lança, puxada para o gelo
    "elite_hunter": (six(seq("hu_idle", range(8)), seq("hu_run", range(8)), seq("hu_a1", [1]), seq("hu_a1", [3]),
                         seq("hu_a3", [2, 4]), seq("hu_hit", [1])), {"remap": [(0.12, 0.45, 200, 0.7, "=")], "bright": 1.15}),
    # Mascarado: "em Carcosa todos usam máscara" — samurai de máscara vermelha, túnica amarela
    "masked": (six(seq("mh2_idle", range(4)), seq("mh2_run", range(8)), seq("mh2_a1", [1]), seq("mh2_a1", [2]),
                   seq("mh2_a2", [1, 2]), seq("mh2_hit", [1])), {"remap": [(0.5, 0.85, 48, 1.1, "=")]}),
    # Duelista Amarelo: "rápido, some, aparece, corta" — espadachim de chapéu, em amarelo
    "elite_duelist": (six(seq("mh_idle", range(8)), seq("mh_run", range(8)), seq("mh_a1", [1]), seq("mh_a1", [3]),
                          seq("mh_a2", [2, 3]), seq("mh_hit", [1])), {"remap": [(0.88, 0.04, 46, 1.1, "="), (0.55, 0.88, 50, 0.9, "=")]}),
    # Escória Viva: "o metal que não quis virar arma; pula, queima e vira poça" — verme de fogo
    "slag": ({"idle": seq("fw_idle", range(9)), "hop": seq("fw_atk", [6]), "land": seq("fw_hit", [1])}, {}),
    # Broto Espinhento: "finca as raízes e incha" — cogumelo
    "seed_pod": ({"idle": seq("mush_idle", range(4)), "walk": seq("mush_run", range(8)), "windup": seq("mush_atk", [3, 4]),
                  "attack": seq("mush_atk", [6])}, {}),
    # Lente Viva: "um olho que mira de qualquer ângulo" — olho voador
    "lens": ({"idle": seq("eye_fly", range(8)), "windup": seq("eye_atk", [2, 4]), "attack": seq("eye_atk", [6])}, {}),
    # Guarda da Casa: "o escudo protege a frente; as costas, ninguém" — esqueleto de escudo (Luiz Melo),
    # soldado do império morto do Mar de Cinzas; recupera atrás do escudo
    "guard": ({"idle": seq("sk_idle", range(4)), "walk": seq("sk_walk", range(4)), "windup": seq("sk_atk", [3]),
               "attack": seq("sk_atk", [6]), "recover": seq("sk_shield", [1]), "stun": seq("sk_hit", [1])}, {}),
    # Penitente: "peregrinos que juraram carregar a culpa do mundo" — peregrino de capuz, em cinza
    "penitent": ({"idle": seq("fwr_idle", range(10)), "walk": seq("fwr_run", range(8)), "windup": seq("fwr_a1", [2]),
                  "attack": seq("fwr_a1", [4]), "stun": seq("fwr_hit", [1])}, {"sat": 0.45}),
    # Ferreiro Cativo: anão de marreta; o cristal vira brasa
    "smith": ({"idle": seq("cm_idle", range(8)), "walk": seq("cm_run", range(8)), "windup": seq("cm_a1", [2]),
               "slam": seq("cm_a1", [4]), "stun": seq("cm_hit", [2])}, {"remap": [(0.42, 0.72, 28, 0.35, "=")]}),
    # Pedreiro da Torre: monge da terra (arremessa pedra, bate de perto)
    "mason": (six(seq("gm_idle", range(6)), seq("gm_run", range(8)), seq("gm_a2", [3]), seq("gm_a2", [6]),
                  seq("gm_sp", [5, 10]), seq("gm_hit", [2])), {}),
    # Mestre-Ferreiro: "a martelada solta ondas pelo chão" — cavaleiro de fogo com espadão
    "elite_forgemaster": (six(seq("fk_idle", range(8)), seq("fk_run", range(8)), seq("fk_a1", [3]), seq("fk_a1", [6]),
                              seq("fk_sp", [6, 10]), seq("fk_hit", [2])), {}),
    # Dançarino Amarelo: "gira e atravessa a sala num rodopio" — assassino do vento
    "dancer": (six(seq("wh_idle", range(8)), seq("wh_run", range(8)), seq("wh_a2", [3]), seq("wh_a2", [8]),
                   seq("wh_a3", [10, 14]), seq("wh_hit", [2])), {"remap": [(0.4, 0.6, -140, 1.1)]}),
    # Fera-Musgo: "não come, só cresce por cima do que encontra; investe em linha reta" — brutamontes (chierit);
    # o gelo das costas vira musgo crescendo e o corpo vira casca escura
    "moss_beast": ({"idle": seq("fg_idle", range(6)), "walk": seq("fg_walk", range(10)), "windup": seq("fg_atk", [3]),
                    "charge": seq("fg_atk", [7]), "rest": seq("fg_hit", [2])},
                   {"remap": [(0.42, 0.72, 78, 0.5, "="), (0.0, 0.12, 28, 0.55, "=")], "bright": 0.62}),
    # Gárgula: "guardas que viraram pedra esperando a ordem de parar" — o morcego em pedra cinza
    "gargoyle": ({"fly": grid_row("bat", 1, range(4)), "windup": grid_row("bat", 0, [0]), "dive": grid_row("bat", 1, [2])},
                 {"sat": 0.15, "bright": 1.15}),
    # Guardiã de Espinhos: "faz o chão crescer contra você" — patrulheira de folhas
    "elite_thornkeeper": (six(seq("lr_idle", range(12)), seq("lr_run", range(10)), seq("lr_a1", [3]), seq("lr_a1", [6]),
                              seq("lr_sp", [6, 10]), seq("lr_hit", [2])), {}),
})

FPS = {"idle": 6, "walk": 10, "run": 12, "fly": 10, "cast": 6}


# ------------------------------------------------------------------ leitura

def find(pattern):
    hits = [f for f in glob.glob(os.path.join(ART, pattern), recursive=True) if "__MACOSX" not in f and not os.path.basename(f).startswith("._")]
    if not hits:
        raise SystemExit("não achei: " + pattern)
    return hits


def num(path):
    m = re.findall(r"(\d+)", os.path.basename(path))
    return int(m[-1]) if m else 0


_cache = {}


def frames(name):
    """{índice: (Image do quadro, âncora x, âncora y)} de uma fonte."""
    if name in _cache:
        return _cache[name]
    spec = SOURCES[name]
    out = {}
    if spec[0] in ("strip", "sq", "fw"):
        im = Image.open(find(spec[1])[0]).convert("RGBA")
        if spec[0] == "strip":
            fw = im.width // spec[2]
        elif spec[0] == "sq":          # quadros quadrados (a altura da tira)
            fw = im.height
        else:                          # largura do quadro informada
            fw = spec[2]
        n = im.width // fw
        cells = {i: im.crop((i * fw, 0, (i + 1) * fw, im.height)) for i in range(n)}
    elif spec[0] == "grid":
        im = Image.open(find(spec[1])[0]).convert("RGBA")
        fw, fh = spec[2], spec[3]
        cells = {(c, r): im.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh))
                 for r in range(im.height // fh) for c in range(im.width // fw)}
    else:
        files = sorted(set(find(spec[1])), key=num)
        imgs = [Image.open(f).convert("RGBA") for f in files]
        w = max(i.width for i in imgs)
        h = max(i.height for i in imgs)
        cells = {}
        for k, i in enumerate(imgs):
            c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            c.paste(i, ((w - i.width) // 2, h - i.height))
            cells[k] = c
    for k, c in cells.items():
        out[k] = c
    _cache[name] = out
    return out


def clean(im, key):
    if key is None:
        return im
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and abs(r - key[0]) < 40 and abs(g - key[1]) < 40 and abs(b - key[2]) < 40:
                px[x, y] = (0, 0, 0, 0)
    return im


def recolor(im, hue, sat, bright):
    if hue == 0 and sat == 1.0 and bright == 1.0:
        return im
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h + hue / 360.0) % 1.0
            r2, g2, b2 = colorsys.hsv_to_rgb(h, min(1.0, s * sat), min(1.0, v * bright))
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return im


def remap(im, rules):
    """Recolore só os pixels numa faixa de matiz: [(h0, h1, graus, sat), ...] (h em 0-1)."""
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s < 0.12:
                continue
            for rule in rules:
                h0, h1, deg, sat = rule[:4]
                inside = h0 <= h <= h1 if h0 <= h1 else (h >= h0 or h <= h1)
                if inside:
                    # 5º item "=": deg é a matiz de destino (0-360), não um deslocamento
                    nh = (deg / 360.0) if len(rule) > 4 and rule[4] == "=" else (h + deg / 360.0) % 1.0
                    r2, g2, b2 = colorsys.hsv_to_rgb(nh % 1.0, min(1.0, s * sat), v)
                    px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
                    break
    return im


def void_face(im):
    """Rei sem Rosto: a pele no alto do corpo vira vazio (quase preto, sem traço)."""
    box = im.getbbox()
    if not box:
        return im
    im = im.copy()
    px = im.load()
    top = box[1] + (box[3] - box[1]) * 0.42
    for y in range(box[1], int(top)):
        for x in range(box[0], box[2]):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if 0.0 <= h <= 0.13 and 0.15 <= s <= 0.75 and v >= 0.42:
                px[x, y] = (10, 8, 16, a)
    return im


def build(name, anims, opt):
    scale = opt.get("scale", 1)
    key = opt.get("key")
    # pé de cada fonte: o mais baixo entre os quadros usados dela
    used = {}
    for seq_ in anims.values():
        for src, i in seq_:
            used.setdefault(src, set()).add(i)
    foot = {}
    for src, idx in used.items():
        fr = frames(src)
        foot[src] = max((clean(fr[i], key).getbbox() or (0, 0, 0, fr[i].height))[3] for i in idx)
    # caixa total em volta da âncora (centro da célula, pé)
    left = right = up = 0
    for src, idx in used.items():
        for i in idx:
            im = clean(frames(src)[i], key)
            box = im.getbbox()
            if not box:
                continue
            ax = im.width / 2
            left = max(left, ax - box[0])
            right = max(right, box[2] - ax)
            up = max(up, foot[src] - box[1])
    half = int(max(left, right) + 1)
    cw, ch = (half * 2) * scale, (int(up) + 2) * scale
    cols = max(len(s) for s in anims.values())
    sheet = Image.new("RGBA", (cols * cw, len(anims) * ch), (0, 0, 0, 0))
    meta = {"w": cw, "h": ch, "size": max(cw, ch), "color": True, "anims": {}}
    if opt.get("draw_scale"):
        meta["draw_scale"] = opt["draw_scale"]   # o jogo amplia na hora de desenhar (textura menor)
    for r, (anim, seq_) in enumerate(anims.items()):
        for c, (src, i) in enumerate(seq_):
            im = clean(frames(src)[i], key)
            if opt.get("flip"):
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            if opt.get("void_face"):
                im = void_face(im)
            if opt.get("remap"):
                im = remap(im, opt["remap"])
            im = recolor(im, opt.get("hue", 0), opt.get("sat", 1.0), opt.get("bright", 1.0))
            ox = half - im.width / 2
            oy = int(up) - foot[src]
            cell = Image.new("RGBA", (half * 2, int(up) + 2), (0, 0, 0, 0))
            cell.alpha_composite(im, (int(round(ox)), oy))
            if scale != 1:
                cell = cell.resize((cell.width * scale, cell.height * scale), Image.NEAREST)
            sheet.alpha_composite(cell, (c * cw, r * ch))
        meta["anims"][anim] = {"row": r, "frames": len(seq_), "fps": FPS.get(anim, 8)}
    sheet.save(os.path.join(OUT, name + ".png"))
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    return sheet, meta


def main():
    os.makedirs(PREV, exist_ok=True)
    only = os.environ.get("SO")
    shots = []
    for name, (anims, opt) in SHEETS.items():
        if only and name not in only.split(","):
            continue
        sheet, meta = build(name, anims, opt)
        # prévia: a primeira linha (idle/andar) de cada folha
        first = sheet.crop((0, 0, sheet.width, meta["h"]))
        shots.append((name, first))
        print("ok %-18s %dx%d  %s" % (name, meta["w"], meta["h"], " ".join("%s:%d" % (k, v["frames"]) for k, v in meta["anims"].items())))
    W = 1800
    x = y = rowh = 0
    pos = []
    for name, im in shots:
        if x + im.width > W:
            x, y, rowh = 0, y + rowh + 14, 0
        pos.append((x, y))
        x += im.width + 8
        rowh = max(rowh, im.height)
    prev = Image.new("RGBA", (W, y + rowh + 14), (44, 40, 54, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(prev)
    for (name, im), (px, py) in zip(shots, pos):
        prev.alpha_composite(im, (px, py))
        d.text((px, py + im.height), name, fill=(255, 230, 140, 255))
        d.line([(px, py + im.height - 2), (px + im.width, py + im.height - 2)], fill=(90, 200, 90, 255))
    prev.save(os.path.join(PREV, "inimigos.png"))


if __name__ == "__main__":
    main()
