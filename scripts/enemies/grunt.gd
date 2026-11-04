class_name Grunt
extends Enemy

# Brutamontes: patrulha, persegue e dá uma pancada lenta e bem avisada.
# É o inimigo para treinar "esperar o aviso, rolar ou interromper".

const WALK := 34.0
const CHASE := 100.0
const REACH := 30.0
const WINDUP := 0.5
const ACTIVE := 0.14
const RECOVER := 0.42
const DAMAGE := 15

var _hit_done := false


func _init() -> void:
	title = "PENITENTE"
	sheet = "penitent"
	max_hp = 60
	hp = 60
	w = 14
	h = 22


func body_color() -> Color:
	return Palette.GRUNT


func telegraphing() -> bool:
	return state == "windup"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			if blocked(facing):
				facing = -facing
			velocity.x = facing * WALK
			if sees_player(150.0, 40.0):
				set_state("chase")
		"chase":
			facing = 1 if d.x > 0.0 else -1
			if not player.alive() or absf(d.x) > 260.0 or absf(d.y) > 120.0:
				set_state("idle")
			elif absf(d.x) < REACH and absf(d.y) < 26.0:
				velocity.x = 0.0
				set_state("windup")
			elif blocked(facing):
				velocity.x = 0.0
			else:
				velocity.x = facing * CHASE
		"windup":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if state_time >= WINDUP:
				_hit_done = false
				velocity.x = 0.0 if blocked(facing) else facing * 170.0
				set_state("attack")
		"attack":
			velocity.x = 0.0 if blocked(facing) else move_toward(velocity.x, 0.0, 900.0 * delta)
			if not _hit_done:
				_hit_done = strike(front_rect(30.0, 18.0), DAMAGE)
			if state_time >= ACTIVE:
				set_state("recover")
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_time >= RECOVER:
				set_state("chase")


func sprite_anim() -> Array:
	match state:
		"windup":
			return ["windup", 0]
		"attack":
			return ["attack", 0]
		"recover":
			return ["attack" if state_time < 0.12 else "idle", 0]
		"stun":
			return ["stun", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 3.0)]


func draw_body() -> void:
	if state == "attack" and state_time < ACTIVE:
		var swoosh := Palette.SLASH
		swoosh.a = 0.6
		px(6, -20, 22, 1, swoosh)
		px(10, -6, 18, 1, swoosh)
