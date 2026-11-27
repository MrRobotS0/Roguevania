class_name Glow
extends RefCounted

# Luz de verdade (PointLight2D) presa a um nó. O mundo fica um pouco escuro
# (CanvasModulate da fase) e as luzes devolvem a cor perto delas: fogo,
# Essência, colunas de luz, o próprio herói.

static var _texture: GradientTexture2D
static var _add: CanvasItemMaterial


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


# Halo: o mesmo degradê somado por cima da cena, sem ser luz. Não acende o chão em
# volta, mas também não pesa: cada luz de verdade é calculada em todos os pixels dos
# blocos que ela toca, e um abate solta uma dúzia de moedas e essências de uma vez.
static func halo(parent: Node2D, color: Color, radius: float, strength: float, offset := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture()
	s.scale = Vector2.ONE * radius * 2.0 / 128.0
	s.position = offset
	s.modulate = Color(color.r, color.g, color.b, strength)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.show_behind_parent = true
	if _add == null:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	s.material = _add
	parent.add_child(s)
	return s


static func attach(parent: Node2D, color: Color, radius: float, energy: float, offset := Vector2.ZERO) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = texture()
	light.texture_scale = radius * 2.0 / 128.0
	light.color = color
	light.energy = energy
	light.position = offset
	# acima do plano: com o relevo, acende o lado das coisas que olha para ela
	light.height = radius * 0.4
	parent.add_child(light)
	return light
