class_name EliteForgemaster
extends Boss

# Elite: Mestre-Ferreiro. Um mini-guardião: só age quando vê o herói.


func _init() -> void:
	title = "MESTRE-FERREIRO"
	sheet = "elite_forgemaster"
	max_hp = 160
	hp = 160
	w = 18
	h = 40
	weight = 2.5
	walk_speed = 40.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {"melee": "hammer_slam"}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "melee", "windup": 0.7, "reach": 52.0, "height": 34.0, "damage": 24.0, "status": {"burn": 2.5}, "max_range": 80.0},
		{"type": "wave", "windup": 0.8, "speed": 200.0, "damage": 16.0},
		{"type": "rain", "windup": 0.6, "style": "fire", "count": 3, "height": 46.0, "damage": 14.0},
	]
