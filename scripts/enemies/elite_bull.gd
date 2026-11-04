class_name EliteBull
extends Boss

# Elite: Bosque Errante: cobra pedágio de quem passa. Ninguém tem com que pagar.


func _init() -> void:
	title = "TOURO DA ESTRADA"
	sheet = "elite_bull"
	max_hp = 170
	hp = 170
	w = 20
	h = 36
	weight = 2.5
	walk_speed = 80.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "charge", "windup": 0.5, "speed": 420.0, "time": 0.6, "damage": 20.0},
		{"type": "melee", "windup": 0.45, "reach": 56.0, "height": 34.0, "damage": 20.0, "max_range": 80.0},
		{"type": "leap", "windup": 0.55, "radius": 56.0, "damage": 18.0},
	]
