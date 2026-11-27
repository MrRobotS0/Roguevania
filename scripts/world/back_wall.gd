class_name BackWall
extends RefCounted

# A parede de fundo: a camada que faltava entre o fundo pintado (longe, em
# paralaxe) e os blocos onde se pisa. Fica presa ao cenário, colada no terreno:
# corredores e reentrâncias viram interior de ruína, e os vãos abertos continuam
# mostrando o céu. É nela que caem a sombra dos blocos e a luz das tochas.
#
# Cada domínio diz até quantos blocos de distância do terreno a parede chega
# (mínimo, máximo; um ruído suave escolhe entre os dois ao longo do mapa) e o
# quanto ela escurece em relação aos blocos. Domínio fechado tem parede funda;
# domínio de céu aberto, só uma casca junto da pedra.

const WALLS := {
	# alcance (blocos): [mín, máx]   tom: quanto do brilho do bloco sobra
	"mar_de_cinzas":     {"reach": [1, 2], "tone": 0.46},
	"saloes":            {"reach": [2, 3], "tone": 0.44},
	"forja_rubra":       {"reach": [3, 4], "tone": 0.62},
	"necropole":         {"reach": [1, 2], "tone": 0.46},
	"torre_babel":       {"reach": [3, 4], "tone": 0.42},
	"jardim_primordial": {"reach": [1, 2], "tone": 0.48},
	"catedral":          {"reach": [3, 4], "tone": 0.44},
	"carcosa":           {"reach": [2, 3], "tone": 0.42},
	"observatorio":      {"reach": [1, 2], "tone": 0.50},
	"ventre":            {"reach": [3, 4], "tone": 0.50},
	"penhascos":         {"reach": [0, 1], "tone": 0.50},
	"cavernas":          {"reach": [3, 5], "tone": 0.55},
	"bosque":            {"reach": [0, 1], "tone": 0.50},
}


static func reach(biome_id: String) -> Vector2i:
	var cfg: Dictionary = WALLS.get(biome_id, {})
	if cfg.is_empty():
		return Vector2i.ZERO
	return Vector2i(int(cfg["reach"][0]), int(cfg["reach"][1]))


static func tone(biome_id: String) -> float:
	return float(WALLS.get(biome_id, {}).get("tone", 0.46))
