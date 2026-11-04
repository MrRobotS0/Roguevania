class_name SpriteSheet
extends RefCounted

# Folhas geradas por tools/gen_sprites.py: cada pixel guarda um ÍNDICE de
# paleta (vermelho = índice * 16 + 8), não uma cor. Aqui a folha é pintada
# com a paleta pedida (uma aparência, um inimigo) e guardada em cache.
# Também sai uma versão toda branca, para o piscar de dano.

static var _cache := {}
static var _meta := {}


static func meta(sheet: String) -> Dictionary:
	if not _meta.has(sheet):
		var text := FileAccess.get_file_as_string("res://assets/sprites/%s.json" % sheet)
		var parsed = JSON.parse_string(text)
		_meta[sheet] = parsed if parsed is Dictionary else {}
	return _meta[sheet]


static var _images := {}


# A folha já pintada, como Image (para ler pixels).
static func image(sheet: String, palette: PackedColorArray) -> Image:
	var key := _key(sheet, palette, false)
	if not _images.has(key):
		texture(sheet, palette)
	return _images[key]


static func _key(sheet: String, palette: PackedColorArray, white: bool) -> String:
	return "%s|%s|%s" % [sheet, ",".join(Array(palette).map(func(c: Color) -> String: return c.to_html())), white]


static func texture(sheet: String, palette: PackedColorArray, white := false) -> ImageTexture:
	var key := _key(sheet, palette, white)
	if _cache.has(key):
		return _cache[key]
	var src: Image = (load("res://assets/sprites/%s.png" % sheet) as Texture2D).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	var data := src.get_data()
	var painted := PackedByteArray()
	painted.resize(data.size())
	for i in range(0, data.size(), 4):
		if data[i + 3] < 128:
			continue
		var c := Color.WHITE if white else palette[mini(data[i] >> 4, palette.size() - 1)]
		painted[i] = c.r8
		painted[i + 1] = c.g8
		painted[i + 2] = c.b8
		painted[i + 3] = 255
	out.set_data(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8, painted)
	var tex := ImageTexture.create_from_image(out)
	_cache[key] = tex
	_images[key] = out
	return tex


# Sprite2D pronto para a folha: pés na origem, quadros de `size`.
static func make_sprite(sheet: String) -> Sprite2D:
	var m := meta(sheet)
	var size: int = m.get("size", 32)
	var s := Sprite2D.new()
	s.centered = false
	s.offset = Vector2(-size * 0.5, -size + 2)
	var rows := 0
	var cols := 1
	for a: Dictionary in m["anims"].values():
		rows = maxi(rows, int(a["row"]) + 1)
		cols = maxi(cols, int(a["frames"]))
	s.set_meta("cols", cols)
	s.set_meta("rows", rows)
	return s


static func set_frame(s: Sprite2D, sheet: String, anim: String, index: int) -> Vector2:
	var a: Dictionary = meta(sheet)["anims"].get(anim, meta(sheet)["anims"].values()[0])
	var n: int = a["frames"]
	var i := posmod(index, n)
	s.hframes = s.get_meta("cols")
	s.vframes = s.get_meta("rows")
	s.frame = int(a["row"]) * s.hframes + i
	# a última mão da lista é a da frente (a que segura a arma)
	var hands: Array = a["hands"][i] if i < a["hands"].size() else [[0, -12]]
	var hand: Array = hands[hands.size() - 1]
	return Vector2(hand[0], hand[1])


static func has_anim(sheet: String, anim: String) -> bool:
	return meta(sheet)["anims"].has(anim)


static func fps(sheet: String, anim: String) -> float:
	return float(meta(sheet)["anims"].get(anim, {}).get("fps", 8))


# Um quadro solto de uma folha de quadros w x h (objetos de cenário).
static func region_sprite(sheet: String, palette: PackedColorArray, anim: String, index := 0) -> Sprite2D:
	var m := meta(sheet)
	var fw := int(m.get("w", 32))
	var fh := int(m.get("h", 32))
	var s := Sprite2D.new()
	s.texture = texture(sheet, palette)
	s.centered = false
	s.region_enabled = true
	s.offset = Vector2(-fw * 0.5, -fh + 2)
	set_region(s, sheet, anim, index)
	return s


static func set_region(s: Sprite2D, sheet: String, anim: String, index: int) -> void:
	var m := meta(sheet)
	var fw := int(m.get("w", 32))
	var fh := int(m.get("h", 32))
	var a: Dictionary = m["anims"][anim]
	s.region_rect = Rect2(posmod(index, int(a["frames"])) * fw, int(a["row"]) * fh, fw, fh)
