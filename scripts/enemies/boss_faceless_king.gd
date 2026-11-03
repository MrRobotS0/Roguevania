class_name FacelessKing
extends Boss

# O Rei Sem Rosto: todos em carcosa usam a máscara dele.


func _init() -> void:
	title = "O REI SEM ROSTO"
	subtitle = "TODOS EM CARCOSA USAM A MÁSCARA DELE"
	defeat_text = "A MÁSCARA CAIU. NÃO HAVIA NADA EMBAIXO"
	sheet = "faceless_king"
	max_hp = 1700
	hp = 1700
	w = 18
	h = 44
	weight = 5.0
	walk_speed = 80.0
	keep_distance = 0.0
	sounds = {"summon": "bell", "volley": "glyph", "rain": "curse"}
	essence_drop = Vector2i(70, 70)

	moves = [
		{"type": "teleport", "reach": 50.0, "damage": 24.0},
		{"type": "melee", "windup": 0.4, "reach": 58.0, "height": 32.0, "damage": 24.0, "max_range": 90.0},
		{"type": "volley", "windup": 0.5, "style": "glyph", "count": 3, "spread": 0.25, "speed": 260.0, "damage": 16.0, "color": Color("e8d070")},
		{"type": "rain", "windup": 0.6, "style": "tendril", "count": 4, "height": 50.0, "predict": true, "damage": 18.0},
	]
	moves2 = [
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/masked.gd", "count": 2},
		{"type": "charge", "windup": 0.4, "speed": 420.0, "time": 0.7, "damage": 22.0},
	]
