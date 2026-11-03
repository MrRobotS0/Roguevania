class_name EliteBrass
extends Boss

# Elite: Sentinela De Latão. Um mini-guardião: só age quando vê o herói.


func _init() -> void:
	title = "SENTINELA DE LATÃO"
	sheet = "elite_brass"
	max_hp = 150
	hp = 150
	w = 16
	h = 40
	weight = 2.5
	walk_speed = 30.0
	keep_distance = 120.0
	aggro_range = 220.0
	rest_every = 4
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "beam", "windup": 0.4, "damage": 18.0},
		{"type": "volley", "windup": 0.5, "style": "star", "count": 6, "radial": true, "speed": 120.0, "damage": 12.0, "bursts": 2, "rate": 0.4, "color": Palette.GLASS},
		{"type": "rain", "windup": 0.6, "style": "light", "count": 3, "width": 18.0, "height": 150.0, "predict": true, "damage": 16.0},
	]
