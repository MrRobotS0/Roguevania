class_name BossInsatiable
extends Boss

# O insaciável: O deus que devorava comeu até a própria fome.


func _init() -> void:
	title = "O INSACIÁVEL"
	subtitle = "O DEUS QUE DEVORAVA COMEU ATÉ A PRÓPRIA FOME"
	defeat_text = "A GOELA FECHOU. O VENTRE PAROU DE BATER"
	sheet = "boss_insatiable"
	max_hp = 1800
	hp = 1800
	w = 34
	h = 52
	weight = 5.0
	walk_speed = 90.0
	keep_distance = 0.0
	sounds = {"melee": "hammer_slam", "rain": "pillar"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "melee", "windup": 0.55, "reach": 80.0, "height": 50.0, "damage": 26.0, "max_range": 110.0},
		{"type": "leap", "windup": 0.6, "radius": 70.0, "damage": 24.0},
		{"type": "rain", "windup": 0.6, "style": "bile", "count": 5, "height": 56.0, "predict": true, "damage": 18.0},
	]
	moves2 = [
		{"type": "volley", "windup": 0.5, "style": "orb", "count": 9, "arc": true, "damage": 15.0, "color": Color("c8d040")},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/larva.gd", "count": 3},
	]
