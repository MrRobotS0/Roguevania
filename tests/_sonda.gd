extends Node

func _ready() -> void:
	var m := SpriteSheet.meta("hero_g")
	var fw := int(m["w"])
	var fh := int(m["h"])
	var row := int(m["anims"]["run"]["row"])
	var out := Image.create(fw * 7, fh, false, Image.FORMAT_RGBA8)
	out.fill(Color("2a2430"))
	var k := 0
	for s in Catalog.skins():
		var img := SpriteSheet.image("hero_g", HeroLook.palette(s.colors()))
		out.blend_rect(img, Rect2i(2 * fw, row * fh, fw, fh), Vector2i(k * fw, 0))
		k += 1
	var c := Catalog.skin("andarilho")
	var img2 := SpriteSheet.image("hero_g", HeroLook.palette(c.colors("geada")))
	out.blend_rect(img2, Rect2i(2 * fw, row * fh, fw, fh), Vector2i(k * fw, 0))
	out.resize(out.get_width() * 2, out.get_height() * 2, Image.INTERPOLATE_NEAREST)
	out.save_png(ProjectSettings.globalize_path("res://tools/previews/_skins_g.png"))
	get_tree().quit()
