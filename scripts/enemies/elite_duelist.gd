class_name EliteDuelist
extends Boss

# Elite: Duelista Amarelo. Um mini-guardião: só age quando vê o herói.


func _init() -> void:
	title = "DUELISTA AMARELO"
	sheet = "elite_duelist"
	max_hp = 120
	hp = 120
	w = 12
	h = 34
	weight = 2.5
	walk_speed = 90.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "teleport", "reach": 44.0, "damage": 18.0},
		{"type": "melee", "windup": 0.3, "reach": 46.0, "height": 28.0, "damage": 16.0, "max_range": 70.0},
		{"type": "charge", "windup": 0.35, "speed": 420.0, "time": 0.45, "damage": 16.0},
	]
