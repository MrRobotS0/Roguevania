class_name EliteHermit
extends Boss

# Elite: Cavernas Fundas: desceu atrás do deus e não quis mais subir. Luta de mãos e pés.


func _init() -> void:
	title = "EREMITA DA FENDA"
	sheet = "elite_hermit"
	max_hp = 150
	hp = 150
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
		{"type": "leap", "windup": 0.5, "radius": 50.0, "damage": 18.0},
		{"type": "melee", "windup": 0.3, "reach": 48.0, "height": 30.0, "damage": 17.0, "max_range": 70.0},
		{"type": "charge", "windup": 0.4, "speed": 400.0, "time": 0.45, "damage": 16.0},
	]
