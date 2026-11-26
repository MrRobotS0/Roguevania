class_name TorchShadows
extends Node2D

# Sombra projetada pelas tochas (braseiros) na parede do fundo.
#
# As luzes 2D do Godot só acendem o que está na mesma camada, e a parede do
# fundo é pintada em outra (o cenário em paralaxe), por isso a sombra é
# desenhada aqui:
#   blocos: cada bloco perto do fogo empurra uma sombra para longe dele,
#     escura junto do bloco e sumindo até o fim do alcance;
#   personagens: a silhueta de quem passa perto do fogo aparece na parede,
#     maior e deslocada para o lado contrário, tremendo com a chama.
#
# Só nos domínios fechados (INDOOR): num céu aberto, sombra no céu é erro.

const INDOOR := ["forja_rubra", "catedral", "cavernas", "ventre"]
const REACH := 120.0          # até onde a sombra vai
const BLOCK_DARK := 0.55      # escuridão da sombra junto do bloco
const ACTOR_DARK := 0.62

var room: Room
var biome_id := ""
var _lights: Array[Vector2] = []
var _blocks := {}             # índice da tocha -> [Rect2 dos blocos ao alcance]
var _t := 0.0
var _rects: Array[Rect2] = []


static func has_shadows(id: String) -> bool:
	return INDOOR.has(id)


func _ready() -> void:
	z_index = -1              # atrás dos blocos (que cobrem a própria base da sombra) e dos personagens
	# sombra não recebe luz (senão a luz do domínio soma cor e ela fica rosada)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	if room == null:
		set_process(false)
		return
	for r: Rect2i in room._merged_rects(Room.SOLID, true):
		_rects.append(Rect2(Vector2(r.position) * Room.TILE, Vector2(r.size) * Room.TILE))
	for spot in room.brazier_spots:
		add_light(spot)


# Mais uma tocha (o pé do braseiro em `spot`): guarda os blocos ao alcance.
func add_light(spot: Vector2) -> void:
	var light := spot + Vector2(0, -16)
	var near: Array[Rect2] = []
	var reach := Rect2(light - Vector2(REACH, REACH), Vector2(REACH, REACH) * 2.0)
	for r in _rects:
		if r.intersects(reach) and not r.has_point(light):
			near.append(r)
	_blocks[_lights.size()] = near
	_lights.append(light)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _flicker(i: int) -> float:
	var seed := fposmod(_lights[i].x * 0.137, TAU)
	return 0.9 + 0.1 * sin(_t * 9.0 + seed) + 0.05 * sin(_t * 23.0)


func _draw() -> void:
	var xf := get_viewport().get_canvas_transform().affine_inverse()
	var view := Rect2(xf * Vector2.ZERO, xf.basis_xform(get_viewport_rect().size)).grow(REACH)
	var actors: Array = []
	var p := get_tree().get_first_node_in_group("player")
	if p:
		actors.append(p)
	actors.append_array(get_tree().get_nodes_in_group("enemies"))
	for i in _lights.size():
		var light := _lights[i]
		if not view.has_point(light):
			continue
		var k := _flicker(i)
		# a chama dança: a origem da sombra mexe um pouco
		var origin := light + Vector2(sin(_t * 7.0 + i) * 0.8, sin(_t * 11.0 + i * 2.0) * 0.6)
		for r: Rect2 in _blocks[i]:
			_block_shadow(origin, r, BLOCK_DARK * k)
		for a in actors:
			if is_instance_valid(a):
				_actor_shadow(origin, a, ACTOR_DARK * k)


# Sombra de um bloco: o contorno do bloco e o mesmo contorno empurrado para
# longe da luz até o fim do alcance, juntos num polígono só (casca convexa).
func _block_shadow(light: Vector2, r: Rect2, dark: float) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var pts := PackedVector2Array()
	var far := {}
	for c: Vector2 in corners:
		var away := c - light
		var dist := away.length()
		if dist >= REACH:
			continue
		pts.append(c)
		var q := c + away / maxf(dist, 1.0) * (REACH - dist)
		pts.append(q)
		far[q] = true
	if pts.size() < 3:
		return
	var hull := Geometry2D.convex_hull(pts)
	if hull.size() < 4:
		return
	hull.remove_at(hull.size() - 1)       # a casca repete o primeiro ponto no fim
	var cols := PackedColorArray()
	for v in hull:
		var fade := 1.0 - clampf((v - light).length() / REACH, 0.0, 1.0)
		cols.append(Color(0, 0, 0, 0.0 if far.has(v) else dark * fade))
	draw_polygon(hull, cols)


# Silhueta de quem está perto do fogo, na parede: deslocada para o lado
# contrário, um pouco maior (a parede está atrás) e mais fraca com a distância.
func _actor_shadow(light: Vector2, a: Node, dark: float) -> void:
	var feet: Vector2 = (a as Node2D).global_position
	var center := feet + Vector2(0, -12)
	var d := center - light
	var dist := d.length()
	if dist > REACH or dist < 2.0:
		return
	var s: Sprite2D = a.get("body")
	if s == null or not is_instance_valid(s) or not s.visible or s.texture == null:
		return
	var src := _frame_rect(s)
	if src.size.x <= 0.0:
		return
	var fade := sqrt(1.0 - dist / REACH)
	var grow := 1.15 + 0.35 * (1.0 - fade)
	var shift := d.normalized() * (6.0 + dist * 0.35)
	var flip := -1.0 if s.flip_h else 1.0
	var at := s.global_position + shift
	draw_set_transform(at, 0.0, Vector2(flip, 1.0) * s.global_scale * grow)
	# o desenho é simétrico em volta da origem (offset = -largura/2): espelhar
	# pela escala dá o mesmo que o flip_h do Sprite2D
	var dst := Rect2(s.offset, src.size)
	draw_texture_rect_region(s.texture, dst, src, Color(0, 0, 0, dark * fade))
	draw_set_transform(Vector2.ZERO)


static func _frame_rect(s: Sprite2D) -> Rect2:
	if s.region_enabled:
		return s.region_rect
	var size := s.texture.get_size()
	var fw := size.x / maxf(s.hframes, 1)
	var fh := size.y / maxf(s.vframes, 1)
	return Rect2((s.frame % s.hframes) * fw, floori(float(s.frame) / s.hframes) * fh, fw, fh)
