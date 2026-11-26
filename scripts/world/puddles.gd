class_name Puddles
extends Node2D

# Poças d'água nas valas rasas do chão: a superfície é uma fileira de colunas
# ligadas por molas (cada uma puxa as vizinhas). Quem entra, anda ou cai na
# água afunda as colunas sob os pés e a onda corre para os lados; pouso
# forte espirra gotas. A água é meio transparente e cobre os pés.
#
# Só aparência: não muda o pulo nem a corrida.
#
# Vala rasa: trecho de 2 a 8 blocos de ar com chão embaixo e parede dos dois
# lados de no máximo 2 blocos de altura (um degrau para baixo, não um poço).

const WATER := {
	"catedral":          "3fa8b8",
	"cavernas":          "4a6ad0",
	"jardim_primordial": "3a8a6a",
	"bosque":            "4a6a4a",
	"ventre":            "a83a48",
	"necropole":         "2a4a52",
	"observatorio":      "5a4ab8",
	"mar_de_cinzas":     "6a6a78",
	"saloes":            "3a5a9a",
	"torre_babel":       "4a7ab0",
	"penhascos":         "8a5ab0",
	"carcosa":           "8a7a3a",
}
const COL := 2.0              # largura de cada coluna (px)
const DEPTH := 7.0            # altura da água acima do fundo da vala (cobre os pés)
const STIFF := 60.0           # mola que traz a coluna de volta ao nível
const DAMP := 2.2
const SPREAD := 0.22          # quanto cada coluna puxa as vizinhas

var room: Room
var biome_id := ""
var _pools: Array = []        # [Rect2 da água, PackedFloat32Array altura, PackedFloat32Array velocidade]
var _color := Color.WHITE
var _t := 0.0
var _inside := {}             # ator -> estava dentro da água no quadro anterior


static func has_water(id: String) -> bool:
	return WATER.has(id)


func _ready() -> void:
	z_index = 6               # na frente dos pés (os personagens são 4 e 5)
	if room == null or not WATER.has(biome_id):
		set_process(false)
		return
	_color = Color(WATER[biome_id])
	_find_pools()
	if _pools.is_empty():
		set_process(false)


func _solid(x: int, y: int) -> bool:
	var c := room.cell(x, y)
	return c == Room.SOLID or c == Room.CRACKED


func _find_pools() -> void:
	for y in range(2, room.rows - 1):
		var x := 0
		while x < room.cols:
			if _solid(x, y) or not _solid(x, y + 1):
				x += 1
				continue
			var x0 := x
			while x < room.cols and not _solid(x, y) and _solid(x, y + 1):
				x += 1
			var x1 := x - 1
			var n := x1 - x0 + 1
			if n < 2 or n > 8 or not _solid(x0 - 1, y) or not _solid(x1 + 1, y):
				continue
			if _solid(x0 - 1, y - 2) or _solid(x1 + 1, y - 2):
				continue          # parede alta: é poço/corredor, não vala
			var bottom := (y + 1) * Room.TILE
			var r := Rect2(x0 * Room.TILE, bottom - DEPTH, n * Room.TILE, DEPTH)
			var cols := int(r.size.x / COL)
			var hgt := PackedFloat32Array()
			hgt.resize(cols)
			var vel := PackedFloat32Array()
			vel.resize(cols)
			_pools.append([r, hgt, vel])


func _view_rect() -> Rect2:
	var xf := get_viewport().get_canvas_transform().affine_inverse()
	return Rect2(xf * Vector2.ZERO, xf.basis_xform(get_viewport_rect().size)).grow(32.0)


