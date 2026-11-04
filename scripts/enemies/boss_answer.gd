class_name BossAnswer
extends Boss

# O que responde: Alguém ouviu as preces. não era o deus.


func _init() -> void:
	title = "O QUE RESPONDE"
	subtitle = "ALGUÉM OUVIU AS PRECES. NÃO ERA O DEUS"
	defeat_text = "O ALTAR FICOU EM SILÊNCIO. FINALMENTE"
	sheet = "boss_answer"
	max_hp = 1600
	hp = 1600
	w = 30
	h = 40
	weight = 5.0
	walk_speed = 60.0
	keep_distance = 120.0
	sounds = {"volley": "glyph", "rain": "curse"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "volley", "windup": 0.6, "style": "orb", "count": 3, "spread": 0.3, "speed": 160.0, "homing": 1.6, "damage": 16.0, "color": Color("6ae88a")},
		{"type": "rain", "windup": 0.6, "style": "water", "count": 4, "height": 70.0, "predict": true, "damage": 18.0},
		{"type": "beam", "windup": 0.8, "damage": 22.0},
	]
	moves2 = [
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/drowned.gd", "count": 2},
		{"type": "teleport", "reach": 60.0, "damage": 22.0},
	]
