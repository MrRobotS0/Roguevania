class_name HeroLook
extends RefCounted

# Paleta do herói a partir de uma aparência, na mesma ordem de índices que
# tools/gen_sprites.py usa para desenhar a folha "hero".

const OUTLINE := Color("0b0910")


static func palette(look: Dictionary) -> PackedColorArray:
	var cloak: Color = look["cloak"]
	var hood: Color = look["hood"]
	var scarf: Color = look["scarf"]
	var eye: Color = hood.lightened(0.3) if look["closed_eyes"] else look["eye"]
	return PackedColorArray([
		Color(0, 0, 0, 0), OUTLINE,
		cloak.lightened(0.22), cloak, look["cloak_dark"],
		hood.lightened(0.3), hood, hood.darkened(0.4),
		eye,
		scarf.lightened(0.25), scarf, scarf.darkened(0.3),
		Color("0e0b12"), Color("2a2230"), Color("3d3346"), Color("c9a24a"),
	])


# Miniatura do herói parado (escolha de aparência, loja da Vigia).
static func draw_figure(ci: CanvasItem, feet: Vector2, look: Dictionary, dim := false) -> void:
	var sheet := Player.SHEET
	var m := SpriteSheet.meta(sheet)
	var tex := SpriteSheet.texture(sheet, palette(look))
	var a: Dictionary = m["anims"]["idle"]
	var fw := float(m.get("w", 32))
	var fh := float(m.get("h", 32))
	# só o recorte em volta do corpo, reduzido para caber na linha do menu
	var src := Rect2(fw * 0.5 - 24.0, int(a["row"]) * fh + fh - 50.0, 48, 48)
	ci.draw_texture_rect_region(tex, Rect2(feet + Vector2(-16, -30), Vector2(32, 32)), src,
		Color(0.45, 0.45, 0.5) if dim else Color.WHITE)