func _process(delta: float) -> void:
	_t += delta
	var view := _view_rect()
	var actors: Array = []
	var p := get_tree().get_first_node_in_group("player")
	if p:
		actors.append(p)
	actors.append_array(get_tree().get_nodes_in_group("enemies"))
	var dt := minf(delta, 1.0 / 30.0)
	for pool in _pools:
		var r: Rect2 = pool[0]
		if not r.intersects(view):
			continue
		var hgt: PackedFloat32Array = pool[1]
		var vel: PackedFloat32Array = pool[2]
		for a in actors:
			if is_instance_valid(a):
				_disturb(a, r, hgt, vel)
		var n := hgt.size()
		# mola de cada coluna + marola miúda que nunca para de todo
		for i in n:
			var calm := sin(_t * 2.3 + i * 0.7) * 0.15
			vel[i] += (calm - hgt[i]) * STIFF * dt
			vel[i] *= 1.0 - DAMP * dt
		# a onda passa para as vizinhas (duas passadas: espalha mais rápido)
		for _pass in 2:
			for i in n:
				if i > 0:
					var dl := (hgt[i - 1] - hgt[i]) * SPREAD
					vel[i - 1] -= dl * STIFF * dt * 0.5
					vel[i] += dl * STIFF * dt * 0.5
		for i in n:
			hgt[i] += vel[i] * dt
			hgt[i] = clampf(hgt[i], -DEPTH + 1.0, 5.0)
	queue_redraw()


# Quem está na água afunda as colunas sob os pés; ao entrar caindo, espirra.
func _disturb(a: Node, r: Rect2, hgt: PackedFloat32Array, vel: PackedFloat32Array) -> void:
	var body := a as CharacterBody2D
	if body == null:
		return
	var feet := body.global_position
	var inside := r.grow_individual(0, 4, 0, 2).has_point(feet)
	var was: bool = _inside.get(a.get_instance_id(), false)
	_inside[a.get_instance_id()] = inside
	if not inside:
		return
	var i := int((feet.x - r.position.x) / COL)
	if i < 0 or i >= hgt.size():
		return
	var push := 0.0
	if not was and body.velocity.y > 60.0:
		# entrou caindo: afunda forte e espirra para os dois lados
		push = clampf(body.velocity.y / 40.0, 3.0, 9.0)
		var surface := Vector2(feet.x, r.position.y)
		Fx.burst(surface, _color.lightened(0.45), int(push * 2.0), 70.0 + push * 12.0, 0.5, 420.0, 2.0, 60.0)
		Sfx.play("land", -12.0, 0.3)
	elif absf(body.velocity.x) > 30.0:
		push = 0.9                  # andando: rastro de marola
	if push > 0.0:
		for k in range(-2, 3):
			var j := i + k
			if j >= 0 and j < hgt.size():
				vel[j] += push * (1.0 - absf(k) * 0.3) * 6.0


func _draw() -> void:
	var view := _view_rect()
	var deep := Color(_color.r * 0.55, _color.g * 0.55, _color.b * 0.6, 0.72)
	var body := Color(_color.r, _color.g, _color.b, 0.5)
	var crest := _color.lightened(0.55)
	crest.a = 0.85
	for pool in _pools:
		var r: Rect2 = pool[0]
		if not r.intersects(view):
			continue
		var hgt: PackedFloat32Array = pool[1]
		var bottom := r.end.y
		for i in hgt.size():
			var top := roundf(r.position.y - hgt[i])
			var x := r.position.x + i * COL
			draw_rect(Rect2(x, top, COL, bottom - top), body)
			draw_rect(Rect2(x, maxf(top + 3.0, bottom - 3.0), COL, minf(3.0, bottom - top - 3.0)), deep)
			draw_rect(Rect2(x, top, COL, 1), crest)
		# brilho que corre pela superfície
		var k := fposmod(_t * 0.35 + r.position.x * 0.01, 1.4)
		if k < 1.0:
			var gx := r.position.x + k * r.size.x
			var gi := clampi(int((gx - r.position.x) / COL), 0, hgt.size() - 1)
			draw_rect(Rect2(roundf(gx), roundf(r.position.y - hgt[gi]) + 1.0, 4, 1), Color(1, 1, 1, 0.45))
