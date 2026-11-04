class_name HudSkin
extends RefCounted

# A pele do HUD de um domínio: peças recortadas de kits de interface (CC0) e
# recoloridas por tools/importar_hud.py em assets/sprites/hud_<domínio>.png,
# com as medidas no .json ao lado.
#   panel   caixa de 9 fatias          bar/boss  moldura com miolo (inner)
#   header  fita atrás de um título    slot      moldura de equipamento
#   gem     enfeite ao lado da vida

const FALLBACK := "mar_de_cinzas"

static var _cache := {}

var id := ""
var tex: Texture2D
var meta := {}
var _panel: StyleBoxTexture


static func of(domain: String) -> HudSkin:
	var key := domain if FileAccess.file_exists("res://assets/sprites/hud_%s.json" % domain) else FALLBACK
	if not _cache.has(key):
		var s := HudSkin.new()
		s._load(key)
		_cache[key] = s
	return _cache[key]


func _load(key: String) -> void:
	id = key
	tex = load("res://assets/sprites/hud_%s.png" % key)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/hud_%s.json" % key))
	meta = parsed if parsed is Dictionary else {}
	var p: Dictionary = meta.get("panel", {})
	_panel = StyleBoxTexture.new()
	_panel.texture = tex
	_panel.region_rect = _rect(p)
	var m := float(p.get("margin", 6))
	_panel.texture_margin_left = m
	_panel.texture_margin_right = m
	_panel.texture_margin_top = m
	_panel.texture_margin_bottom = m


static func _rect(part: Dictionary) -> Rect2:
	var r: Array = part.get("rect", [0, 0, 1, 1])
	return Rect2(r[0], r[1], r[2], r[3])


func color(key: String) -> Color:
	return Color(String(meta.get(key, "ffffff")))


func part_size(part: String) -> Vector2:
	return _rect(meta.get(part, {})).size


# Caixa em volta de `content` (a moldura fica por fora, a `pad` pixels).
func panel(ci: CanvasItem, content: Rect2, alpha := 1.0, pad := 4.0) -> void:
	_panel.modulate_color = Color(1, 1, 1, alpha)
	ci.draw_style_box(_panel, content.grow(pad))


# Peça horizontal esticada até `width`: tampas, meio repetido e o enfeite do
# centro. Devolve o miolo, onde a barra é pintada (vazio para a fita).
func hbar(ci: CanvasItem, part: String, at: Vector2, width: float, alpha := 1.0) -> Rect2:
	var p: Dictionary = meta.get(part, {})
	var r := _rect(p)
	var mod := Color(1, 1, 1, alpha)
	var left := float(p.get("left", 4))
	var right := float(p.get("right", 4))
	width = maxf(width, left + right + 1.0)
	var h := r.size.y
	ci.draw_texture_rect_region(tex, Rect2(at, Vector2(left, h)), Rect2(r.position, Vector2(left, h)), mod)
	var mid := float(p.get("mid", left))
	ci.draw_texture_rect_region(tex, Rect2(at + Vector2(left, 0), Vector2(width - left - right, h)), Rect2(r.position + Vector2(mid, 0), Vector2(1, h)), mod)
	ci.draw_texture_rect_region(tex, Rect2(at + Vector2(width - right, 0), Vector2(right, h)), Rect2(r.position + Vector2(r.size.x - right, 0), Vector2(right, h)), mod)
	var center: Variant = p.get("center")
	if center is Array:
		var cx := float(center[0])
		var cw := float(center[1])
		ci.draw_texture_rect_region(tex, Rect2(at + Vector2(roundf((width - cw) * 0.5), 0), Vector2(cw, h)), Rect2(r.position + Vector2(cx, 0), Vector2(cw, h)), mod)
	return inner_of(part, at, width)


# Onde a barra é pintada dentro da moldura (sem desenhar nada).
func inner_of(part: String, at: Vector2, width: float) -> Rect2:
	var p: Dictionary = meta.get(part, {})
	var inner: Variant = p.get("inner")
	if inner is Array:
		return Rect2(at.x + float(inner[0]), at.y + float(inner[1]), width - float(inner[0]) - float(inner[2]), float(inner[3]))
	return Rect2(at, Vector2(width, height(part)))


func height(part: String) -> float:
	return part_size(part).y


# Moldura de equipamento no tamanho original, com o canto em `at`. Devolve
# o miolo (onde vai o ícone e a sombra da recarga).
func slot(ci: CanvasItem, at: Vector2) -> Rect2:
	var p: Dictionary = meta.get("slot", {})
	var r := _rect(p)
	ci.draw_texture_rect_region(tex, Rect2(at, r.size), r)
	var inner: Variant = p.get("inner")
	if inner is Array:
		return Rect2(at.x + float(inner[0]), at.y + float(inner[1]), float(inner[2]), float(inner[3]))
	return Rect2(at + Vector2(4, 4), r.size - Vector2(8, 8))


func gem(ci: CanvasItem, at: Vector2) -> void:
	var r := _rect(meta.get("gem", {}))
	ci.draw_texture_rect_region(tex, Rect2(at, r.size), r)
