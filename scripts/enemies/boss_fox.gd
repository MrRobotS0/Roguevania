class_name BossFox
extends Boss

# A raposa de nove caudas: O deus que caminhava seguia ela. ela só anda em círculos.


func _init() -> void:
	title = "A RAPOSA DE NOVE CAUDAS"
	subtitle = "O DEUS QUE CAMINHAVA SEGUIA ELA. ELA SÓ ANDA EM CÍRCULOS"
	defeat_text = "AS NOVE CAUDAS SE APAGARAM. A ESTRADA TERMINA AQUI"
	sheet = "boss_fox"
	max_hp = 2000
	hp = 2000
	w = 40
	h = 40
	weight = 5.0
	walk_speed = 110.0
	keep_distance = 0.0
	sounds = {"volley": "spirit_call", "charge": "wolf_bite"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "charge", "windup": 0.4, "speed": 480.0, "time": 0.55, "damage": 22.0},
		{"type": "volley", "windup": 0.5, "style": "orb", "count": 9, "radial": true, "speed": 160.0, "damage": 14.0, "color": Color("9fd8ff")},
		{"type": "leap", "windup": 0.45, "radius": 60.0, "damage": 22.0},
		{"type": "teleport", "reach": 56.0, "damage": 20.0},
	]
	moves2 = [
		{"type": "volley", "windup": 0.5, "style": "orb", "count": 3, "spread": 0.4, "speed": 140.0, "homing": 2.2, "damage": 15.0, "color": Color("9fd8ff")},
		{"type": "rain", "windup": 0.6, "style": "vine", "count": 4, "height": 44.0, "predict": true, "damage": 18.0},
	]
