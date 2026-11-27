class_name FrontDust
extends Node2D

# Poeira fora de foco passando na frente da câmera: discos grandes, moles e
# quase transparentes, que andam mais que o mundo quando a câmera anda
# (paralaxe > 1). É o plano mais perto de quem olha: com o fundo pintado, a
# parede e as silhuetas do primeiro plano, fecha a profundidade.
# Coordenadas de tela (CanvasLayer), somada por cima, sem luz. A quantidade vem
# de Graficos ("poeira_frente"); some com os efeitos de tela desligados.

const MARGIN := 40.0

var tint := Color(1.0, 0.9, 0.75)
var _motes: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	Graficos.changed.connect(_seed)
	_seed()


func _seed() -> void:
	_motes.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in int(Graficos.num("poeira_frente")):
		_motes.append({
			"at": Vector2(rng.randf() * 560.0, rng.randf() * 350.0),
			"drift": Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-5.0, -1.0)),
			"size": rng.randf_range(7.0, 20.0),
			"depth": rng.randf_range(1.3, 2.1),
			"alpha": rng.randf_range(0.045, 0.1),
			"phase": rng.randf() * TAU,
		})
	set_process(not _motes.is_empty())
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if _motes.is_empty():
		return
	var cam := get_viewport().get_camera_2d()
	var scroll := cam.get_screen_center_position() if cam else Vector2.ZERO
	var span := get_viewport_rect().size + Vector2(MARGIN, MARGIN) * 2.0
	var tex := Glow.texture()
	for m in _motes:
		var depth: float = m["depth"]
		var from: Vector2 = m["at"]
		var drift: Vector2 = m["drift"]
		var r: float = m["size"]
		var phase: float = m["phase"]
		var alpha: float = m["alpha"]
		var p := from + drift * _t - scroll * depth
		p = Vector2(fposmod(p.x, span.x), fposmod(p.y, span.y)) - Vector2(MARGIN, MARGIN)
		draw_texture_rect(tex, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false,
			Color(tint.r, tint.g, tint.b, alpha * (0.7 + 0.3 * sin(_t * 0.6 + phase))))
