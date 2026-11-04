class_name ElitePriestess
extends Boss

# Elite: Catedral Submersa: ainda reza a missa. A água obedece.


func _init() -> void:
	title = "SACERDOTISA AFOGADA"
	sheet = "elite_priestess"
	max_hp = 140
	hp = 140
	w = 12
	h = 34
	weight = 2.5
	walk_speed = 80.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "wave", "windup": 0.5, "speed": 200.0, "damage": 15.0},
		{"type": "rain", "windup": 0.6, "style": "water", "count": 3, "height": 64.0, "predict": true, "damage": 15.0},
		{"type": "melee", "windup": 0.35, "reach": 46.0, "height": 30.0, "damage": 16.0, "max_range": 70.0},
	]
