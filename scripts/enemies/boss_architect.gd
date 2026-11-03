class_name Architect
extends Boss

# O Arquiteto Mudo: ergueu a torre. esqueceu a própria língua.


func _init() -> void:
	title = "O ARQUITETO MUDO"
	subtitle = "ERGUEU A TORRE. ESQUECEU A PRÓPRIA LÍNGUA"
	defeat_text = "A TORRE PAROU DE CRESCER"
	sheet = "architect"
	max_hp = 1500
	hp = 1500
	w = 26
	h = 60
	weight = 5.0
	walk_speed = 30.0
	keep_distance = 140.0
	essence_drop = Vector2i(70, 70)

	moves = [
		{"type": "volley", "windup": 0.6, "style": "glyph", "count": 3, "spread": 0.3, "speed": 150.0, "homing": 1.6, "damage": 14.0, "color": Palette.GOLD},
		{"type": "rain", "windup": 0.7, "style": "light", "count": 4, "width": 22.0, "height": 170.0, "predict": true, "damage": 20.0},
		{"type": "volley", "windup": 0.5, "style": "glyph", "count": 10, "radial": true, "speed": 120.0, "damage": 12.0, "bursts": 2, "rate": 0.35, "color": Palette.GOLD},
	]
	moves2 = [
		{"type": "teleport", "reach": 50.0, "damage": 22.0},
		{"type": "beam", "windup": 0.4, "damage": 22.0},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/scribe.gd", "count": 2},
	]
