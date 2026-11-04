class_name BossForgotten
extends Boss

# O rei esquecido: Ele lembra de todos os mortos, menos de si mesmo.


func _init() -> void:
	title = "O REI ESQUECIDO"
	subtitle = "ELE LEMBRA DE TODOS OS MORTOS, MENOS DE SI MESMO"
	defeat_text = "ELE LEMBROU O PRÓPRIO NOME. E DESCANSOU"
	sheet = "boss_forgotten"
	max_hp = 1300
	hp = 1300
	w = 16
	h = 46
	weight = 5.0
	walk_speed = 70.0
	keep_distance = 0.0
	sounds = {"summon": "bell", "rain": "curse"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "melee", "windup": 0.45, "reach": 60.0, "height": 34.0, "damage": 22.0, "max_range": 90.0},
		{"type": "rain", "windup": 0.6, "style": "bone", "count": 5, "height": 46.0, "predict": true, "damage": 18.0},
		{"type": "charge", "windup": 0.45, "speed": 380.0, "time": 0.6, "damage": 20.0},
	]
	moves2 = [
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/mourner.gd", "count": 2},
		{"type": "volley", "windup": 0.5, "style": "glyph", "count": 10, "radial": true, "speed": 150.0, "damage": 13.0, "color": Color("a8c0e8")},
	]
