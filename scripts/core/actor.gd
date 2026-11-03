class_name Actor
extends CharacterBody2D

# Base do herói, dos inimigos e dos chefes: vida, caixa de dano,
# efeitos de status (queimadura, atordoamento) e o desenho espelhado.

const BURN_TICK := 0.5
const BURN_DAMAGE := 3.0

var room: Room
var max_hp := 100
var hp := 100
var w := 12
var h := 22
var facing := 1
var statuses := {}

var flash := 0.0
var _burn_clock := 0.0
var _tint := Color(0, 0, 0, 0)


func setup_body(layer: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var holder := CollisionShape2D.new()
	holder.shape = shape
	holder.position = Vector2(0, -h * 0.5)
	add_child(holder)
	collision_layer = layer
	collision_mask = Room.WORLD_LAYER | Room.PLATFORM_LAYER


func alive() -> bool:
	return hp > 0


func center() -> Vector2:
	return global_position + Vector2(0, -h * 0.5)


func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-w * 0.5, -h), Vector2(w, h))


func has_status(name: String) -> bool:
	return statuses.get(name, 0.0) > 0.0


func add_status(name: String, seconds: float) -> void:
	statuses[name] = maxf(statuses.get(name, 0.0), seconds)


func apply_statuses(d: Damage) -> void:
	for name: String in d.status:
		add_status(name, d.status[name])


# Golpe recebido. Cada tipo de ator decide se defende, se atordoa etc.
func hurt(_d: Damage) -> bool:
	return false


func tick_statuses(delta: float) -> void:
	for name: String in statuses.keys():
		statuses[name] -= delta
		if statuses[name] <= 0.0:
			statuses.erase(name)
	if has_status("burn") and alive():
		_burn_clock -= delta
		if _burn_clock <= 0.0:
			_burn_clock = BURN_TICK
			var d := Damage.make(BURN_DAMAGE)
			d.over_time = true
			hurt(d)
			Fx.burst(center() + Vector2(randf_range(-4, 4), -4), Palette.BURN, 3, 40.0, 0.4, -120.0)


# --- desenho ------------------------------------------------------------------

func px(x: float, y: float, rw: float, rh: float, c: Color) -> void:
	if facing < 0:
		x = -x - rw
	draw_rect(Rect2(x, y, rw, rh), _tint if _tint.a > 0.0 else c)


func begin_tint() -> void:
	_tint = Palette.FLASH if flash > 0.0 else Color(0, 0, 0, 0)


func end_tint() -> void:
	_tint = Color(0, 0, 0, 0)


func draw_statuses(t: float) -> void:
	if has_status("burn"):
		for i in 3:
			var fx := -w * 0.5 + 2 + i * (w - 4) * 0.5
			var fh := 3.0 + fmod(t * 9.0 + i * 1.7, 3.0)
			draw_rect(Rect2(fx - 1, -h - fh + 4, 2, fh), Palette.BURN)
	if has_status("stun"):
		for i in 3:
			var a := t * 6.0 + i * TAU / 3.0
			draw_rect(Rect2(cos(a) * 6 - 1, -h - 5 + sin(a) * 2, 2, 2), Palette.DANGER)
