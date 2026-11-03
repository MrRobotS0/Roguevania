class_name Colossus
extends Boss

# O Colosso Da Bigorna: o ferreiro que o deus esqueceu ligado.


func _init() -> void:
	title = "O COLOSSO DA BIGORNA"
	subtitle = "O FERREIRO QUE O DEUS ESQUECEU LIGADO"
	defeat_text = "A BIGORNA SILENCIOU"
	sheet = "colossus"
	max_hp = 1400
	hp = 1400
	w = 30
	h = 56
	weight = 5.0
	walk_speed = 40.0
	keep_distance = 0.0
	sounds = {"melee": "hammer_slam", "summon": "slag_hop", "rain": "laser_charge"}
	essence_drop = Vector2i(70, 70)

	moves = [
		{"type": "melee", "windup": 0.8, "reach": 64.0, "height": 40.0, "damage": 30.0, "status": {"burn": 2.5}, "max_range": 100.0},
		{"type": "wave", "windup": 0.9, "speed": 210.0, "damage": 20.0},
		{"type": "rain", "windup": 0.7, "style": "fire", "count": 5, "height": 50.0, "damage": 18.0},
	]
	moves2 = [
		{"type": "leap", "windup": 0.6, "radius": 80.0, "damage": 28.0},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/slag.gd", "count": 3},
	]
