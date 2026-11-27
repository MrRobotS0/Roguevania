class_name Grass
extends Node2D

# Vegetação viva no chão: fios de 1 px que nascem na face de cima dos blocos,
# em touceiras (não um tapete igual), balançam com o vento (rajadas que
# correm pelo chão) e se abrem quando alguém passa, voltando com mola.
#
# São duas camadas: a de trás (atrás dos personagens) nasce no fundo da face
# de cima; a da frente nasce na beira e cobre os pés. É isso que põe o herói
# DENTRO do mato em vez de em cima de uma linha.
#
# Cada domínio tem o seu tipo (GRASS): grama, juncos de cinza, algas,
# cílios de carne... Domínio sem entrada não tem nada.

const GRASS := {
	# cores de baixo para cima, densidade (0..1), altura mín/máx, vento, onde nasce (limiar do ruído)
	"bosque":            {"colors": ["2f3b1c", "56662a", "a0a648"], "density": 0.6, "h": [3, 8], "wind": 1.0, "patch": 0.25},
	"jardim_primordial": {"colors": ["1d4a2a", "3f8a3a", "a6e05a"], "density": 0.65, "h": [3, 9], "wind": 0.9, "patch": 0.15},
	"necropole":         {"colors": ["25302c", "4a5a4c", "8a9a7c"], "density": 0.55, "h": [2, 6], "wind": 0.6, "patch": 0.45},
	"penhascos":         {"colors": ["4a2a4a", "8a4a7a", "e8a0c8"], "density": 0.7, "h": [2, 6], "wind": 1.3, "patch": 0.35},
	"mar_de_cinzas":     {"colors": ["3a302c", "6e5e52", "b8a48c"], "density": 0.45, "h": [4, 10], "wind": 1.1, "patch": 0.5},
	"carcosa":           {"colors": ["4a3a14", "8a7224", "e8cf5a"], "density": 0.6, "h": [3, 8], "wind": 0.8, "patch": 0.4},
	"catedral":          {"colors": ["123a3a", "1f6a62", "5ac8b0"], "density": 0.5, "h": [4, 11], "wind": 0.45, "patch": 0.45},
	"ventre":            {"colors": ["4a1420", "8a2a3a", "e86a70"], "density": 0.7, "h": [2, 5], "wind": 0.5, "patch": 0.35},
}
const PUSH_RADIUS := 11.0
const STIFF := 150.0          # mola que traz o fio de volta
const DAMP := 7.0

var room: Room
var front := false
var biome_id := ""

var _x := PackedFloat32Array()
var _y := PackedFloat32Array()
var _h := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _bend := PackedFloat32Array()
var _vel := PackedFloat32Array()
var _shade := PackedByteArray()    # 0..2: fio mais escuro ou mais claro
var _colors: Array[Color] = []
var _wind := 1.0
var _t := 0.0


static func has_grass(id: String) -> bool:
	return GRASS.has(id)


func _ready() -> void:
	z_index = 6 if front else 3
	var cfg: Dictionary = GRASS.get(biome_id, {})
	if cfg.is_empty() or room == null:
		set_process(false)
		return
	for c: String in cfg["colors"]:
		_colors.append(Color(c))
	_wind = float(cfg["wind"])
	_build(cfg)


