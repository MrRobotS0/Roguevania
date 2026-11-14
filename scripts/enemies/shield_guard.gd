class_name ShieldGuard
extends Enemy

# Guarda da Casa: escudo de bronze na frente defende tudo que vem de frente.
# Vira devagar — role por trás dele, ou bata enquanto ele está atacando.
# O escudo não aguenta para sempre: BREAK_HITS golpes seguidos de frente o
# quebram (fica tonto por BREAK_STUN s). Os risquinhos na cabeça mostram quanto falta.

const WALK := 28.0
const CHASE := 78.0
const REACH := 38.0
const TURN_DELAY := 0.45
const WINDUP := 0.55
const ACTIVE := 0.12
const RECOVER := 0.55
const DAMAGE := 16.0
const BREAK_HITS := 3
const BREAK_STUN := 1.3
const BREAK_FORGET := 1.6     # sem apanhar por esse tempo, o escudo se recompõe
const FIRST_FLOOR_HP := 55    # no 1º andar ele é mais curto (os novatos travavam aqui)

const ARMOR := Color("8a2e2e")
const ARMOR_DARK := Color("561b22")
const BRONZE := Color("c8964a")

var _turn_clock := 0.0
var _hit_done := false
var blocks := 0               # golpes de frente seguidos (zera ao quebrar ou ao passar o tempo)
var blocked_once := false     # a dica do escudo aparece no primeiro bloqueio
var _since_block := 99.0


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
	if Run.stage_tier == 0:
		max_hp = FIRST_FLOOR_HP
		hp = FIRST_FLOOR_HP


func body_color() -> Color:
	return ARMOR


func telegraphing() -> bool:
	return state == "windup"


func guard(d: Damage) -> bool:
	if d.unblockable or state in ["attack", "recover", "stun"]:
		return false
	if d.dir != -facing:
		return false
	blocks += 1
	blocked_once = true
	_since_block = 0.0
	if blocks >= BREAK_HITS:
		_break_guard(d)
		return false
	Fx.burst(center() + Vector2(facing * 8, -2), BRONZE, 6 + 4 * blocks, 100.0 + 40.0 * blocks, 0.2)
	Sfx.play("block", -6.0)
	velocity.x = d.dir * 30.0
	return true


# Escudo quebrado: o golpe que quebrou passa, e ele fica tonto, aberto.
func _break_guard(d: Damage) -> void:
	blocks = 0
	Fx.burst(center() + Vector2(facing * 8, -2), BRONZE, 22, 240.0, 0.45)
	Fx.spray(center() + Vector2(facing * 8, -2), d.dir, BRONZE.lightened(0.3), 12, 260.0)
	Fx.impact(center() + Vector2(facing * 8, -2), BRONZE.lightened(0.4), true)
	Fx.add_shake(2.5)
	Fx.hitstop(0.06)
	Sfx.play("crack", -2.0)
	stagger(BREAK_STUN)


func _physics_process(delta: float) -> void:
	_since_block += delta
	if blocks > 0 and (_since_block > BREAK_FORGET or state in ["attack", "recover"]):
		blocks = 0
	super._physics_process(delta)


func _draw() -> void:
	super._draw()
	if blocks <= 0 or not alive():
		return
	# risquinhos de bronze em cima da cabeça: quantos golpes faltam para quebrar
	var top := -maxf(float(h), sprite_top()) - 12.0
	var x0 := -float(BREAK_HITS * 4 - 1) * 0.5
	for i in BREAK_HITS:
		var c := BRONZE.lightened(0.25) if i < blocks else Color(Palette.UI_SHADOW, 0.7)
		draw_rect(Rect2(roundf(x0 + i * 4.0) - 0.5, top - 0.5, 4, 4), Palette.UI_SHADOW)
		draw_rect(Rect2(roundf(x0 + i * 4.0), top, 3, 3), c)


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
