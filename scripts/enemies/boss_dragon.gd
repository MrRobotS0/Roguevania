class_name BossDragon
extends Boss

# O dragão sonhado: O deus que sonhava sonhou um guarda. ele acordou.


func _init() -> void:
	title = "O DRAGÃO SONHADO"
	subtitle = "O DEUS QUE SONHAVA SONHOU UM GUARDA. ELE ACORDOU"
	defeat_text = "O SONHO ACABOU. O DRAGÃO NÃO ESTAVA MAIS LÁ"
	sheet = "boss_dragon"
	max_hp = 2000
	hp = 2000
	w = 50
	h = 46
	weight = 5.0
	walk_speed = 80.0
	keep_distance = 0.0
	sounds = {"volley": "roar", "charge": "roar"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "volley", "windup": 0.6, "style": "orb", "count": 5, "spread": 0.35, "speed": 240.0, "damage": 18.0, "color": Color("c88aff")},
		{"type": "charge", "windup": 0.5, "speed": 440.0, "time": 0.7, "damage": 24.0},
		{"type": "melee", "windup": 0.45, "reach": 76.0, "height": 40.0, "damage": 24.0, "max_range": 100.0},
		{"type": "rain", "windup": 0.7, "style": "dream", "count": 4, "height": 80.0, "predict": true, "damage": 18.0},
	]
	moves2 = [
		{"type": "beam", "windup": 0.7, "damage": 24.0},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/nightmare.gd", "count": 1},
	]
