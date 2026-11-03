class_name EliteLibrarian
extends Boss

# Elite: Bibliotecário Cego. Um mini-guardião: só age quando vê o herói.


func _init() -> void:
	title = "BIBLIOTECÁRIO CEGO"
	sheet = "elite_librarian"
	max_hp = 120
	hp = 120
	w = 14
	h = 38
	weight = 2.5
	walk_speed = 30.0
	keep_distance = 110.0
	aggro_range = 220.0
	rest_every = 4
	sounds = {"volley": "glyph"}
	essence_drop = Vector2i(3, 5)
	moves = [
		{"type": "volley", "windup": 0.6, "style": "glyph", "count": 8, "radial": true, "speed": 110.0, "damage": 12.0, "color": Palette.GOLD},
		{"type": "volley", "windup": 0.5, "style": "glyph", "count": 2, "spread": 0.4, "speed": 130.0, "homing": 1.5, "damage": 13.0, "color": Palette.GOLD},
		{"type": "teleport", "reach": 40.0, "damage": 16.0},
	]
