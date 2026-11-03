class_name Automaton
extends Enemy

# Autômato Astral (Observatório): anda devagar e, quando te vê, mira (o olho
# acende) e solta um raio horizontal na altura dele. Pule ou role.

var _cd := 1.0


func _init() -> void:
	title = "AUTÔMATO ASTRAL"
	sheet = "automaton"
	max_hp = 70
	hp = 70
	w = 12
	h = 26
	poise = 0.5
	weight = 1.8
	essence_drop = Vector2i(2, 4)


func telegraphing() -> bool:
	return state == "aim"


func think(delta: float) -> void:
	_cd -= delta
	var d := to_player()
	match state:
		"idle", "chase":
			face_player()
			velocity.x = 0.0 if blocked(facing) or absf(d.x) < 60.0 else facing * 30.0
			if _cd <= 0.0 and sees_player(260.0, 40.0):
				set_state("aim")
		"aim":
			velocity.x = 0.0
			if state_time >= 0.8:
				_cd = 3.0
				var beam := Hazard.new()
				beam.player = player
				beam.style = "light"
				beam.source = self
				beam.width = 260.0
				beam.height = 10.0
				beam.delay = 0.0
				beam.linger = 0.3
				beam.damage = 18.0
				beam.position = global_position + Vector2(facing * 134.0, -12.0)
				get_parent().add_child(beam)
				set_state("idle")


func _draw() -> void:
	if state == "aim" and alive():
		var c := Palette.GLASS
		c.a = 0.25 + 0.5 * state_time / 0.8
		draw_line(Vector2(facing * 6, -17), Vector2(facing * 260, -17), c, 1.0)
	super._draw()


func sprite_anim() -> Array:
	if state == "aim":
		return ["windup", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 6.0)]
	return ["idle", int(_anim * 2.0)]
