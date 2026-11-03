class_name Backdrop
extends Node2D

# Fundo com duas camadas de colunas em paralaxe. Fica numa CanvasLayer
# atrás de tudo e desenha em coordenadas de tela.

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var at := cam.get_screen_center_position() if cam else Vector2.ZERO

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
