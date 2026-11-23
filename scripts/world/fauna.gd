class_name Fauna
extends Node2D

# Vida no fundo: o que cruza o céu de cada domínio, entre as camadas
# pintadas (fica atrás das camadas de perto, então parece longe). Tudo em
# silhueta da cor da camada do meio, desenhado em pixel, em coordenadas de
# tela. Anda em paralaxe fraca com a câmera e sozinho no tempo.

const KINDS := {
	"mar_de_cinzas": "birds",
	"saloes": "bats",
	"forja_rubra": "embers",
	"necropole": "crows",
	"torre_babel": "birds",
	"jardim_primordial": "leaves",
	"catedral": "fish",
	"carcosa": "eyes",
	"observatorio": "meteors",
	"ventre": "spores",
	"penhascos": "birds",
	"cavernas": "bats",
	"bosque": "leaves",
}
const COUNT := {"birds": 9, "bats": 8, "crows": 7, "embers": 26, "leaves": 18, "fish": 10, "eyes": 6, "meteors": 3, "spores": 22}
const PARALLAX := 0.12

var kind := ""
var ink := Color(0, 0, 0, 0.55)
var light := Color(1, 1, 1, 0.8)
var _t := 0.0
var _items: Array = []


func use(biome_id: String, ink_color: Color, light_color: Color) -> void:
	kind = KINDS.get(biome_id, "")
	ink = ink_color
	light = light_color
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(biome_id) + 17
	_items.clear()
	for i in COUNT.get(kind, 0):
		# [x em fração, y em fração, velocidade, fase, tamanho]
		_items.append([rng.randf(), rng.randf_range(0.08, 0.55), rng.randf_range(0.6, 1.4), rng.randf() * TAU, rng.randi_range(0, 2)])
	visible = kind != ""


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x * PARALLAX if cam else 0.0
	var wide := size.x + 80.0
	for it in _items:
		var sp: float = it[2]
		var ph: float = it[3]
		var big: int = it[4]
		var base := Vector2(float(it[0]) * wide, float(it[1]) * size.y)
		match kind:
			"birds", "crows":
				# bando que atravessa em ondas, asas batendo
				var x := fposmod(base.x + _t * 14.0 * sp - cx, wide) - 40.0
				var y := base.y + sin(_t * 0.6 * sp + ph) * 8.0
				_bird(Vector2(x, y).round(), int(_t * 6.0 * sp + ph * 3.0) % 4, big, kind == "crows")
			"bats":
				var x2 := fposmod(base.x - _t * 22.0 * sp - cx, wide) - 40.0
				var y2 := base.y + sin(_t * 3.1 * sp + ph) * 5.0 + sin(_t * 0.8 + ph) * 14.0
				_bat(Vector2(x2, y2).round(), int(_t * 14.0 * sp + ph * 5.0) % 2)
			"embers":
				var x3 := fposmod(base.x + sin(_t * 0.9 * sp + ph) * 16.0 - cx * 0.5, wide) - 40.0
				var y3 := fposmod(base.y + size.y * 0.5 - _t * 18.0 * sp, size.y + 20.0) - 10.0
				var a := clampf(y3 / size.y, 0.0, 1.0)
				_dot(Vector2(x3, y3).round(), Color(light, 0.25 + 0.6 * a), 1 + big / 2)
			"leaves":
				var x4 := fposmod(base.x + _t * 11.0 * sp + sin(_t * 1.3 * sp + ph) * 12.0 - cx * 0.7, wide) - 40.0
				var y4 := fposmod(base.y + _t * 9.0 * sp, size.y + 20.0) - 10.0
				_leaf(Vector2(x4, y4).round(), int(_t * 5.0 * sp + ph * 4.0) % 4)
			"fish":
				var dir := -1.0 if int(ph * 10.0) % 2 == 0 else 1.0
				var x5 := fposmod(base.x + dir * _t * 9.0 * sp - cx, wide) - 40.0
				var y5 := base.y + 0.25 * size.y + sin(_t * 1.2 * sp + ph) * 4.0
				_fish(Vector2(x5, y5).round(), dir, int(_t * 4.0 * sp + ph) % 2, big)
			"eyes":
				# olhos que abrem no escuro do fundo e piscam
				var cycle := fposmod(_t * 0.18 * sp + ph, 1.0)
				if cycle < 0.55:
					var opening := minf(1.0, minf(cycle, 0.55 - cycle) * 12.0)
					_eye(Vector2(fposmod(base.x - cx * 0.6, wide) - 40.0, base.y + 10.0).round(), opening)
			"meteors":
				var cyc := fposmod(_t * 0.12 * sp + ph, 1.0)
				if cyc < 0.12:
					var k := cyc / 0.12
					var start := Vector2(fposmod(base.x * 1.3, size.x), base.y * 0.6)
					_meteor(start + Vector2(90.0, 40.0) * k, 1.0 - k)
			"spores":
				var x7 := fposmod(base.x + sin(_t * 0.7 * sp + ph) * 20.0 - cx * 0.5, wide) - 40.0
				var y7 := fposmod(base.y + size.y * 0.4 - _t * 6.0 * sp, size.y + 20.0) - 10.0
				var pulse := 0.5 + 0.5 * sin(_t * 2.0 * sp + ph)
				_dot(Vector2(x7, y7).round(), Color(light, 0.2 + 0.45 * pulse), 1 + big / 2)


