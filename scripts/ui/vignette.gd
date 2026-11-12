class_name Vignette
extends Node2D

# Cantos da tela um pouco mais escuros: puxa o olho para o centro, onde está
# o herói. Fica abaixo do HUD.

static var _tex: GradientTexture2D
static var _red: GradientTexture2D


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
	if _red == null:
		# herói ferido: as bordas da tela pulsam em vermelho (Fx.pain)
		var r := Gradient.new()
		r.set_color(0, Color(1, 0.1, 0.15, 0))
		r.set_color(1, Color(0.9, 0.05, 0.1, 0.75))
		r.add_point(0.55, Color(1, 0.1, 0.15, 0))
		_red = GradientTexture2D.new()
		_red.gradient = r
		_red.width = 128
		_red.height = 128
		_red.fill = GradientTexture2D.FILL_RADIAL
		_red.fill_from = Vector2(0.5, 0.5)
		_red.fill_to = Vector2(1.0, 1.0)


func _process(delta: float) -> void:
	if Fx.pain > 0.0:
		Fx.pain = maxf(Fx.pain - delta * 2.2, 0.0)
		queue_redraw()


func _draw() -> void:
	var screen := Rect2(Vector2.ZERO, get_viewport_rect().size)
	draw_texture_rect(_tex, screen, false)
	if Fx.pain > 0.0:
		draw_texture_rect(_red, screen, false, Color(1, 1, 1, Fx.pain))
