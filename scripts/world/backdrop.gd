class_name Backdrop
extends Node2D

# Fundo em paralaxe, desenhado em coordenadas de tela (fica numa CanvasLayer).
# Cada bioma escolhe um estilo; as cores vêm do BiomeData.sky.
#   "dunes":   céu de cinza, sol pálido, colossos em ruína e três camadas de dunas
#   "columns": colunas escuras (sala de treino / padrão)

var style := "columns"
var layers := "bd"
var sky := {}
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _c(key: String, fallback: Color) -> Color:
	return sky.get(key, fallback)


func _draw() -> void:
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var at := cam.get_screen_center_position() if cam else Vector2.ZERO
	match style:
		"dunes", "painted":
			_dunes(size, at)
		_:
			_columns_bg(size, at)


# Camadas pintadas por tools/gen_backdrop.py (índices de paleta), pintadas
# aqui com as cores do bioma. Céu parado; as outras andam em paralaxe e
# repetem na horizontal.
const LAYERS := [["bd_far", 0.08, 0.04], ["bd_mid", 0.22, 0.1], ["bd_near", 0.45, 0.18]]

var _painted := {}
var _painted_for := {}


func _layer(name: String) -> ImageTexture:
	if _painted_for != sky:
		_painted.clear()
		_painted_for = sky.duplicate()
	var file := layers + name.trim_prefix("bd")
	if not _painted.has(file):
		_painted[file] = SpriteSheet.texture(file, _palette())
	return _painted[file]


func _palette() -> PackedColorArray:
	var s0 := _c("sky0", Palette.SKY_0)
	var s1 := _c("sky1", Palette.SKY_1)
	var glow := _c("glow", Palette.SKY_GLOW)
	var sun := _c("sun", Color.WHITE)
	var far_body := s1.lerp(glow, 0.35)
	var mid_body := s1.lerp(s0, 0.15)
	var near_body := s0.darkened(0.35)
	return PackedColorArray([
		Color(0, 0, 0, 0), s0, s0.lerp(s1, 0.6), s1.lerp(glow, 0.45), glow,
		sun, sun.lerp(glow, 0.45), glow.lerp(sun, 0.25),
		far_body, far_body.lerp(sun, 0.25),
		mid_body, mid_body.lerp(glow, 0.5), mid_body.darkened(0.25),
		near_body, near_body.lerp(glow, 0.35),
		glow.lerp(sun, 0.15),
	])


func _dunes(size: Vector2, at: Vector2) -> void:
	draw_texture(_layer("bd_sky"), Vector2.ZERO)
	for l in LAYERS:
		var tex := _layer(l[0])
		var lw := float(tex.get_width())
		var x0 := -fposmod(at.x * float(l[1]), lw)
		var y0 := clampf(-(at.y - 400.0) * float(l[2]), -30.0, 30.0)
		x0 = floorf(x0)
		y0 = floorf(y0)
		draw_texture(tex, Vector2(x0, y0))
		draw_texture(tex, Vector2(x0 + lw, y0))
		if y0 < 0.0:
			# o pé da camada não pode deixar buraco embaixo
			draw_rect(Rect2(0, size.y + y0 - 1, size.x, -y0 + 1), SpriteSheet.image(layers + String(l[0]).trim_prefix("bd"), _palette()).get_pixel(0, tex.get_height() - 1))
	# cinza caindo devagar
	var ash := _c("sun", Color.WHITE)
	ash.a = 0.18
	for i in 40:
		var px := fposmod(i * 97.0 - _t * (8.0 + i % 5) - at.x * 0.3, size.x)
		var py := fposmod(i * 53.0 + _t * (12.0 + i % 7), size.y)
		draw_rect(Rect2(px, py, 1, 1), ash)


func _columns_bg(size: Vector2, at: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.SKY_0)
	for i in 6:
		var band := Palette.SKY_0.lerp(Palette.SKY_GLOW, i / 10.0)
		draw_rect(Rect2(0, size.y - 90 + i * 15, size.x, 15), band)
	_columns(at * 0.15, 72.0, 18.0, Palette.SKY_1, size, 30.0, true)
	_columns(at * 0.4, 120.0, 34.0, Palette.SKY_2, size, 60.0, false)


func _columns(scroll: Vector2, spacing: float, width: float, color: Color, size: Vector2, top: float, windows: bool) -> void:
	var first := floori(scroll.x / spacing) - 1
	var y0 := top - scroll.y * 0.2
	for i in range(first, first + int(size.x / spacing) + 3):
		var x := floorf(i * spacing - scroll.x)
		var h_off := float(absi(i * 37) % 30)
		draw_rect(Rect2(x, y0 + h_off, width, size.y - y0 - h_off + 200.0), color)
		draw_rect(Rect2(x - 3, y0 + h_off, width + 6, 4), color.lightened(0.06))
		if windows and absi(i * 53) % 3 == 0:
			var glow := Palette.WINDOW
			glow.a = 0.55
			draw_rect(Rect2(x + width * 0.5 - 2, y0 + h_off + 22, 4, 7), glow)
