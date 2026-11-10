class_name Hazard
extends Node2D

# Perigo de cenário com aviso: marca o chão, espera e dispara uma coluna.
#   "glass": espinho de vidro que sobe da cinza (fulgurante)
#   "light": coluna de luz profética (Imperador Cego)
#   "fire":  jato de fogo da Forja (queima)
#   "molten": poça de escória derretida (queima)
# Não se mata; se desvia.

var player: Player
var style := "glass"
var delay := 0.7
var width := 14.0
var height := 34.0
var damage := 18.0
var linger := 0.35
var source: Node
var quiet := false            # rastro: sem som nem tremor (são muitos em seguida)

var _t := 0.0
var _fired := false


var _light: PointLight2D


func _ready() -> void:
	z_index = 3
	if style == "light":
		_light = Glow.attach(self, Palette.SLASH, maxf(width * 3.0, 60.0), 0.0, Vector2(0, -20))
	if not quiet:
		Sfx.play("omen" if style == "light" else "crack", -8.0)
	if style == "fire":
		_light = Glow.attach(self, Palette.BURN, 70.0, 0.0, Vector2(0, -20))


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


# o nome que aparece em "morto por" e no relatório
func danger_name() -> String:
	match style:
		"glass": return "ESPINHO DE VIDRO"
		"light": return "COLUNA DE LUZ"
		"fire": return "JATO DE FOGO"
		"molten": return "ESCÓRIA DERRETIDA"
	return "PERIGO DO CENÁRIO"


func _fire() -> void:
	var zone := Rect2(global_position.x - width * 0.5, global_position.y - height, width, height)
	if is_instance_valid(player) and player.alive() and zone.intersects(player.hurt_rect()):
		var d := Damage.make(damage, 1 if player.global_position.x >= global_position.x else -1, 150.0)
		d.source = source if is_instance_valid(source) else self
		d.label = danger_name()
		d.unblockable = true
		if style in ["fire", "molten"]:
			d.status = {"burn": 3.0}
		player.hurt(d)
	var color := _tint()
	Fx.burst(global_position + Vector2(0, -height * 0.5), color, 12, 150.0, 0.4, 300.0, 2.0, 60.0)
	if not quiet:
		Fx.add_shake(2.0)
		Sfx.play("spike" if style == "glass" else "pillar", -4.0)


const TINTS := {
	"glass": Color("bfe6ea"), "light": Color("fff3c4"), "fire": Color("ff9a3c"), "molten": Color("ff9a3c"),
	"vine": Color("6a9a3a"), "tendril": Color("5a2a7a"), "spore": Color("b8d05a"),
	"bone": Color("e8e0c8"), "water": Color("8ad0f0"), "bile": Color("c8d040"), "dream": Color("c8a8ff"),
}


func _tint() -> Color:
	return TINTS.get(style, Palette.GLASS)


func _draw() -> void:
	if style == "spore":
		_draw_spore()
		return
	if style == "fire" or style == "molten":
		_draw_fire()
		return
	if not _fired:
		var k := clampf(_t / delay, 0.0, 1.0)
		var warn := Palette.DANGER if style == "light" else _tint()
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
			var glass := _tint()
			glass.a = 0.4 + 0.6 * fade
			draw_colored_polygon(PackedVector2Array([
				Vector2(-width * 0.5, 0), Vector2(-2, -height * rise), Vector2(1, -height * 0.8 * rise),
				Vector2(width * 0.5, 0)]), glass)


func _draw_fire() -> void:
	var half := width * 0.5
	if not _fired:
		var k := clampf(_t / maxf(delay, 0.01), 0.0, 1.0)
		var glow := Palette.BURN
		glow.a = 0.3 + 0.6 * k
		draw_rect(Rect2(-half, -2, width, 2), glow)
		for i in 3:
			var y := -fmod(_t * 30.0 + i * 5.0, 12.0)
			draw_rect(Rect2(-2 + i * 2, y - 2, 1, 2), glow)
		return
	var fade := 1.0 - clampf((_t - delay) / linger, 0.0, 1.0)
	if style == "molten":
		var pool := Palette.BURN
		pool.a = fade
		draw_rect(Rect2(-half, -2, width, 2), pool)
		draw_rect(Rect2(-half + 3, -3, width - 6, 1), Palette.DANGER)
		return
	if _light:
		_light.energy = 1.4 * fade
	for i in 5:
		var x := -half + i * width / 5.0
		var tall := height * (0.6 + 0.4 * absf(sin(_t * 23.0 + i * 1.7))) * fade
		var c := Palette.BURN if i % 2 else Palette.DANGER
		draw_rect(Rect2(x, -tall, width / 5.0 + 1.0, tall), c)
	var core := Palette.FLASH
	core.a = fade
	draw_rect(Rect2(-2, -height * 0.7 * fade, 4, height * 0.7 * fade), core)


func _draw_spore() -> void:
	var half := width * 0.5
	if not _fired:
		var k := clampf(_t / maxf(delay, 0.01), 0.0, 1.0)
		var pod := _tint()
		pod.a = 0.4 + 0.5 * k
		draw_rect(Rect2(-3, -4 - k * 2.0, 6, 4 + k * 2.0), pod)
		return
	var fade := 1.0 - clampf((_t - delay) / linger, 0.0, 1.0)
	for i in 10:
		var a := i * 0.63 + _t * 2.0
		var r := half * (0.3 + 0.7 * fposmod(i * 0.37 + _t, 1.0))
		var c := _tint()
		c.a = 0.6 * fade
		draw_rect(Rect2(Vector2(cos(a) * r, -height * 0.5 + sin(a) * r * 0.6) - Vector2(2, 2), Vector2(4, 4)), c)
