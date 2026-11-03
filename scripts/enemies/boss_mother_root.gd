class_name MotherRoot
extends Boss

# A Mãe-Raiz: tudo que cresce aqui nasceu dela.


func _init() -> void:
	title = "A MÃE-RAIZ"
	subtitle = "TUDO QUE CRESCE AQUI NASCEU DELA"
	defeat_text = "O JARDIM SE CALOU"
	sheet = "mother_root"
	max_hp = 1600
	hp = 1600
	w = 50
	h = 50
	weight = 5.0
	walk_speed = 0.0
	keep_distance = 0.0
	sounds = {"volley": "thorn_shoot", "rain": "moss_charge", "summon": "spirit_call"}
	essence_drop = Vector2i(70, 70)

	moves = [
		{"type": "rain", "windup": 0.6, "style": "vine", "count": 4, "width": 20.0, "height": 56.0, "predict": true, "damage": 20.0},
		{"type": "volley", "windup": 0.6, "style": "thorn", "count": 5, "arc": true, "damage": 14.0},
		{"type": "rain", "windup": 0.7, "style": "spore", "count": 3, "width": 40.0, "height": 40.0, "damage": 12.0},
	]
	moves2 = [
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/thorn_plant.gd", "count": 2},
		{"type": "volley", "windup": 0.5, "style": "thorn", "count": 12, "radial": true, "speed": 150.0, "damage": 12.0},
	]
