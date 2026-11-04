class_name BossWyrm
extends Boss

# A serpe do fundo: O deus que se escondia deixou alguém na porta.


func _init() -> void:
	title = "A SERPE DO FUNDO"
	subtitle = "O DEUS QUE SE ESCONDIA DEIXOU ALGUÉM NA PORTA"
	defeat_text = "A PORTA DO FUNDO ESTÁ ABERTA. LÁ DENTRO, NINGUÉM"
	sheet = "boss_wyrm"
	max_hp = 2100
	hp = 2100
	w = 48
	h = 40
	weight = 5.0
	walk_speed = 70.0
	keep_distance = 0.0
	sounds = {"volley": "roar", "leap": "roar"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "volley", "windup": 0.55, "style": "orb", "count": 4, "spread": 0.25, "speed": 260.0, "damage": 18.0, "color": Color("ff8a3a")},
		{"type": "leap", "windup": 0.6, "radius": 76.0, "damage": 24.0},
		{"type": "wave", "windup": 0.5, "speed": 220.0, "damage": 18.0},
	]
	moves2 = [
		{"type": "rain", "windup": 0.6, "style": "glass", "count": 6, "height": 50.0, "damage": 16.0},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/crevice_snake.gd", "count": 2},
	]
