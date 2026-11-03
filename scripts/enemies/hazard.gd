class_name Hazard
extends Node2D

# Perigo de cenário com aviso: marca o chão, espera e dispara uma coluna.
#   "glass": espinho de vidro que sobe da cinza (fulgurante)
#   "light": coluna de luz profética (Imperador Cego)
# Não se mata; se desvia.

var player: Player
var style := "glass"
var delay := 0.7
var width := 14.0
var height := 34.0
var damage := 18.0
var linger := 0.35
var source: Node

var _t := 0.0
var _fired := false


var _light: PointLight2D


func _ready() -> void:
	z_index = 3
	if style == "light":
		_light = Glow.attach(self, Palette.SLASH, maxf(width * 3.0, 60.0), 0.0, Vector2(0, -20))
	Sfx.play("crack" if style == "glass" else "omen", -8.0)


func _physics_process(delta: float) -> void:
	_t += delta
	if _light:
		if _fired:
			_light.energy = 1.6 * (1.0 - clampf((_t - delay) / linger, 0.0, 1.0))
			_light.position.y = -height * 0.5
			_light.texture_scale = height * 1.4 / 128.0
		else:
			_light.energy = 0.5 * clampf(_t / delay, 0.0, 1.0)
	if not _fired and _t >= delay:
		_fired = true
		_fire()
	if _t >= delay + linger:
		queue_free()
	queue_redraw()


func _fire() -> void:
	var zone := Rect2(global_position.x - width * 0.5, global_position.y - height, width, height)
	if is_instance_valid(player) and player.alive() and zone.intersects(player.hurt_rect()):
		var d := Damage.make(damage, 1 if player.global_position.x >= global_position.x else -1, 150.0)
		d.source = source
		d.unblockable = true
		player.hurt(d)
	var color := Palette.GLASS if style == "glass" else Palette.SLASH
	Fx.burst(global_position + Vector2(0, -height * 0.5), color, 12, 150.0, 0.4, 300.0, 2.0, 60.0)
	Fx.add_shake(2.0)
	Sfx.play("spike" if style == "glass" else "pillar", -4.0)


func _draw() -> void:
	if not _fired:
		var k := clampf(_t / delay, 0.0, 1.0)
		var warn := Palette.DANGER if style == "light" else Palette.GLASS
		warn.a = 0.35 + 0.5 * k
		var half := width * 0.5
		if style == "light":
			draw_rect(Rect2(-half, -2, width, 2), warn)
			for i in 4:
				var a := _t * 5.0 + i * TAU / 4.0
				draw_rect(Rect2(cos(a) * half - 1, -6 + sin(a) * 2, 2, 2), warn)
			var beam := warn
			beam.a = 0.12 * k
			draw_rect(Rect2(-half, -height, width, height), beam)
		else:
			for i in 5:
				var x := -half + i * width / 4.0
				draw_rect(Rect2(x, -1 - (i % 2), 1, 1 + (i % 2) + k * 2.0), warn)
	else:
		var fade := 1.0 - clampf((_t - delay) / linger, 0.0, 1.0)
		if style == "light":
			var core := Palette.SLASH
			core.a = fade
			draw_rect(Rect2(-width * 0.5, -height, width, height), core)
			var edge := Palette.DANGER
			edge.a = fade
			draw_rect(Rect2(-width * 0.5 - 2, -height, 2, height), edge)
			draw_rect(Rect2(width * 0.5, -height, 2, height), edge)
		else:
			var rise := minf((_t - delay) / 0.06, 1.0)
			var glass := Palette.GLASS
			glass.a = 0.4 + 0.6 * fade
			draw_colored_polygon(PackedVector2Array([
				Vector2(-width * 0.5, 0), Vector2(-2, -height * rise), Vector2(1, -height * 0.8 * rise),
				Vector2(width * 0.5, 0)]), glass)
