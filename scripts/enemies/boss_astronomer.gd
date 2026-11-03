class_name Astronomer
extends Boss

# O Último Astrônomo: contou as estrelas até elas acabarem.


func _init() -> void:
	title = "O ÚLTIMO ASTRÔNOMO"
	subtitle = "CONTOU AS ESTRELAS ATÉ ELAS ACABAREM"
	defeat_text = "O CÉU FICOU SEM NINGUÉM PARA OLHAR"
	sheet = "astronomer"
	max_hp = 1800
	hp = 1800
	w = 22
	h = 54
	weight = 5.0
	walk_speed = 35.0
	keep_distance = 150.0
	essence_drop = Vector2i(70, 70)

	moves = [
		{"type": "volley", "windup": 0.6, "style": "star", "count": 12, "radial": true, "speed": 130.0, "damage": 13.0, "bursts": 2, "rate": 0.4, "color": Palette.GLASS},
		{"type": "beam", "windup": 0.4, "damage": 24.0},
		{"type": "rain", "windup": 0.7, "style": "light", "count": 5, "width": 20.0, "height": 170.0, "predict": true, "damage": 20.0},
	]
	moves2 = [
		{"type": "volley", "windup": 0.5, "style": "star", "count": 4, "spread": 0.2, "speed": 160.0, "homing": 2.0, "damage": 14.0, "color": Palette.GLASS},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/fallen_star.gd", "count": 3},
		{"type": "teleport", "reach": 46.0, "damage": 22.0},
	]
