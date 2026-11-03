class_name WolfKing
extends Boss

# O Lobo Da Longa Noite: guarda a porta de um dono que não volta.


func _init() -> void:
	title = "O LOBO DA LONGA NOITE"
	subtitle = "GUARDA A PORTA DE UM DONO QUE NÃO VOLTA"
	defeat_text = "O LOBO DEITOU. A NOITE FICOU MAIS CURTA"
	sheet = "wolf_king"
	max_hp = 1100
	hp = 1100
	w = 40
	h = 26
	weight = 5.0
	walk_speed = 90.0
	keep_distance = 0.0
	essence_drop = Vector2i(70, 70)

	moves = [
		{"type": "charge", "windup": 0.55, "speed": 360.0, "time": 0.9, "damage": 22.0, "recover": 0.6},
		{"type": "melee", "windup": 0.45, "reach": 56.0, "height": 26.0, "damage": 24.0, "max_range": 90.0},
		{"type": "volley", "windup": 0.6, "style": "shard", "count": 5, "spread": 0.22, "speed": 230.0, "damage": 14.0},
	]
	moves2 = [
		{"type": "summon", "windup": 0.7, "script": "res://scripts/enemies/wolf.gd", "count": 2},
		{"type": "rain", "windup": 0.6, "style": "glass", "count": 5, "height": 40.0, "predict": true, "damage": 16.0},
		{"type": "leap", "windup": 0.5, "radius": 70.0, "damage": 24.0},
	]
