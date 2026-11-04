class_name EliteGlutton
extends Boss

# Elite: O Ventre: o primeiro que o deus engoliu. Ficou lá dentro, comendo.


func _init() -> void:
	title = "GLUTÃO"
	sheet = "elite_glutton"
	max_hp = 170
	hp = 170
	w = 22
	h = 44
	weight = 2.5
	walk_speed = 80.0
	keep_distance = 0.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "volley", "windup": 0.6, "style": "orb", "count": 5, "spread": 0.5, "speed": 200.0, "damage": 15.0, "color": Color("ff7a3a")},
		{"type": "charge", "windup": 0.45, "speed": 360.0, "time": 0.5, "damage": 18.0},
		{"type": "melee", "windup": 0.4, "reach": 54.0, "height": 40.0, "damage": 20.0, "max_range": 80.0},
	]
