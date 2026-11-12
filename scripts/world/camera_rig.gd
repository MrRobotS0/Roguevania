class_name CameraRig
extends Camera2D

# Segue o herói olhando um pouco para onde ele vai, e aplica o tremor.

const LOOK_AHEAD := 28.0
const HEIGHT := -46.0          # o herói fica no terço de baixo: mais céu, menos chão
const LOOK_DOWN := 46.0        # caindo rápido, a câmera desce para mostrar onde vai pousar

var target: Player


func follow(who: Player, bounds: Vector2) -> void:
	target = who
	_has_ref = false
	_look = 0.0
	limit_left = 0
	limit_top = 0
	limit_right = int(bounds.x)
	limit_bottom = int(bounds.y)
	global_position = who.global_position + Vector2(0, HEIGHT)
	make_current()
	reset_smoothing()
	reset_physics_interpolation()
	who.reset_physics_interpolation()


func snap() -> void:
	_has_ref = false
	_look = 0.0
	if is_instance_valid(target):
		global_position = target.global_position + Vector2(0, HEIGHT)
		reset_smoothing()
		reset_physics_interpolation()
		target.reset_physics_interpolation()


# O olhar para a frente desliza em vez de pular de lado a cada virada (no
# combate o herói vira o tempo todo). Na vertical, a câmera segue o chão onde
# ele pisou: um pulo comum não sacode a tela; só cair abaixo dele ou subir
# bem acima move a câmera no ar.
const LOOK_SPEED := 110.0      # px/s do olhar trocando de lado
const AIR_SLACK := 52.0        # quanto o herói sobe no ar antes da câmera ir junto

var _look := 0.0
var _ref_y := 0.0
var _has_ref := false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var moving := absf(target.velocity.x) > 40.0
	var want := target.facing * LOOK_AHEAD * (1.0 if moving else 0.6)
	_look = move_toward(_look, want, LOOK_SPEED * delta)
	var y := target.global_position.y
	if not _has_ref or target.is_on_floor():
		_ref_y = y
		_has_ref = true
	elif y > _ref_y:
		_ref_y = y
	elif y < _ref_y - AIR_SLACK:
		_ref_y = y + AIR_SLACK
	var drop := LOOK_DOWN * clampf((target.velocity.y - 220.0) / 180.0, 0.0, 1.0)
	var goal := Vector2(target.global_position.x + _look, _ref_y + HEIGHT + drop)
	global_position.x = lerpf(global_position.x, goal.x, 1.0 - exp(-9.0 * delta))
	global_position.y = lerpf(global_position.y, goal.y, 1.0 - exp(-8.0 * delta))

	_shake(delta)


# Tremor: o pedido (Fx.shake) é o pico em pixels. A amplitude cai ao quadrado
# (forte no impacto, some rápido) e o desvio vem de senoides em frequências
# que não se repetem, então a tela balança em vez de chiar quadro a quadro.
var _peak := 0.0
var _clock := 0.0
var _last := 0.0

func _shake(delta: float) -> void:
	var s := Fx.shake
	if s > _last:
		_peak = s          # pedido novo (até no meio de outro): recomeça do pico
	if s <= 0.0 or _peak <= 0.0:
		_last = 0.0
		_peak = 0.0
		offset = Vector2.ZERO
		return
	_clock += delta
	var k := s / _peak
	var amp := _peak * k * k
	var t := _clock * 38.0
	var wob := Vector2(sin(t) * 0.6 + sin(t * 2.31 + 1.7) * 0.4, sin(t * 1.13 + 0.4) * 0.6 + sin(t * 2.71 + 2.9) * 0.4)
	offset = (wob * amp).round()
	Fx.shake = move_toward(s, 0.0, 28.0 * delta)
	_last = Fx.shake
