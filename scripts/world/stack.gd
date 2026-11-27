class_name Stack
extends RefCounted

# Sprite stacking: um objeto em 3D feito de fatias horizontais finas (cada uma é o
# objeto visto de cima, numa altura), empilhadas com 1 px de diferença. Girar as
# fatias juntas gira o objeto em 3D, sem modelo 3D nem quadros desenhados à mão.
#
# As pilhas vêm prontas de tools/gen_pilhas.py: cada objeto é uma tira com o giro
# completo em 32 quadros, já rasterizados na grade do jogo (com contorno e a
# lateral mais escura). Aqui só se escolhe o quadro do ângulo. Girar as fatias na
# hora, na placa de vídeo, saía fora da grade na câmera lisa: baú serrilhado e
# item do pedestal virando um rabisco quando ficava de lado.
#
#   Stack.of("bau").draw(self, base, angulo)
#
# Nomes: bau, bau_aberto, bau_maldito, bau_maldito_aberto, moeda, planta e
# item_<id> para cada ícone de assets/icons/<id>_16.png.

static var _atlas: Texture2D
static var _items := {}
static var _frames := 32
static var _cache := {}

var _strip := Rect2()        # o primeiro quadro da tira, no atlas
var _origin := Vector2.ZERO  # onde fica o centro da base dentro do quadro


static func of(name: String) -> Stack:
	if _atlas == null:
		var tex: Texture2D = load("res://assets/sprites/pilhas.png")
		_atlas = SpriteSheet.lit("pilhas", tex)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/pilhas.json"))
		if parsed is Dictionary:
			_items = parsed.get("itens", {})
			_frames = int(parsed.get("frames", 32))
	if not _cache.has(name):
		var s: Stack = null
		if _items.has(name):
			var m: Dictionary = _items[name]
			s = Stack.new()
			s._strip = Rect2(float(m["x"]), float(m["y"]), float(m["w"]), float(m["h"]))
			s._origin = Vector2(float(m["ox"]), float(m["oy"]))
		_cache[name] = s
	return _cache[name]


# Desenha com o centro da base em `at` (coordenadas do `ci`), girado de `angle`.
func draw(ci: CanvasItem, at: Vector2, angle: float, tint := Color.WHITE) -> void:
	var frame := posmod(roundi(angle / TAU * _frames), _frames)
	var src := Rect2(_strip.position + Vector2(frame * _strip.size.x, 0), _strip.size)
	ci.draw_texture_rect_region(_atlas, Rect2(at.round() - _origin, _strip.size), src, tint)
