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
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/mourner.gd", "count": 2},
		{"type": "melee", "windup": 0.45, "reach": 60.0, "height": 34.0, "damage": 22.0, "max_range": 90.0},
		{"type": "rain", "windup": 0.6, "style": "bone", "count": 5, "height": 46.0, "predict": true, "damage": 18.0},
		{"type": "charge", "windup": 0.45, "speed": 380.0, "time": 0.6, "damage": 20.0},
	]
	moves2 = [
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/risen.gd", "count": 2},
		{"type": "volley", "windup": 0.5, "style": "glyph", "count": 10, "radial": true, "speed": 150.0, "damage": 13.0, "color": Color("a8c0e8")},
	]


static var _told := false


# Enquanto os mortos que ele chamou estão de pé, ele quase não sente: mate-os primeiro.
func hurt(d: Damage) -> bool:
	if _adds() > 0 and not d.over_time and state != "intro":
		d.amount *= 0.35
		Fx.burst(center(), Color("a8c0e8"), 6, 90.0, 0.3)
		if not _told:
			_told = true
			Fx.toast("OS MORTOS O PROTEGEM")
	return super.hurt(d)


func draw_body() -> void:
	if is_inside_tree() and _adds() > 0:
		var c := Color("a8c0e8")
		c.a = 0.45 + 0.25 * sin(_anim * 5.0)
		draw_arc(Vector2(0, -h * 0.5), maxf(h, 40.0) * 0.72, 0.0, TAU, 28, c, 1.0)
