class_name CloudShadows
extends Node2D

# Sombra de nuvens passando pelo chão nos domínios a céu aberto.
#
# É uma luz que SUBTRAI (Light2D em BLEND_MODE_SUB) com uma textura de nuvem
# (ruído sem emenda; só os morros do ruído viram sombra, de borda macia).
# Luz só age na camada do mundo: escurece chão, blocos, personagens e
# objetos, nunca o céu pintado do fundo (que mora em outra camada) nem o que
# brilha sozinho (efeitos, emissão).
#
# Uma luz não repete a textura, então a textura dela já é o ruído repetido
# 2x2: cobre dois períodos para cada lado. A luz anda com o vento e, quando a
# câmera se afasta meio período, volta um período inteiro (o desenho se repete,
# o salto não aparece). Antes eram nove luzes lado a lado, e cada bloco pagava
# por até quatro delas em todos os pixels.

const OUTDOOR := {
	# força da sombra, vento (px/s)
	"mar_de_cinzas":     {"dark": 0.34, "wind": Vector2(14, 0)},
	"jardim_primordial": {"dark": 0.30, "wind": Vector2(9, 2)},
	"bosque":            {"dark": 0.36, "wind": Vector2(-11, 0)},
	"penhascos":         {"dark": 0.30, "wind": Vector2(18, 0)},
	"carcosa":           {"dark": 0.26, "wind": Vector2(6, 0)},
	"torre_babel":       {"dark": 0.30, "wind": Vector2(16, 0)},
}
const TEX := 128              # tamanho do ruído (um período)
const SCALE := 8.0            # cada pixel do ruído cobre 8 do mundo: período de 1024 px

static var _texture: ImageTexture

var biome_id := ""
var _wind := Vector2.ZERO
var _offset := Vector2.ZERO
var _light: PointLight2D


static func has_clouds(id: String) -> bool:
	return OUTDOOR.has(id)


static func texture() -> ImageTexture:
	if _texture == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.024
		noise.fractal_octaves = 3
		noise.seed = 11
		var one := noise.get_seamless_image(TEX, TEX)
		one.convert(Image.FORMAT_L8)
		# só os morros do ruído viram sombra; borda macia (sem pontilhado)
		var bytes := one.get_data()
		for i in bytes.size():
			bytes[i] = int(smoothstep(0.48, 0.62, bytes[i] / 255.0) * 255.0)
		one = Image.create_from_data(TEX, TEX, false, Image.FORMAT_L8, bytes)
		var tiled := Image.create(TEX * 2, TEX * 2, false, Image.FORMAT_L8)
		for y in 2:
			for x in 2:
				tiled.blit_rect(one, Rect2i(0, 0, TEX, TEX), Vector2i(x * TEX, y * TEX))
		_texture = ImageTexture.create_from_image(tiled)
	return _texture


func _ready() -> void:
	var cfg: Dictionary = OUTDOOR.get(biome_id, {})
	if cfg.is_empty():
		set_process(false)
		return
	_wind = cfg["wind"]
	_light = PointLight2D.new()
	_light.texture = texture()
	_light.texture_scale = SCALE
	_light.blend_mode = Light2D.BLEND_MODE_SUB
	_light.color = Color(1, 1, 1)
	_light.energy = float(cfg["dark"])
	_light.height = 2000.0          # de cima: o relevo quase não interfere
	_light.range_item_cull_mask = Depth.MUNDO | Depth.HEROI
	add_child(_light)


func _process(delta: float) -> void:
	_offset += _wind * delta
	var period := TEX * SCALE
	var cam := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
	# o centro da luz fica no múltiplo do período (deslocado pelo vento) mais perto da câmera
	_light.global_position = ((cam - _offset) / period).round() * period + _offset
