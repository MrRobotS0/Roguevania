class_name EliteCaller
extends Boss

# Elite: Necrópole: lê em voz alta o nome dos mortos, e eles levantam.


func _init() -> void:
	title = "CHAMADOR DE NOMES"
	sheet = "elite_caller"
	max_hp = 130
	hp = 130
	w = 14
	h = 34
	weight = 2.5
	walk_speed = 80.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "volley", "windup": 0.5, "style": "glyph", "count": 3, "spread": 0.3, "speed": 220.0, "damage": 14.0, "color": Color("c86ae8")},
		{"type": "summon", "windup": 0.7, "script": "res://scripts/enemies/risen.gd", "count": 1},
		{"type": "rain", "windup": 0.6, "style": "bone", "count": 3, "height": 44.0, "predict": true, "damage": 15.0},
	]
