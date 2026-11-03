class_name Assassin
extends Enemy

# Assassino da Duna: nada debaixo da cinza (não dá para acertar) e só a
# ondulação no chão denuncia. Emerge com um corte rápido, luta um pouco
# e afunda de novo. Olhe para o chão.

const SWIM := 105.0
const RISE := 0.45
const DASH := 230.0
const DAMAGE := 18.0

const CLOTH := Color("3a3046")
const WRAP := Color("c9b38a")

var _hit_done := false
var _rise_k := 0.0


func _init() -> void:
	title = "ASSASSINO DA DUNA"
	sheet = "assassin"
	max_hp = 40
	hp = 40
	w = 10
	h = 22
	essence_drop = Vector2i(2, 3)


func _ready() -> void:
	super._ready()
	set_state("hidden")
	ghost = true


func body_color() -> Color:
	return CLOTH


func telegraphing() -> bool:
	return state == "rise"


func hurt(d: Damage) -> bool:
	if ghost:
		return false
	return super.hurt(d)


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"hidden", "idle":
			ghost = true
			if absf(d.x) < 200.0 and absf(d.y) < 50.0 and player.alive():
				face_player()
				velocity.x = 0.0 if blocked(facing) else facing * SWIM
				if absf(d.x) < 16.0 or (state_time > 2.6 and absf(d.x) < 90.0):
					_surface()
			else:
				velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if int(state_time * 10.0) % 2 == 0:
				Fx.burst(global_position + Vector2(randf_range(-6, 6), -1), Palette.DUST, 1, 30.0, 0.4, 100.0, 2.0, 30.0)
		"rise":
			velocity.x = 0.0
			face_player()
			if state_time >= RISE:
				_hit_done = false
				velocity.x = 0.0 if blocked(facing) else facing * DASH
				set_state("slash")
				Sfx.play("swing", -6.0)
		"slash":
			velocity.x = 0.0 if blocked(facing) else move_toward(velocity.x, 0.0, 900.0 * delta)
			if not _hit_done:
				_hit_done = strike(front_rect(24.0, 20.0), DAMAGE, 180.0)
			if state_time >= 0.16:
				set_state("recover")
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_time >= 0.55:
				set_state("exposed")
		"exposed", "chase":
			if state == "chase":
				set_state("exposed")
			face_player()
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if absf(d.x) < 28.0 and state_time > 0.5:
				set_state("rise")
			elif state_time > 1.5:
				set_state("sink")
		"sink":
			velocity.x = 0.0
			if state_time >= 0.3:
				set_state("hidden")
				ghost = true


func _surface() -> void:
	ghost = false
	velocity.x = 0.0
	set_state("rise")
	Fx.burst(global_position, Palette.DUST, 10, 90.0, 0.4, 200.0, 2.0, 50.0)
	Sfx.play("burrow", -6.0)


func sprite_anim() -> Array:
	match state:
		"hidden", "idle":
			_rise_k = 0.0
		"rise":
			_rise_k = clampf(state_time / RISE, 0.0, 1.0)
		"sink":
			_rise_k = 1.0 - clampf(state_time / 0.3, 0.0, 1.0)
		_:
			_rise_k = 1.0
	body.visible = _rise_k > 0.0
	sink_px = (1.0 - _rise_k) * 26.0
	match state:
		"rise":
			return ["crouch" if _rise_k < 0.7 else "windup", 0]
		"slash":
			return ["slash", 0]
		"recover":
			return ["slash" if state_time < 0.1 else "idle", 0]
		"sink":
			return ["crouch", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 10.0)]
	return ["idle", int(_anim * 3.0)]


func draw_body() -> void:
	if state in ["hidden", "idle"]:
		# só um volume se mexendo na cinza
		var wob := sin(_anim * 12.0)
		draw_rect(Rect2(-6, -2 + wob * 0.5, 12, 2), Palette.DUST)
		draw_rect(Rect2(-3, -3, 6, 1), Palette.DUST.lightened(0.2))
	elif _rise_k < 1.0:
		draw_rect(Rect2(-8, -2, 16, 2), Palette.DUST)
		draw_rect(Rect2(-5, -3, 10, 1), Palette.DUST.lightened(0.15))
