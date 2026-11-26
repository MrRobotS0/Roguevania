class_name Stack
extends RefCounted

# Sprite stacking: um objeto em 3D feito de fatias horizontais finas (cada
# uma é o objeto visto de cima, numa altura), desenhadas uma em cima da outra
# com 1 px de diferença. Girar todas as fatias juntas gira o objeto em 3D de
# verdade, sem modelo 3D nem quadros desenhados para cada ângulo.
#
#   tilt: quanto da vista de cima aparece (0 = de lado puro; 0.5 = 3/4).
#   As fatias de baixo saem mais escuras: é isso que vira a lateral do objeto.
#
# Dois jeitos de montar:
#   from_voxels(w, h, d, cor(x, y, z))  y = 0 é a fatia do chão;
#   from_image(desenho, espessura)      cada linha do desenho vira uma fatia
#                                       (o desenho ganha corpo e gira como peça).

var texture: ImageTexture
var w := 1
var d := 1
var n := 1
var tops := PackedInt32Array()   # fatias que são tampa (mais claras)


static func from_voxels(sw: int, sh: int, sd: int, color: Callable) -> Stack:
	var img := Image.create(sw * sh, sd, false, Image.FORMAT_RGBA8)
	for y in sh:
		for z in sd:
			for x in sw:
				var c: Color = color.call(x, y, z)
				if c.a > 0.0:
					img.set_pixel(y * sw + x, z, c)
	var s := Stack.new()
	s.w = sw
	s.d = sd
	s.n = sh
	s.texture = ImageTexture.create_from_image(img)
	return s


static func from_image(src: Image, depth := 2) -> Stack:
	var img := src.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var sw := img.get_width()
	var sh := img.get_height()
	return from_voxels(sw, sh, depth, func(x: int, y: int, z: int) -> Color:
		var c := img.get_pixel(x, sh - 1 - y)
		if c.a < 0.5:
			return Color(0, 0, 0, 0)
		# a face de trás é mais escura: de lado se vê a espessura
		return c if z == depth - 1 else c.darkened(0.45))


# Desenha a pilha com a base em `at` (coordenadas do `ci`).
func draw(ci: CanvasItem, at: Vector2, angle: float, tilt := 0.45, tint := Color.WHITE, outline := false) -> void:
	var base := at.round()
	if outline:
		# contorno escuro de 1 px, como o dos personagens: a pilha inteira
		# desenhada em preto, deslocada para os quatro lados, antes da cor
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			for i in n:
				var oxf := Transform2D(0.0, Vector2(1.0, tilt), 0.0, base + o + Vector2(0, -i)) * Transform2D(angle, Vector2.ZERO)
				ci.draw_set_transform_matrix(oxf)
				ci.draw_texture_rect_region(texture, Rect2(-w * 0.5, -d * 0.5, w, d), Rect2(i * w, 0, w, d), Color("0b0910"))
	for i in n:
		var k := 0.62 + 0.38 * float(i) / maxf(n - 1, 1)
		if i == n - 1:
			k = 1.12
		var c := Color(tint.r * k, tint.g * k, tint.b * k, tint.a)
		var xf := Transform2D(0.0, Vector2(1.0, tilt), 0.0, base + Vector2(0, -i)) * Transform2D(angle, Vector2.ZERO)
		ci.draw_set_transform_matrix(xf)
		ci.draw_texture_rect_region(texture, Rect2(-w * 0.5, -d * 0.5, w, d), Rect2(i * w, 0, w, d), c)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


# --- modelos -------------------------------------------------------------------

static var _cache := {}


# Moeda de ouro em pé (gira em volta do eixo de cima).
static func coin() -> Stack:
	if not _cache.has("coin"):
		var gold := Color("f2c14e")
		_cache["coin"] = from_voxels(7, 7, 2, func(x: int, y: int, _z: int) -> Color:
			var dx := x - 3
			var dy := y - 3
			var r2 := dx * dx + dy * dy
			if r2 > 10:
				return Color(0, 0, 0, 0)
			if r2 > 6:
				return gold.darkened(0.25)          # aro
			return gold.lightened(0.25) if (dx + dy) < 0 else gold)
	return _cache["coin"]


# Baú de madeira com cintas de ferro e fecho de ouro (a frente é z = D - 1:
# com o tilt, z maior fica mais embaixo na tela, mais perto de quem olha). `open` tira a tampa e
# mostra o ouro dentro. `cursed`: madeira roxa e ferro preto.
static func chest(open: bool, cursed: bool) -> Stack:
	var key := "chest_%s_%s" % [open, cursed]
	if _cache.has(key):
		return _cache[key]
	var wood := Color("6a3f8a") if cursed else Color("7a4a2c")
	var iron := Color("1c1620") if cursed else Color("3a3236")
	var lock := Color("c08fff") if cursed else Color("f2c14e")
	var W := 16
	var H := 12
	var D := 10
	var lid_from := 8
	_cache[key] = from_voxels(W, H, D, func(x: int, y: int, z: int) -> Color:
		var edge_x := x == 0 or x == W - 1
		var edge_z := z == 0 or z == D - 1
		var shell := edge_x or edge_z
		if open and y >= lid_from:
			return Color(0, 0, 0, 0)
		var lid_top := not open and y == H - 1
		if not shell and y > 0 and not lid_top:
			# por dentro: oco; aberto, o ouro aparece no alto
			if open and y == lid_from - 1:
				return Color("f2c14e") if (x + z) % 3 else Color("ffe28a")
			return Color(0, 0, 0, 0)
		var c := wood
		if (x + y * 3) % 5 == 0 and not edge_x:
			c = wood.darkened(0.18)                   # veio das tábuas
		if y == lid_from - 1:
			c = wood.darkened(0.35)                   # a fresta da tampa
		if x == 3 or x == W - 4 or y == 0 or (y == H - 1 and not open and (edge_x or edge_z)):
			c = iron                                  # cintas e borda
		if z == D - 1 and absi(x - W / 2) <= 1 and y >= lid_from - 3 and y <= lid_from:
			c = lock                                  # fecho na frente
		return c)
	return _cache[key]