# Onde nasce: em cima de bloco sólido com pelo menos 2 blocos de ar em cima,
# em touceiras (ruído suave ao longo do chão) e mais ralo nas pontas.
func _build(cfg: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(biome_id) ^ room.cols * 7919 ^ (1 if front else 0)
	var hmin: int = cfg["h"][0]
	var hmax: int = cfg["h"][1]
	var density: float = cfg["density"]
	var patch: float = cfg["patch"]
	var blades: Array = []
	for y in range(1, room.rows):
		for x in room.cols:
			if not _ground(x, y) or _ground(x, y - 1) or _ground(x, y - 2):
				continue
			for i in Room.TILE:
				var wx := x * Room.TILE + i
				var clump := _noise(wx * 0.045 + y * 3.1)
				if clump < patch or rng.randf() > density * (clump - patch) / (1.0 - patch) * 1.6:
					continue
				# fundo da face (atrás) ou beira (frente)
				var depth := rng.randi_range(-4, -2) if not front else rng.randi_range(-1, 0)
				if front and rng.randf() < 0.45:
					continue
				var tall := lerpf(hmin, hmax, pow(rng.randf(), 1.6) * clump)
				blades.append([wx + 0.5, y * Room.TILE + depth, roundf(tall * (0.75 if front else 1.0)),
					rng.randf() * TAU, rng.randi_range(0, 2)])
	# em ordem de x: a cada quadro só se percorre a faixa que está na tela
	blades.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for bl: Array in blades:
		_x.append(bl[0])
		_y.append(bl[1])
		_h.append(bl[2])
		_phase.append(bl[3])
		_shade.append(bl[4])
		_bend.append(0.0)
		_vel.append(0.0)


func _ground(x: int, y: int) -> bool:
	var c := room.cell(x, y)
	return c == Room.SOLID or c == Room.CRACKED


func _noise(v: float) -> float:
	# ruído suave 1D: soma de senos com frequências que não se repetem
	return 0.5 + 0.25 * sin(v) + 0.15 * sin(v * 2.37 + 1.3) + 0.1 * sin(v * 5.1 + 4.0)


func _view_rect() -> Rect2:
	var xf := get_viewport().get_canvas_transform()
	var size := get_viewport_rect().size
	var tl := xf.affine_inverse() * Vector2.ZERO
	var br := xf.affine_inverse() * size
	return Rect2(tl, br - tl).grow(16.0)


func _process(delta: float) -> void:
	_t += delta
	var view := _view_rect()
	# só quem está na tela empurra o mato
	var feet := PackedVector2Array()
	var p := get_tree().get_first_node_in_group("player")
	if p:
		feet.append((p as Node2D).global_position)
	for a in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(a) and a is Node2D and view.has_point((a as Node2D).global_position):
			feet.append((a as Node2D).global_position)
	var nf := feet.size()
	var k := 1.0 - exp(-DAMP * delta)
	for i in range(_x.bsearch(view.position.x), _x.size()):
		var x := _x[i]
		if x > view.end.x:
			break
		if _y[i] < view.position.y or _y[i] > view.end.y:
			continue
		# vento: balanço miúdo + rajada que corre pelo chão
		var g := maxf(0.0, sin(_t * 0.55 - x * 0.012))
		g = g * g * g
		var target := _wind * (0.9 * sin(_t * 1.6 + x * 0.05 + _phase[i] * 0.3) + 0.25 * sin(_t * 3.1 + _phase[i]) + g * g * 2.4)
		var pushed := false
		for j in nf:
			var dx := x - feet[j].x
			if absf(dx) < PUSH_RADIUS and absf(_y[i] - feet[j].y) < 10.0:
				target += (1.0 if dx >= 0.0 else -1.0) * (1.0 - absf(dx) / PUSH_RADIUS) * _h[i] * 1.1
				pushed = true
		# a mola só trabalha em quem foi empurrado e ainda está voltando;
		# o resto segue o vento direto (barato: são milhares de fios)
		if pushed or absf(_vel[i]) > 0.5 or absf(_bend[i] - target) > 0.6:
			_vel[i] += (target - _bend[i]) * STIFF * delta
			_vel[i] *= 1.0 - k
			_bend[i] += _vel[i] * delta
		else:
			_bend[i] = target
			_vel[i] = 0.0
	queue_redraw()


func _draw() -> void:
	if _x.is_empty():
		return
	var view := _view_rect()
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in range(_x.bsearch(view.position.x), _x.size()):
		var x := _x[i]
		if x > view.end.x:
			break
		if _y[i] < view.position.y or _y[i] > view.end.y:
			continue
		var h := _h[i]
		var b := clampf(_bend[i], -h * 0.85, h * 0.85)
		var s := _shade[i]
		var dark := _colors[0].lerp(_colors[1], s * 0.3)
		var light := _colors[1 + mini(s, 1)]
		# O fio é feito de colunas de 1 pixel do jogo, em degraus: pé reto, meio um pouco
		# para o lado, ponta mais. Dobra em passos inteiros (é pixel art, não linha fina:
		# antes saía um risco de 1 pixel da TELA, um quarto do pixel do jogo).
		var foot := _y[i] + 1.0
		var y_mid := foot - roundf(h * 0.5)
		var y_top := foot - roundf(h * 0.8)
		var y_tip := foot - h + absf(roundf(b * 0.3))
		var o_mid := roundf(b * 0.3)
		var o_tip := roundf(b)
		_run(pts, cols, x, foot, y_mid, dark)
		_run(pts, cols, x + o_mid, y_mid, y_top, light if absf(o_mid) > 0.5 else dark)
		if y_tip < y_top:
			# dobrou muito: a ponta deita, ligada por um degrau horizontal
			if absf(o_tip - o_mid) > 1.5:
				pts.append(Vector2(x + minf(o_mid, o_tip) - 0.5, y_top + 0.5))
				pts.append(Vector2(x + maxf(o_mid, o_tip) + 0.5, y_top + 0.5))
				cols.append(light)
			_run(pts, cols, x + o_tip, y_top, y_tip, light)
	if not pts.is_empty():
		draw_multiline_colors(pts, cols, 1.0)


# Uma coluna vertical de 1 px de largura, de `from` (embaixo) até `to` (em cima).
func _run(pts: PackedVector2Array, cols: PackedColorArray, x: float, from: float, to: float, color: Color) -> void:
	if from - to < 0.5:
		return
	pts.append(Vector2(x, from))
	pts.append(Vector2(x, to))
	cols.append(color)
