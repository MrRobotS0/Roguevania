class_name EliteHunter
extends Boss

# Elite: Caçador Do Inverno. Um mini-guardião: só age quando vê o herói.


func _init() -> void:
	title = "CAÇADOR DO INVERNO"
	sheet = "elite_hunter"
	max_hp = 130
	hp = 130
	w = 14
	h = 34
	weight = 2.5
	walk_speed = 90.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {"volley": "turret_shot", "charge": "wolf_bite"}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "volley", "windup": 0.55, "style": "shard", "count": 3, "spread": 0.12, "speed": 300.0, "damage": 14.0},
		{"type": "charge", "windup": 0.5, "speed": 340.0, "time": 0.6, "damage": 18.0},
		{"type": "melee", "windup": 0.45, "reach": 44.0, "height": 28.0, "damage": 18.0, "max_range": 70.0},
	]
