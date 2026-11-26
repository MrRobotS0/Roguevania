class_name Vfx
extends Sprite2D

# Efeito animado em pixel art desenhado à mão (pacote CC0 "Free Pixel Effects
# Pack", de CodeManu e Davit Masia), importado por tools/importar_efeitos.py
# para assets/sprites/vfx_<nome>.png (tira horizontal) + vfx.json.
#
# Não recebe a luz da fase (é luz: fogo, impacto, alma) e fica por cima de
# quem apanhou. Os de uma vez somem no fim; os de laço (fogo da queimadura)
# ficam até alguém tirá-los.

static var _meta := {}
static var _textures := {}

var effect := ""
var speed := 1.0
var loop := false
var _t := 0.0
var _frames := 1
var _fps := 20.0


static func info(name: String) -> Dictionary:
	if _meta.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/vfx.json"))
		_meta = parsed if parsed is Dictionary else {"_": {}}
	return _meta.get(name, {})


static func make(name: String, speed_scale := 1.0, looping := false) -> Vfx:
	var m := info(name)
	if m.is_empty():
		return null
	var v := Vfx.new()
	v.effect = name
	v.speed = speed_scale
	v.loop = looping
	if not _textures.has(name):
		_textures[name] = load("res://assets/sprites/vfx_%s.png" % name)
	v.texture = _textures[name]
	v._frames = int(m["frames"])
	v._fps = float(m["fps"])
	v.hframes = v._frames
	v.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	v.material = mat
	v.z_index = 9
	return v


func _process(delta: float) -> void:
	_t += delta * speed
	var f := int(_t * _fps)
	if f >= _frames:
		if not loop:
			queue_free()
			return
		f = f % _frames
	frame = f
