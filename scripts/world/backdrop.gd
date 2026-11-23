class_name Backdrop
extends Node2D

# Fundo em paralaxe, desenhado em coordenadas de tela (fica numa CanvasLayer).
# Cada bioma escolhe um estilo; as cores vêm do BiomeData.sky.
#   "dunes":   céu de cinza, sol pálido, colossos em ruína e três camadas de dunas
#   "columns": colunas escuras (sala de treino / padrão)

var style := "columns"
var layers := "bd"
var sky := {}
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _c(key: String, fallback: Color) -> Color:
	return sky.get(key, fallback)


func _draw() -> void:
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var at := cam.get_screen_center_position() if cam else _idle_view(size)
	var painted := style in ["dunes", "painted"]
	for c in get_children():
		(c as CanvasItem).visible = painted
	match style:
		"dunes", "painted":
			_dunes(size, at)
		_:
			_columns_bg(size, at)


# Sem câmera (o título): a vista anda sozinha, devagar, e segue um pouco o
# mouse. As camadas andam em velocidades diferentes, e é isso que mostra a
# distância entre elas.
var _look := Vector2.ZERO


func _idle_view(size: Vector2) -> Vector2:
	var want := Vector2.ZERO
	if Options.get_value("postfx"):
		var m := get_viewport().get_mouse_position() / size - Vector2(0.5, 0.5)
		want = m.clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5)) * Vector2(160.0, 80.0)
	_look = _look.lerp(want, clampf(get_process_delta_time() * 2.5, 0.0, 1.0))
	return Vector2(_t * 9.0, 400.0) + _look


# Camadas pintadas por tools/gen_backdrop.py (índices de paleta), pintadas
# aqui com as cores do bioma. Céu parado; as outras andam em paralaxe e
# repetem na horizontal.
const LAYERS := [["bd_far", 0.08, 0.04], ["bd_mid", 0.22, 0.1], ["bd_near", 0.45, 0.18]]

var _painted := {}
var _painted_for := {}
var _painted_layers := ""
var _feet := {}


# Prefere o fundo em cor cheia (tools/pintar_fundos.py); sem ele, pinta a
# silhueta antiga com as cores do bioma.
func _layer(name: String) -> Texture2D:
	if _painted_for != sky or _painted_layers != layers:
		_painted.clear()
		_painted_for = sky.duplicate()
		_painted_layers = layers
	var file := layers + name.trim_prefix("bd")
	if not _painted.has(file):
		var full := "res://assets/sprites/%s_cor%s.png" % [layers, name.trim_prefix("bd")]
		if ResourceLoader.exists(full):
			_painted[file] = load(full)
		else:
			_painted[file] = SpriteSheet.texture(file, _palette())
	return _painted[file]


# Cor da última linha da camada (preenche embaixo quando a câmera sobe).
func _foot(tex: Texture2D) -> Color:
	if not _feet.has(tex):
		var img := tex.get_image()
		_feet[tex] = img.get_pixel(0, img.get_height() - 1) if img else Color.BLACK
	return _feet[tex]


func _palette() -> PackedColorArray:
	var s0 := _c("sky0", Palette.SKY_0)
	var s1 := _c("sky1", Palette.SKY_1)
	var glow := _c("glow", Palette.SKY_GLOW)
	var sun := _c("sun", Color.WHITE)
	var far_body := s1.lerp(glow, 0.35)
	var mid_body := s1.lerp(s0, 0.15)
	var near_body := s0.darkened(0.35)
	return PackedColorArray([
		Color(0, 0, 0, 0), s0, s0.lerp(s1, 0.6), s1.lerp(glow, 0.45), glow,
		sun, sun.lerp(glow, 0.45), glow.lerp(sun, 0.25),
		far_body, far_body.lerp(sun, 0.25),
		mid_body, mid_body.lerp(glow, 0.5), mid_body.darkened(0.25),
		near_body, near_body.lerp(glow, 0.35),
		glow.lerp(sun, 0.15),
	])


