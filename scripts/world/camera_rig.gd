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


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var look := target.facing * LOOK_AHEAD
	var drop := LOOK_DOWN * clampf((target.velocity.y - 220.0) / 180.0, 0.0, 1.0)
	var goal := target.global_position + Vector2(look, HEIGHT + drop)
	global_position.x = lerpf(global_position.x, goal.x, 1.0 - exp(-6.0 * delta))
	global_position.y = lerpf(global_position.y, goal.y, 1.0 - exp(-9.0 * delta))

	var s := Fx.shake
	offset = Vector2(randf_range(-s, s), randf_range(-s, s)).round()
	Fx.shake = move_toward(Fx.shake, 0.0, 28.0 * delta)
