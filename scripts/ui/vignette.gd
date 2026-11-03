class_name Vignette
extends Node2D

# Cantos da tela um pouco mais escuros: puxa o olho para o centro, onde está
# o herói. Fica abaixo do HUD.

static var _tex: GradientTexture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0))
		g.set_color(1, Color(0.02, 0.01, 0.03, 0.55))
		g.add_point(0.62, Color(0, 0, 0, 0))
		_tex = GradientTexture2D.new()
		_tex.gradient = g
		_tex.width = 128
		_tex.height = 128
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 1.0)


func _draw() -> void:
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, get_viewport_rect().size), false)
