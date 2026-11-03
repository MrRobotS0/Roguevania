class_name EliteThornkeeper
extends Boss

# Elite: Guardiã De Espinhos. Um mini-guardião: só age quando vê o herói.


func _init() -> void:
	title = "GUARDIÃ DE ESPINHOS"
	sheet = "elite_thornkeeper"
	max_hp = 140
	hp = 140
	w = 14
	h = 36
	weight = 2.5
	walk_speed = 60.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "rain", "windup": 0.6, "style": "vine", "count": 3, "width": 18.0, "height": 46.0, "predict": true, "damage": 16.0},
		{"type": "volley", "windup": 0.5, "style": "thorn", "count": 10, "radial": true, "speed": 140.0, "damage": 11.0},
		{"type": "melee", "windup": 0.45, "reach": 48.0, "height": 30.0, "damage": 18.0, "max_range": 70.0},
	]