# Cada camada pintada é um nó próprio (BackLayer) com vida: nuvens que andam
# sozinhas, mata que balança, água que ondula, calor que tremula, carne que
# pulsa, e a névoa da distância (a de longe some no ar). Entre a camada de
# longe e a do meio passa a fauna do domínio (Fauna). O que cada domínio faz:
#   drift: px/s andando sozinha   bob: px de respiração   sway: px de balanço no alto
#   heat: tremor de calor          wave: ondulação de água  glow: pulso de luz
#   fog: quanto a névoa da distância cobre a camada
const LIFE := {
	"mar_de_cinzas": {"far": {"drift": 3.0, "fog": 0.30}, "mid": {"bob": 1.0, "fog": 0.14}, "near": {"heat": 0.8}},
	"saloes": {"far": {"fog": 0.30, "glow": 0.08, "glow_speed": 0.4}, "mid": {"bob": 1.0, "fog": 0.12}, "near": {}},
	"forja_rubra": {"sky": {"glow": 0.15, "glow_speed": 0.8}, "far": {"heat": 1.5, "fog": 0.28, "glow": 0.12},
		"mid": {"heat": 1.2, "fog": 0.1}, "near": {"heat": 1.0}},
	"necropole": {"far": {"sway": 1.5, "fog": 0.30, "glow": 0.14, "glow_speed": 0.3}, "mid": {"sway": 3.0, "sway_speed": 0.5, "fog": 0.12},
		"near": {"sway": 2.5}},
	"torre_babel": {"far": {"drift": 2.5, "fog": 0.30}, "mid": {"fog": 0.12}, "near": {}},
	"jardim_primordial": {"far": {"sway": 2.0, "fog": 0.28}, "mid": {"sway": 4.0, "sway_speed": 0.7, "fog": 0.12},
		"near": {"sway": 4.0, "sway_speed": 0.9}},
	"catedral": {"sky": {"wave": 1.0}, "far": {"wave": 1.5, "fog": 0.34}, "mid": {"wave": 2.0, "fog": 0.14}, "near": {"wave": 1.5}},
	"carcosa": {"far": {"glow": 0.22, "glow_speed": 0.45, "fog": 0.25}, "mid": {"sway": 1.5, "sway_speed": 0.4, "glow": 0.1, "fog": 0.1},
		"near": {"sway": 1.0}},
	"observatorio": {"far": {"drift": 1.5, "bob": 2.0, "fog": 0.25}, "mid": {"bob": 2.0, "fog": 0.1}, "near": {"bob": 1.0}},
	"ventre": {"far": {"wave": 2.5, "glow": 0.25, "glow_speed": 1.4, "fog": 0.3}, "mid": {"wave": 3.5, "glow": 0.18, "glow_speed": 1.4, "fog": 0.12},
		"near": {"wave": 2.0}},
	"penhascos": {"far": {"drift": 4.0, "bob": 2.0, "fog": 0.30}, "mid": {"drift": 1.5, "bob": 3.0, "fog": 0.12}, "near": {"bob": 1.5}},
	"cavernas": {"far": {"fog": 0.35, "glow": 0.12, "glow_speed": 0.3}, "mid": {"bob": 2.0, "fog": 0.14}, "near": {"bob": 1.0}},
	"bosque": {"far": {"sway": 2.0, "fog": 0.28}, "mid": {"sway": 4.0, "sway_speed": 0.6, "fog": 0.12}, "near": {"sway": 4.0, "sway_speed": 0.7}},
}
const DEFAULT_LIFE := {"far": {"fog": 0.28}, "mid": {"bob": 1.0, "fog": 0.12}, "near": {}}

var biome_id := ""
var _nodes := {}
var _fauna: Fauna
var _life_for := ""


func _build_layers() -> void:
	if not _nodes.is_empty():
		return
	for name in ["bd_sky", "bd_far", "fauna", "bd_mid", "bd_near"]:
		if name == "fauna":
			_fauna = Fauna.new()
			add_child(_fauna)
			continue
		var n := BackLayer.new()
		add_child(n)
		_nodes[name] = n


func _apply_life() -> void:
	_life_for = biome_id + "|" + layers
	var life: Dictionary = LIFE.get(biome_id, DEFAULT_LIFE)
	var fog := _c("glow", Palette.SKY_GLOW).lerp(_c("sky1", Palette.SKY_1), 0.4)
	var i := 0
	for name: String in _nodes:
		var n: BackLayer = _nodes[name]
		var cfg: Dictionary = life.get(name.trim_prefix("bd_"), {})
		n.tex = _layer(name)
		n.foot = _foot(n.tex)
		n.drift = cfg.get("drift", 0.0)
		n.bob = cfg.get("bob", 0.0)
		n.bob_phase = i * 1.7
		for k in ["sway", "heat", "wave", "glow"]:
			n.set_param(k, float(cfg.get(k, 0.0)))
		n.set_param("sway_speed", float(cfg.get("sway_speed", 0.6)))
		n.set_param("glow_speed", float(cfg.get("glow_speed", 0.5)))
		n.set_param("fog", fog)
		n.set_param("fog_amount", float(cfg.get("fog", 0.0)))
		i += 1
	_fauna.use(biome_id, Color(_c("sky0", Palette.SKY_0).darkened(0.35), 0.75), _c("sun", Color.WHITE).lerp(_c("glow", Palette.SKY_GLOW), 0.3))


func _dunes(size: Vector2, at: Vector2) -> void:
	_build_layers()
	if _life_for != biome_id + "|" + layers or _painted_for != sky:
		_apply_life()
	var delta := get_process_delta_time()
	for name: String in _nodes:
		var n: BackLayer = _nodes[name]
		var still := name == "bd_sky"
		var par: Array = [0.0, 0.0]
		for l in LAYERS:
			if l[0] == name:
				par = [l[1], l[2]]
		n.scroll = par[0]
		n.lift = par[1]
		n.place(delta, at, size, _t, still)


func _columns_bg(size: Vector2, at: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.SKY_0)
	for i in 6:
		var band := Palette.SKY_0.lerp(Palette.SKY_GLOW, i / 10.0)
		draw_rect(Rect2(0, size.y - 90 + i * 15, size.x, 15), band)
	_columns(at * 0.15, 72.0, 18.0, Palette.SKY_1, size, 30.0, true)
	_columns(at * 0.4, 120.0, 34.0, Palette.SKY_2, size, 60.0, false)


func _columns(scroll: Vector2, spacing: float, width: float, color: Color, size: Vector2, top: float, windows: bool) -> void:
	var first := floori(scroll.x / spacing) - 1
	var y0 := top - scroll.y * 0.2
	for i in range(first, first + int(size.x / spacing) + 3):
		var x := floorf(i * spacing - scroll.x)
		var h_off := float(absi(i * 37) % 30)
		draw_rect(Rect2(x, y0 + h_off, width, size.y - y0 - h_off + 200.0), color)
		draw_rect(Rect2(x - 3, y0 + h_off, width + 6, 4), color.lightened(0.06))
		if windows and absi(i * 53) % 3 == 0:
			var glow := Palette.WINDOW
			glow.a = 0.55
			draw_rect(Rect2(x + width * 0.5 - 2, y0 + h_off + 22, 4, 7), glow)
