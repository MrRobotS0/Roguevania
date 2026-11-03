class_name Backdrop
extends Node2D

# Fundo em paralaxe, desenhado em coordenadas de tela (fica numa CanvasLayer).
# Cada bioma escolhe um estilo; as cores vêm do BiomeData.sky.
#   "dunes":   céu de cinza, sol pálido, colossos em ruína e três camadas de dunas
#   "columns": colunas escuras (sala de treino / padrão)

var style := "columns"
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
		"dunes":
			_dunes(size, at)
		_:
			_columns_bg(size, at)


func _gradient(size: Vector2, top: Color, bottom: Color, bands := 12) -> void:
	var bh := ceilf(size.y / bands)
	for i in bands:
		draw_rect(Rect2(0, i * bh, size.x, bh), top.lerp(bottom, float(i) / (bands - 1)))


func _dunes(size: Vector2, at: Vector2) -> void:
	var top := _c("sky0", Palette.SKY_0)
	var glow := _c("glow", Palette.SKY_GLOW)
	_gradient(size, top, glow)
	# sol pálido atrás da cinza
	var sun := _c("sun", Color.WHITE)
	var sp := Vector2(size.x * 0.72 - at.x * 0.02, 70.0 - at.y * 0.02)
	for r in [26, 20, 15]:
		var c := sun
		c.a = 0.08 if r == 26 else (0.15 if r == 20 else 0.75)
		draw_circle(sp, r, c)
	# colossos: estátuas quebradas e meio enterradas, bem ao fundo
	var far := _c("sky1", Palette.SKY_1)
	var scroll := at.x * 0.08
	for i in range(-1, 4):
		var x := floorf(i * 260.0 - fposmod(scroll, 260.0))
		var base := size.y - 70.0 - at.y * 0.05
		draw_rect(Rect2(x + 40, base - 110, 34, 110), far)
		draw_rect(Rect2(x + 34, base - 128, 46, 22), far)
		draw_rect(Rect2(x + 44, base - 140, 8, 14), far)
		draw_rect(Rect2(x + 74, base - 90, 30, 10), far)
	# três camadas de dunas, com névoa de cinza entre elas: quanto mais longe,
	# mais apagado. A última fica escura para o cenário jogável se destacar.
	_haze(size, size.y - 150.0, glow, 0.22)
	_dune_layer(size, at, 0.15, size.y - 95.0, 30.0, 0.011, far.lerp(glow, 0.35))
	_haze(size, size.y - 110.0, glow, 0.16)
	_dune_layer(size, at, 0.3, size.y - 70.0, 24.0, 0.017, _c("sky2", Palette.SKY_2).lerp(glow, 0.15))
	_haze(size, size.y - 80.0, top, 0.25)
	_dune_layer(size, at, 0.5, size.y - 40.0, 18.0, 0.023, _c("sky2", Palette.SKY_2).darkened(0.5))
	# cinza caindo devagar
	for i in 40:
		var px := fposmod(i * 97.0 - _t * (8.0 + i % 5) - at.x * 0.3, size.x)
		var py := fposmod(i * 53.0 + _t * (12.0 + i % 7), size.y)
		var c := sun
		c.a = 0.18
		draw_rect(Rect2(px, py, 1, 1), c)


func _haze(size: Vector2, from_y: float, color: Color, alpha: float) -> void:
	var bands := 6
	for i in bands:
		var c := color
		c.a = alpha * (1.0 - float(i) / bands)
		draw_rect(Rect2(0, from_y + i * 10.0, size.x, size.y - from_y - i * 10.0), c)


func _dune_layer(size: Vector2, at: Vector2, parallax: float, base: float, amp: float, freq: float, color: Color) -> void:
	var off := at.x * parallax
	var y0 := base - at.y * parallax * 0.25
	var step := 4.0
	var x := 0.0
	while x < size.x:
		var wx := x + off
		var hgt := sin(wx * freq) * amp + sin(wx * freq * 2.3 + 1.7) * amp * 0.35
		draw_rect(Rect2(x, y0 - hgt, step, size.y - y0 + hgt), color)
		x += step


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
