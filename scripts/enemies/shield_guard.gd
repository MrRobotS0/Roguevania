class_name ShieldGuard
extends Enemy

# Guarda da Casa: escudo de bronze na frente defende tudo que vem de frente.
# Vira devagar — role por trás dele, ou bata enquanto ele está atacando.

const WALK := 28.0
const CHASE := 78.0
const REACH := 38.0
const TURN_DELAY := 0.45
const WINDUP := 0.55
const ACTIVE := 0.12
const RECOVER := 0.55
const DAMAGE := 16.0

const ARMOR := Color("8a2e2e")
const ARMOR_DARK := Color("561b22")
const BRONZE := Color("c8964a")

var _turn_clock := 0.0
var _hit_done := false


func _init() -> void:
	title = "GUARDA DA CASA"
	sheet = "guard"
	max_hp = 70
	hp = 70
	w = 14
	h = 24
	poise = 0.5
	weight = 1.6
	essence_drop = Vector2i(2, 3)


func body_color() -> Color:
	return ARMOR


func telegraphing() -> bool:
	return state == "windup"


func guard(d: Damage) -> bool:
	if d.unblockable or state in ["attack", "recover", "stun"]:
		return false
	if d.dir != -facing:
		return false
	Fx.burst(center() + Vector2(facing * 8, -2), BRONZE, 6, 100.0, 0.2)
	Sfx.play("block", -6.0)
	velocity.x = d.dir * 30.0
	return true


func think(delta: float) -> void:
	var d := to_player()
	var want := 1 if d.x > 0.0 else -1
	match state:
		"idle":
			if blocked(facing):
				facing = -facing
			velocity.x = facing * WALK
			if sees_player(160.0, 40.0):
				set_state("chase")
		"chase":
			if want != facing:
				_turn_clock += delta
				velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
				if _turn_clock >= TURN_DELAY:
					facing = want
					_turn_clock = 0.0
				return
			_turn_clock = 0.0
			if not player.alive() or absf(d.x) > 280.0 or absf(d.y) > 120.0:
				set_state("idle")
			elif absf(d.x) < REACH and absf(d.y) < 26.0:
				velocity.x = 0.0
				set_state("windup")
			else:
				velocity.x = 0.0 if blocked(facing) else facing * CHASE
		"windup":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if state_time >= WINDUP:
				_hit_done = false
				velocity.x = 0.0 if blocked(facing) else facing * 130.0
				set_state("attack")
		"attack":
			velocity.x = 0.0 if blocked(facing) else move_toward(velocity.x, 0.0, 700.0 * delta)
			if not _hit_done:
				_hit_done = strike(front_rect(REACH + 6.0, 10.0, 8.0), DAMAGE, 200.0)
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
			return ["recover", 0]
		"stun":
			return ["stun", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 3.0)]


func draw_body() -> void:
	pass
