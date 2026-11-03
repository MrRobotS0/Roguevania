class_name Icicle
extends Node2D

# Estalactite dos Salões: pendurada no teto acima do marcador. Quando o herói
# passa embaixo, treme (aviso) e cai. Volta a crescer depois de um tempo.

const SHAKE := 0.45
const REGROW := 4.0
const DAMAGE := 18.0

var room: Room
var player: Player
var _ceiling := 0.0
var _y := 0.0
var _vy := 0.0
var _state := "hang"
var _t := 0.0


func _ready() -> void:
	z_index = 3
	# acha o teto subindo a partir do chão
	var probe := position + Vector2(0, -8)
	var steps := 0
	while steps < 40 and not room.is_solid_at(probe):
		probe.y -= Room.TILE
		steps += 1
	_ceiling = (floorf(probe.y / Room.TILE) + 1.0) * Room.TILE - position.y
	_y = _ceiling


func _physics_process(delta: float) -> void:
	_t += delta
	match _state:
		"hang":
			if is_instance_valid(player) and player.alive() and absf(player.global_position.x - global_position.x) < 18.0 \
					and player.global_position.y > global_position.y + _ceiling:
				_state = "shake"
				_t = 0.0
				Sfx.play("crack", -8.0)
		"shake":
			if _t >= SHAKE:
				_state = "fall"
				_vy = 0.0
		"fall":
			_vy = minf(_vy + 900.0 * delta, 520.0)
			_y += _vy * delta
			var tip := global_position + Vector2(0, _y + 12.0)
			if is_instance_valid(player) and player.alive() and Rect2(tip - Vector2(4, 12), Vector2(8, 12)).intersects(player.hurt_rect()):
				var d := Damage.make(DAMAGE, 1 if player.global_position.x >= global_position.x else -1, 120.0)
				d.unblockable = true
				player.hurt(d)
				_shatter()
			elif room.is_solid_at(tip) or _y >= -2.0:
				_shatter()
		"gone":
			if _t >= REGROW:
				_state = "hang"
				_y = _ceiling
	queue_redraw()


func _shatter() -> void:
	Fx.burst(global_position + Vector2(0, _y + 10.0), Palette.GLASS, 12, 110.0, 0.4, 400.0)
	Sfx.play("spike", -6.0)
	_state = "gone"
	_t = 0.0


func _draw() -> void:
	if _state == "gone":
		var grow := clampf(_t / REGROW, 0.0, 1.0)
		draw_rect(Rect2(-2, _ceiling, 4, 4.0 * grow), Palette.GLASS.darkened(0.2))
		return
	var shake := (randf_range(-1.0, 1.0) if _state == "shake" else 0.0)
	var top := _y
	var ice := Palette.GLASS
	for i in 6:
		var wid := 7.0 - i
		draw_rect(Rect2(-wid * 0.5 + shake, top + i * 2.5, wid, 3), ice.darkened(i * 0.05))
	draw_rect(Rect2(-3 + shake, top, 1, 10), Palette.FLASH)