func _dot(p: Vector2, c: Color, r: int) -> void:
	draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2 + 1, r * 2 + 1)), Color(c, c.a * 0.3))
	draw_rect(Rect2(p, Vector2(1, 1)), c)


# Ave de longe: um "v" que bate as asas (4 quadros).
func _bird(p: Vector2, f: int, big: int, crow: bool) -> void:
	var c := ink
	var w := 3 + big
	var up: int = [-2, -1, 0, -1][f]
	draw_rect(Rect2(p, Vector2(2, 1)), c)
	for i in w:
		var dy := roundf(float(up) * float(i + 1) / w)
		draw_rect(Rect2(p + Vector2(-1 - i, dy), Vector2(1, 1)), c)
		draw_rect(Rect2(p + Vector2(2 + i, dy), Vector2(1, 1)), c)
	if crow:
		draw_rect(Rect2(p + Vector2(0, 1), Vector2(2, 1)), c)


func _bat(p: Vector2, f: int) -> void:
	var c := ink
	draw_rect(Rect2(p, Vector2(2, 2)), c)
	if f == 0:
		draw_rect(Rect2(p + Vector2(-3, -1), Vector2(3, 1)), c)
		draw_rect(Rect2(p + Vector2(2, -1), Vector2(3, 1)), c)
		draw_rect(Rect2(p + Vector2(-4, -2), Vector2(1, 1)), c)
		draw_rect(Rect2(p + Vector2(5, -2), Vector2(1, 1)), c)
	else:
		draw_rect(Rect2(p + Vector2(-3, 1), Vector2(3, 1)), c)
		draw_rect(Rect2(p + Vector2(2, 1), Vector2(3, 1)), c)


func _leaf(p: Vector2, f: int) -> void:
	var c := Color(light, 0.55)
	match f:
		0:
			draw_rect(Rect2(p, Vector2(2, 1)), c)
		1:
			draw_rect(Rect2(p, Vector2(1, 2)), c)
		2:
			draw_rect(Rect2(p, Vector2(1, 1)), c)
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 1)), c)
		_:
			draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 1)), c)
			draw_rect(Rect2(p + Vector2(0, 1), Vector2(1, 1)), c)


func _fish(p: Vector2, dir: float, f: int, big: int) -> void:
	var c := ink
	var n := 4 + big * 2
	draw_rect(Rect2(p + Vector2(-n / 2.0, 0), Vector2(n, 2)), c)
	var tail := p + Vector2(-dir * (n / 2.0 + 1.0), 0)
	draw_rect(Rect2(tail + Vector2(0, -1 if f == 0 else 0), Vector2(1, 3 if f == 0 else 2)), c)


func _eye(p: Vector2, open: float) -> void:
	var h := maxf(1.0, roundf(3.0 * open))
	draw_rect(Rect2(p + Vector2(-3, -h * 0.5), Vector2(7, h)), Color(light, 0.35 * open))
	draw_rect(Rect2(p + Vector2(0, -h * 0.5 + (h - 1.0) * 0.5), Vector2(1, 1)), Color(0.05, 0.02, 0.0, 0.9 * open))


func _meteor(p: Vector2, a: float) -> void:
	for i in 10:
		var c := Color(light, a * (1.0 - i / 10.0))
		draw_rect(Rect2((p - Vector2(2.2, 1.0) * i).round(), Vector2(1, 1)), c)
	draw_rect(Rect2(p.round() - Vector2(1, 0), Vector2(3, 1)), Color(1, 1, 1, a))
