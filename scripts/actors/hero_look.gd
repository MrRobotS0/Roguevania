class_name HeroLook
extends RefCounted

# Miniatura do herói parado, para menus (escolha de aparência, loja da Vigia).
# Usa as mesmas proporções do desenho do Player.

static func draw_figure(ci: CanvasItem, feet: Vector2, look: Dictionary, dim := false) -> void:
	var f := func(c: Color) -> Color: return c.darkened(0.55) if dim else c
	var parts := [
		[Rect2(-4, -7, 3, 7), look["hood"]],
		[Rect2(1, -7, 3, 7), look["hood"]],
		[Rect2(-5, -16, 10, 10), look["cloak"]],
		[Rect2(-5, -9, 10, 3), look["cloak_dark"]],
		[Rect2(-8, -16, 4, 2), look["scarf"]],
		[Rect2(-3, -17, 7, 2), look["scarf"]],
		[Rect2(-4, -22, 8, 6), look["hood"]],
	]
	for p in parts:
		var r: Rect2 = p[0]
		ci.draw_rect(Rect2(feet + r.position - Vector2(1, 1), r.size + Vector2(2, 2)), Color("0b0910"))
	for p in parts:
		var r: Rect2 = p[0]
		ci.draw_rect(Rect2(feet + r.position, r.size), f.call(p[1]))
	var eye: Color = look["hood"].lightened(0.25) if look["closed_eyes"] else look["eye"]
	ci.draw_rect(Rect2(feet + Vector2(1, -20), Vector2(2, 1)), f.call(eye))
