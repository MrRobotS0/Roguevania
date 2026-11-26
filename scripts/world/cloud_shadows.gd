class_name CloudShadows
extends Node2D

# Sombra de nuvens passando pelo chão nos domínios a céu aberto.
#
# É uma luz que SUBTRAI (Light2D em BLEND_MODE_SUB) com uma textura de nuvem
# (ruído sem emenda, só os morros do ruído viram sombra, de borda macia).
# Luz só age na camada do mundo: escurece chão, blocos, personagens e
# objetos, nunca o céu pintado do fundo (que mora em outra camada) nem o que
# brilha sozinho (efeitos, emissão).
#
# Uma luz não repete a textura, então são 3x3 luzes lado a lado, cada uma do
# tamanho de um período do ruído; elas andam com o vento e, quando passam de
# um período, voltam um período inteiro (como o ruído não tem emenda, o salto
# não aparece).

const OUTDOOR := {
	# força da sombra, vento (px/s)
	"mar_de_cinzas":     {"dark": 0.34, "wind": Vector2(14, 0)},
	"jardim_primordial": {"dark": 0.30, "wind": Vector2(9, 2)},
	"bosque":            {"dark": 0.36, "wind": Vector2(-11, 0)},
	"penhascos":         {"dark": 0.30, "wind": Vector2(18, 0)},
	"carcosa":           {"dark": 0.26, "wind": Vector2(6, 0)},
	"torre_babel":       {"dark": 0.30, "wind": Vector2(16, 0)},
}
const TEX := 256              # tamanho do ruído
const SCALE := 4.0            # cada pixel do ruído cobre 4 do mundo: período de 1024 px

static var _texture: NoiseTexture2D

var biome_id := ""
var _wind := Vector2.ZERO
var _offset := Vector2.ZERO
var _lights: Array[PointLight2D] = []


static func has_clouds(id: String) -> bool:
	return OUTDOOR.has(id)


static func texture() -> NoiseTexture2D:
	if _texture == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.012
		noise.fractal_octaves = 3
		noise.seed = 11
		var ramp := Gradient.new()
		# só os morros do ruído viram sombra; borda macia (sem pontilhado)
		ramp.set_color(0, Color(0, 0, 0))
		ramp.set_color(1, Color(1, 1, 1))
		ramp.set_offset(0, 0.48)
		ramp.set_offset(1, 0.62)
		_texture = NoiseTexture2D.new()
		_texture.width = TEX
		_texture.height = TEX
		_texture.seamless = true
		_texture.noise = noise
		_texture.color_ramp = ramp
	return _texture


func _ready() -> void:
	var cfg: Dictionary = OUTDOOR.get(biome_id, {})
	if cfg.is_empty():
		set_process(false)
		return
	_wind = cfg["wind"]
	for i in 9:
		var l := PointLight2D.new()
		l.texture = texture()
		l.texture_scale = SCALE
		l.blend_mode = Light2D.BLEND_MODE_SUB
		l.color = Color(1, 1, 1)
		l.energy = float(cfg["dark"])
		l.height = 2000.0          # de cima: o relevo quase não interfere
		add_child(l)
		_lights.append(l)


func _process(delta: float) -> void:
	_offset += _wind * delta
	var period := TEX * SCALE
	var cam := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
	# canto da grade de períodos que contém a câmera, deslocado pelo vento
	var base := ((cam - _offset) / period).floor() * period + _offset
	for i in 9:
		var cell := Vector2(i % 3 - 1, floori(i / 3.0) - 1)
		_lights[i].global_position = base + cell * period + Vector2(period, period) * 0.5
