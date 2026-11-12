class_name CameraRig
extends Camera2D

# Segue o herói olhando um pouco para onde ele vai, e aplica o tremor.

const LOOK_AHEAD := 28.0
const HEIGHT := -46.0          # o herói fica no terço de baixo: mais céu, menos chão
const LOOK_DOWN := 46.0        # caindo rápido, a câmera desce para mostrar onde vai pousar

var target: Player


func follow(who: Player, bounds: Vector2) -> void:
	target = who
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
	if is_instance_valid(target):
		global_position = target.global_position + Vector2(0, HEIGHT)
		reset_smoothing()
		reset_physics_interpolation()
		target.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var look := target.facing * LOOK_AHEAD
	var drop := LOOK_DOWN * clampf((target.velocity.y - 220.0) / 180.0, 0.0, 1.0)
	var goal := target.global_position + Vector2(look, HEIGHT + drop)
	global_position.x = lerpf(global_position.x, goal.x, 1.0 - exp(-9.0 * delta))
	global_position.y = lerpf(global_position.y, goal.y, 1.0 - exp(-12.0 * delta))

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
