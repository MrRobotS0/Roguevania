class_name Inquisitor
extends Enemy

# Inquisidor Profeta (elite): dois cortes de incensário de perto, e de longe
# um salto que cai onde você está, com onda de choque dos dois lados.

const CHASE := 60.0
const LEAP_COOLDOWN := 3.0
const SLASH_DAMAGE := 18.0
const SLAM_DAMAGE := 22.0

const ROBE := Color("e2d6b8")
const ROBE_DARK := Color("9d8f6f")
const GOLD := Color("d9a93f")

var _leap_cd := 1.0
var _hits := 0
var _hit_done := false
var _target_x := 0.0


func _init() -> void:
	title = "INQUISIDOR PROFETA"
	max_hp = 90
	hp = 90
	w = 16
	h = 28
	weight = 2.0
	poise = 0.6
	essence_drop = Vector2i(2, 3)


func body_color() -> Color:
	return ROBE


func telegraphing() -> bool:
	return state in ["slash_windup", "leap_windup"]


func think(delta: float) -> void:
	var d := to_player()
	_leap_cd -= delta
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if sees_player(220.0, 60.0):
				set_state("chase")
		"chase":
			face_player()
			if absf(d.x) < 40.0 and absf(d.y) < 30.0:
				_hits = 0
				set_state("slash_windup")
			elif _leap_cd <= 0.0 and absf(d.x) < 200.0 and is_on_floor():
				set_state("leap_windup")
			else:
				velocity.x = 0.0 if blocked(facing) else facing * CHASE
		"slash_windup":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if state_time >= (0.5 if _hits == 0 else 0.22):
				_hit_done = false
				velocity.x = 0.0 if blocked(facing) else facing * 120.0
				set_state("slash")
				Sfx.play("swing_heavy", -6.0)
		"slash":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if not _hit_done:
				_hit_done = strike(front_rect(34.0, 24.0), SLASH_DAMAGE, 200.0)
			if state_time >= 0.12:
				_hits += 1
				set_state("slash_windup" if _hits < 2 else "recover")
		"leap_windup":
			velocity.x = 0.0
			face_player()
			_target_x = player.global_position.x
			if state_time >= 0.55:
				var dx := clampf(_target_x - global_position.x, -230.0, 230.0)
				velocity = Vector2(dx / 0.62, -330.0)
				set_state("leap")
		"leap":
			if state_time > 0.1 and is_on_floor():
				_slam()
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_time >= 0.8:
				set_state("chase")


func _slam() -> void:
	velocity = Vector2.ZERO
	_leap_cd = LEAP_COOLDOWN
	var wave := Rect2(global_position.x - 56.0, global_position.y - 14.0, 112.0, 14.0)
	strike(wave, SLAM_DAMAGE, 240.0, {"unblockable": false})
	Fx.burst(global_position, Palette.DUST, 18, 160.0, 0.45, 200.0, 3.0, 30.0)
	Fx.add_shake(5.0)
	Sfx.play("slam")
	set_state("recover")


func draw_body() -> void:
	var crouch := 4.0 if state == "leap_windup" else 0.0
	var body := ROBE
	if telegraphing():
		body = ROBE.lerp(Palette.TELEGRAPH, 0.3 + 0.3 * sin(state_time * 30.0))
	px(-8, -22 + crouch, 16, 22 - crouch, body)
	px(-8, -6, 16, 6, ROBE_DARK)
	px(-2, -18 + crouch, 4, 10, GOLD)
	px(-5, -28 + crouch, 10, 7, ROBE_DARK)
	px(-3, -32 + crouch, 6, 4, GOLD)
	px(1, -25 + crouch, 3, 1, Palette.HERO_EYE)
	# incensário
	var swing := 0.0
	match state:
		"slash_windup": swing = -10.0
		"slash": swing = 14.0
	px(8 + swing * 0.5, -18 + crouch, 1, 10, GOLD)
	px(6 + swing, -9 + crouch, 5, 5, GOLD.darkened(0.2))
	if state == "slash":
		var trail := Palette.SLASH
		trail.a = 0.5
		px(8, -24, 26, 1, trail)
		px(8, -4, 26, 1, trail)
