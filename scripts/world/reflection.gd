class_name Reflection
extends Node2D

# Chão molhado: na frente de cada trecho de chão, o que está em cima (herói,
# inimigos, tochas, fundo) aparece espelhado, escurecido na cor do domínio,
# ondulando de leve e sumindo para baixo. Lê a própria tela já desenhada
# (hint_screen_texture), por isso fica acima dos personagens (z 7).
#
# A conta de quantos pixels da tela vale um pixel do mundo sai da derivada
# do UV (dFdy) dentro do shader: funciona em qualquer escala de tela e com a
# visão ampla, sem passar nada de fora.

const WET := {
	# cor da água/brilho, força, altura do reflexo (px)
	"catedral":     {"tint": "6fd6e0", "strength": 0.62, "depth": 18.0},
	"cavernas":     {"tint": "7a9cff", "strength": 0.5, "depth": 16.0},
	"ventre":       {"tint": "ff7a80", "strength": 0.45, "depth": 10.0},
	"observatorio": {"tint": "b8a0ff", "strength": 0.4, "depth": 12.0},
	"saloes":       {"tint": "a9c4ff", "strength": 0.34, "depth": 10.0},
}

const SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 tint = vec3(0.5, 0.8, 0.9);
uniform float strength = 0.35;
uniform float depth_px = 12.0;
uniform float time = 0.0;
uniform float face = 5.0;     // a face de cima do bloco (Room.TOP_FACE): o espelho começa acima dela
void fragment() {
	// pixels da tela por pixel do mundo (vertical): o retângulo tem depth_px de altura
	float per_uv = 1.0 / max(abs(dFdy(UV.y)), 1e-6);   // pixels da tela no retângulo todo
	float scale = per_uv / depth_px;
	float d = UV.y * depth_px;                         // px do mundo abaixo da linha
	float wx = SCREEN_UV.x / SCREEN_PIXEL_SIZE.x / scale;  // x em px do mundo (para a onda)
	// ondulação em pixel inteiro: mais forte longe da linha
	float wob = floor(sin(time * 2.1 + wx * 0.21 + d * 0.8) * (0.4 + d * 0.09) + 0.5);
	vec2 uv = SCREEN_UV;
	uv.y -= (2.0 * (floor(d) + 0.5) + face) * scale * SCREEN_PIXEL_SIZE.y;
	uv.x += wob * scale * SCREEN_PIXEL_SIZE.x;
	vec3 c = textureLod(screen_tex, clamp(uv, vec2(0.0), vec2(1.0)), 0.0).rgb;
	float fade = pow(1.0 - UV.y, 1.6) * strength * step(0.0, uv.y);
	// faixas de brilho que correm (a lâmina d'água pegando luz)
	float sheen = step(0.985, sin(wx * 0.07 - time * 0.9 + d * 0.15)) * 0.25 * (1.0 - UV.y);
	vec3 refl = mix(c, c * tint, 0.45) * 1.25;
	COLOR = vec4(refl + tint * sheen, fade + sheen * 0.5);
}
"""

static var _shader: Shader
static var _white: ImageTexture

var room: Room
var biome_id := ""
var _rects: Array[Rect2] = []
var _mat: ShaderMaterial
var _t := 0.0


static func is_wet(id: String) -> bool:
	return WET.has(id)


func _ready() -> void:
	z_index = 7
	var cfg: Dictionary = WET.get(biome_id, {})
	if cfg.is_empty() or room == null:
		set_process(false)
		return
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	var tint := Color(cfg["tint"])
	_mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	_mat.set_shader_parameter("strength", cfg["strength"])
	_mat.set_shader_parameter("depth_px", cfg["depth"])
	_mat.set_shader_parameter("face", float(Room.TOP_FACE))
	material = _mat
	_build(float(cfg["depth"]))


# Trechos de chão: blocos sólidos com ar em cima, juntados na horizontal.
func _build(depth: float) -> void:
	for y in range(1, room.rows):
		var start := -1
		for x in room.cols + 1:
			var floor_here := x < room.cols and _solid(x, y) and not _solid(x, y - 1)
			if floor_here and start < 0:
				start = x
			elif not floor_here and start >= 0:
				if x - start >= 2:
					_rects.append(Rect2(start * Room.TILE, y * Room.TILE, (x - start) * Room.TILE, depth))
				start = -1


func _solid(x: int, y: int) -> bool:
	var c := room.cell(x, y)
	return c == Room.SOLID or c == Room.CRACKED


func _process(delta: float) -> void:
	_t += delta
	_mat.set_shader_parameter("time", _t)
	queue_redraw()


func _draw() -> void:
	var xf := get_viewport().get_canvas_transform().affine_inverse()
	var view := Rect2(xf * Vector2.ZERO, xf.basis_xform(get_viewport_rect().size)).grow(8.0)
	for r in _rects:
		if r.intersects(view):
			draw_texture_rect(_white, r, false)
