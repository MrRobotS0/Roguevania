class_name EliteReverie
extends Boss

# Elite: Penhascos do Sonho: ela sonha que luta. Você está no sonho dela.


func _init() -> void:
	title = "LÂMINA DO DEVANEIO"
	sheet = "elite_reverie"
	max_hp = 130
	hp = 130
	w = 12
	h = 32
	weight = 2.5
	walk_speed = 80.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "teleport", "reach": 44.0, "damage": 17.0},
		{"type": "volley", "windup": 0.4, "style": "shard", "count": 3, "spread": 0.2, "speed": 320.0, "damage": 14.0},
		{"type": "charge", "windup": 0.35, "speed": 440.0, "time": 0.4, "damage": 16.0},
	]
