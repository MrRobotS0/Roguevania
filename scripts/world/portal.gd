class_name Portal
extends Interactable

# Pedra de passagem: um arco de pedra com um redemoinho dentro. Leva para
# qualquer outro portal que o herói já tenha visto neste andar, então dá para
# entrar fundo num desvio e voltar sem refazer o caminho.

const SEEN_RANGE := 120.0
const CORE := Color("b48cff")

var label := ""
var found := false
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	add_to_group("portals")
	_light = Glow.attach(self, CORE, 70.0, 0.55, Vector2(0, -16))


func _process(delta: float) -> void:
	super._process(delta)
	var p: Player = level.player if level and is_instance_valid(level.player) else null
	if not found and p and p.global_position.distance_to(global_position) < SEEN_RANGE:
		found = true
	_light.energy = (0.55 if found else 0.25) + 0.12 * sin(_t * 3.0)


func prompt() -> String:
	return "PORTAL: " + label


func detail() -> String:
	return ""


func destinations() -> Array[Portal]:
	var out: Array[Portal] = []
	for n in get_tree().get_nodes_in_group("portals"):
		var other := n as Portal
		if other != self and other.found:
			out.append(other)
	return out


func interact(p: Player) -> void:
	var list := destinations()
	if list.is_empty():
		Sfx.play("block", -8.0)
		return
	var options: Array[Dictionary] = []
	for d in list:
		options.append({"label": d.label, "detail": "", "color": CORE.lightened(0.3)})
	options.append({"label": "FICAR", "detail": ""})
	menu().open_choice("PORTAL", "", options, func(i: int) -> void:
		if i < list.size():
			travel(p, list[i]))


func travel(p: Player, to: Portal) -> void:
	Fx.burst(p.center(), CORE, 18, 140.0, 0.4, -40.0)
	p.global_position = to.global_position
	p.velocity = Vector2.ZERO
	Fx.burst(p.center(), CORE, 22, 160.0, 0.5, -60.0)
	Fx.add_shake(2.0)
	Sfx.play("portal")
	if level and level.camera:
		level.camera.snap()


func _draw() -> void:
	var k := 1.0 if found else 0.45
	# arco de pedra
	for i in 11:
		var a := lerpf(PI, TAU, i / 10.0)
		var c := Vector2(cos(a) * 11.0, sin(a) * 15.0 - 15.0)
		draw_rect(Rect2(c.round() - Vector2(2, 2), Vector2(4, 4)), Palette.STONE_TOP.darkened(0.15 * (i % 2)))
	draw_rect(Rect2(-13, -16, 4, 16), Palette.STONE_TOP.darkened(0.2))
	draw_rect(Rect2(9, -16, 4, 16), Palette.STONE_TOP.darkened(0.2))
	draw_rect(Rect2(-14, -2, 28, 2), Palette.STONE_TOP.darkened(0.35))
	# redemoinho
	for i in 14:
		var t := _t * (1.6 + i * 0.07) + i * 0.9
		var r := 2.0 + (i % 5) * 1.6
		var at := Vector2(cos(t) * r, sin(t) * r * 1.3 - 14.0)
		var c := CORE.lerp(Palette.FLASH, float(i % 3) * 0.25)
		c.a = k * (0.5 + 0.5 * sin(t * 2.0))
		draw_rect(Rect2(at.round(), Vector2(1, 1) * (1 + i % 2)), c)
	var core := CORE
	core.a = 0.25 * k
	draw_rect(Rect2(-7, -24, 14, 20), core)
