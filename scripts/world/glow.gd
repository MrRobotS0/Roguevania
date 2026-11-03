class_name Glow
extends RefCounted

# Luz de verdade (PointLight2D) presa a um nó. O mundo fica um pouco escuro
# (CanvasModulate da fase) e as luzes devolvem a cor perto delas: fogo,
# Essência, colunas de luz, o próprio herói.

static var _texture: GradientTexture2D


static func texture() -> GradientTexture2D:
	if _texture == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.45))
		_texture = GradientTexture2D.new()
		_texture.gradient = g
		_texture.width = 128
		_texture.height = 128
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
	return _texture


static func attach(parent: Node2D, color: Color, radius: float, energy: float, offset := Vector2.ZERO) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = texture()
	light.texture_scale = radius * 2.0 / 128.0
	light.color = color
	light.energy = energy
	light.position = offset
	parent.add_child(light)
	return light
