class_name Room
extends Node2D

# O mapa de uma fase inteira, um caractere por bloco:
#   #  pedra sólida        =  plataforma (atravessa por baixo; S+pulo desce)
#   F  parede falsa (parece pedra, mas dá para atravessar: salas secretas)
#   .  vazio               ;  linha de comentário (só nos arquivos de sala)
# Marcadores (viram vazio e são entregues à fase para criar objetos):
#   P início  e inimigo comum  r inimigo à distância  E elite  B chefe
#   i item  f fragmento divino  L inscrição  X saída  V vigia  w zona de vidro
#   g/a brutamontes/atirador fixos (salas de teste)

const TILE := 16
const SOLID := "#"
const PLATFORM := "="
const FAKE := "F"
const MARKERS := "PeErBifLXVwga"
const WORLD_LAYER := 1
const PLATFORM_LAYER := 8
const CHUNK := 16

var cols := 0
var rows := 0
var grid: PackedStringArray = []
var markers: Array[Dictionary] = []
var player_spawn := Vector2.ZERO
var colors := {}
var spawns: Array[Dictionary]:
	get:
		var out: Array[Dictionary] = []
		for m in markers:
			if m["ch"] == "g":
				out.append({"kind": "grunt", "pos": m["pos"]})
			elif m["ch"] == "a":
				out.append({"kind": "archer", "pos": m["pos"]})
		return out

var _chunks := {}
var _revealed := {}
var _depth := PackedByteArray()      # distância (em blocos) até o ar mais próximo
var decor: Array = []                # [tipo, célula]: enfeites desenhados atrás de tudo
var brazier_spots: Array[Vector2] = []
var glints: Array[Vector2] = []      # cacos de vidro que piscam


func _init() -> void:
	colors = default_colors()


static func default_colors() -> Dictionary:
	return {
		"stone": Palette.STONE, "deep": Palette.STONE_DEEP, "top": Palette.STONE_TOP,
		"light": Palette.STONE_LIGHT, "shadow": Palette.STONE_SHADOW, "moss": Palette.MOSS,
		"wood": Palette.WOOD, "wood_top": Palette.WOOD_TOP, "wood_dark": Palette.WOOD_DARK,
		"bone": Color("c8bca4"), "cloth": Color("6a1e26"), "vein": Palette.GLASS,
	}


func load_file(path: String) -> void:
	load_text(FileAccess.get_file_as_string(path))


func load_text(text: String) -> void:
	var lines := PackedStringArray()
	for line in text.split("\n"):
		line = line.strip_edges(false, true)
		if line.is_empty() or line.begins_with(";"):
			continue
		lines.append(line)
	load_grid(lines)


func load_grid(lines: PackedStringArray) -> void:
	grid = lines.duplicate()
	markers.clear()
	rows = grid.size()
	cols = 0
	for line in grid:
		cols = maxi(cols, line.length())
	for y in rows:
		var line := grid[y].rpad(cols, ".")
		for x in cols:
			var c := line[x]
			if MARKERS.contains(c):
				var feet := Vector2((x + 0.5) * TILE, (y + 1) * TILE)
				markers.append({"ch": c, "pos": feet, "cell": Vector2i(x, y)})
				if c == "P":
					player_spawn = feet
				line = line.substr(0, x) + "." + line.substr(x + 1)
		grid[y] = line
	_build_collision()
	_build_depth()
	_build_decor()
	_build_chunks()


func size_px() -> Vector2:
	return Vector2(cols, rows) * TILE


func markers_of(ch: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in markers:
		if m["ch"] == ch:
			out.append(m)
	return out


func cell(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= cols or y >= rows:
		return SOLID
	return grid[y][x]


func is_solid(x: int, y: int) -> bool:
	return cell(x, y) == SOLID


func is_solid_at(p: Vector2) -> bool:
	return is_solid(floori(p.x / TILE), floori(p.y / TILE))


func is_ground_at(p: Vector2) -> bool:
	var c := cell(floori(p.x / TILE), floori(p.y / TILE))
	return c == SOLID or c == PLATFORM


func is_platform_at(p: Vector2) -> bool:
	return cell(floori(p.x / TILE), floori(p.y / TILE)) == PLATFORM


func clear_line(a: Vector2, b: Vector2) -> bool:
	var steps := int(a.distance_to(b) / 6.0)
	for i in range(1, steps):
		if is_solid_at(a.lerp(b, float(i) / steps)):
			return false
	return true


# Paredes falsas somem quando o herói chega perto.
func reveal_near(p: Vector2) -> void:
	var cx := floori(p.x / TILE)
	var cy := floori(p.y / TILE)
	for y in range(cy - 3, cy + 2):
		for x in range(cx - 2, cx + 3):
			if cell(x, y) == FAKE and not _revealed.has(Vector2i(x, y)):
				_reveal_from(Vector2i(x, y))


func _reveal_from(start: Vector2i) -> void:
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		if _revealed.has(c) or cell(c.x, c.y) != FAKE:
			continue
		_revealed[c] = true
		var key := Vector2i(c.x / CHUNK, c.y / CHUNK)
		if _chunks.has(key):
			_chunks[key].queue_redraw()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			todo.append(c + d)
	Sfx.play("secret", -4.0)


# --- colisão --------------------------------------------------------------

func _build_collision() -> void:
	var stone := StaticBody2D.new()
	stone.collision_layer = WORLD_LAYER
	stone.collision_mask = 0
	add_child(stone)
	for r in _merged_rects(SOLID, true):
		_add_box(stone, Rect2(Vector2(r.position) * TILE, Vector2(r.size) * TILE), false)

	var planks := StaticBody2D.new()
	planks.collision_layer = PLATFORM_LAYER
	planks.collision_mask = 0
	add_child(planks)
	for r in _merged_rects(PLATFORM, false):
		_add_box(planks, Rect2(Vector2(r.position) * TILE, Vector2(r.size.x * TILE, 8)), true)


func _add_box(body: StaticBody2D, rect: Rect2, one_way: bool) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var holder := CollisionShape2D.new()
	holder.shape = shape
	holder.position = rect.get_center()
	holder.one_way_collision = one_way
	body.add_child(holder)


# Junta blocos iguais em retângulos grandes: menos formas e nenhuma
# "costura" no chão para o personagem enganchar.
func _merged_rects(ch: String, vertical: bool) -> Array[Rect2i]:
	var done: Array[Rect2i] = []
	var open: Array[Rect2i] = []
	for y in rows:
		var runs: Array[Rect2i] = []
		var x := 0
		while x < cols:
			if grid[y][x] != ch:
				x += 1
				continue
			var start := x
			while x < cols and grid[y][x] == ch:
				x += 1
			runs.append(Rect2i(start, y, x - start, 1))

		var still_open: Array[Rect2i] = []
		for r in open:
			var grown := false
			if vertical:
				for i in runs.size():
					if runs[i].position.x == r.position.x and runs[i].size.x == r.size.x:
						still_open.append(Rect2i(r.position, r.size + Vector2i(0, 1)))
						runs.remove_at(i)
						grown = true
						break
			if not grown:
				done.append(r)
		still_open.append_array(runs)
		open = still_open
	done.append_array(open)
	return done


# --- desenho (arte provisória) ---------------------------------------------
# O mapa é dividido em pedaços de 16x16 blocos; o Godot só desenha os
# pedaços que aparecem na tela.

class Chunk:
	extends Node2D
	var room: Room
	var area: Rect2i
	var back := false

	func _draw() -> void:
		if back:
			room.draw_decor(self, area)
		else:
			room.draw_area(self, area)


class Glints:
	extends Node2D
	var room: Room
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		var view := Rect2(cam.get_screen_center_position() - Vector2(260, 150), Vector2(520, 300))
		for i in room.glints.size():
			var p: Vector2 = room.glints[i]
			if not view.has_point(p):
				continue
			var k := fposmod(_t * 0.7 + i * 0.37, 1.0)
			if k > 0.12:
				continue
			var c := Palette.FLASH
			c.a = 1.0 - k / 0.12
			var soft := Color(c, c.a * 0.5)
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 1)), soft)
			draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 3)), soft)
			draw_rect(Rect2(p, Vector2(1, 1)), c)


func _build_chunks() -> void:
	for c in _chunks.values():
		c.queue_free()
	_chunks.clear()
	for cy in range(0, rows, CHUNK):
		for cx in range(0, cols, CHUNK):
			var area := Rect2i(cx, cy, mini(CHUNK, cols - cx), mini(CHUNK, rows - cy))
			var behind := Chunk.new()
			behind.room = self
			behind.area = area
			behind.back = true
			behind.z_index = -1
			add_child(behind)
			var chunk := Chunk.new()
			chunk.room = self
			chunk.area = area
			add_child(chunk)
			_chunks[Vector2i(cx / CHUNK, cy / CHUNK)] = chunk
	var g := Glints.new()
	g.room = self
	g.z_index = 1
	add_child(g)


# --- profundidade e enfeites --------------------------------------------------------

func depth(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= cols or y >= rows:
		return 9
	return _depth[y * cols + x]


func _build_depth() -> void:
	_depth = PackedByteArray()
	_depth.resize(cols * rows)
	_depth.fill(9)
	var todo: Array[Vector2i] = []
	for y in rows:
		for x in cols:
			if not _solidish(x, y):
				_depth[y * cols + x] = 0
				todo.append(Vector2i(x, y))
	var head := 0
	while head < todo.size():
		var c := todo[head]
		head += 1
		var d := _depth[c.y * cols + c.x] + 1
		if d > 8:
			continue
		for n: Vector2i in [Vector2i(c.x + 1, c.y), Vector2i(c.x - 1, c.y), Vector2i(c.x, c.y + 1), Vector2i(c.x, c.y - 1)]:
			if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows:
				continue
			if _depth[n.y * cols + n.x] > d:
				_depth[n.y * cols + n.x] = d
				todo.append(n)


func _air(x: int, y: int) -> bool:
	return cell(x, y) == "."


func _build_decor() -> void:
	decor.clear()
	brazier_spots.clear()
	glints.clear()
	var last_brazier := -99
	for y in rows:
		for x in cols:
			if not _air(x, y):
				continue
			var hv := _hash(x * 3 + 1, y * 5 + 2)
			if is_solid(x, y + 1):
				var room_up := 0
				while room_up < 5 and _air(x, y - room_up - 1):
					room_up += 1
				var base := Vector2((x + 0.5) * TILE, (y + 1) * TILE)
				if hv < 9 and room_up >= 4:
					decor.append(["tree", Vector2i(x, y)])
				elif hv < 17 and room_up >= 3:
					decor.append(["column", Vector2i(x, y)])
				elif hv < 30:
					decor.append(["bones", Vector2i(x, y)])
				elif hv < 54:
					decor.append(["mound", Vector2i(x, y)])
				elif hv < 70:
					decor.append(["shards", Vector2i(x, y)])
					glints.append(base + Vector2(hv % 9 - 4, -3))
				elif hv < 90 and x - last_brazier > 14 and room_up >= 2 and _air(x - 1, y) and _air(x + 1, y):
					brazier_spots.append(base)
					last_brazier = x
			elif is_solid(x, y - 1) and _air(x, y + 1) and _air(x, y + 2):
				if hv < 22:
					decor.append(["banner", Vector2i(x, y)])
				elif hv < 40:
					decor.append(["chain", Vector2i(x, y)])


func draw_decor(ci: CanvasItem, area: Rect2i) -> void:
	for d in decor:
		var c: Vector2i = d[1]
		if area.has_point(c):
			_draw_prop(ci, d[0], c)


func _draw_prop(ci: CanvasItem, kind: String, c: Vector2i) -> void:
	var hv := _hash(c.x * 7, c.y * 3)
	var floor_y := float((c.y + 1) * TILE)
	var top_y := float(c.y * TILE)
	var cx := float(c.x * TILE + 8)
	var dark: Color = Color(colors["shadow"]).lerp(colors["stone"], 0.35)
	match kind:
		"tree":
			# árvore morta, galhos secos para os dois lados
			var tall := 34 + hv % 14
			ci.draw_rect(Rect2(cx - 2, floor_y - tall, 3, tall), dark)
			ci.draw_rect(Rect2(cx - 3, floor_y - 3, 5, 3), dark)
			for i in 3:
				var by := floor_y - tall + 4 + i * 8
				var side := 1 if (hv + i) % 2 == 0 else -1
				var reach := 6 + (hv >> (i + 1)) % 6
				ci.draw_rect(Rect2(cx + (1 if side > 0 else -1 - reach), by, reach, 1), dark)
				ci.draw_rect(Rect2(cx + side * reach - (1 if side < 0 else 0), by - 3, 1, 3), dark)
		"column":
			var tall := 22 + hv % 18
			var stone: Color = Color(colors["stone"]).darkened(0.3)
			ci.draw_rect(Rect2(cx - 6, floor_y - tall, 12, tall), stone)
			ci.draw_rect(Rect2(cx - 8, floor_y - 4, 16, 4), stone.darkened(0.15))
			ci.draw_rect(Rect2(cx - 6, floor_y - tall, 12, 1), Color(colors["top"]).darkened(0.25))
			ci.draw_rect(Rect2(cx - 2, floor_y - tall + 3, 1, tall - 7), stone.darkened(0.25))
			ci.draw_rect(Rect2(cx + 3, floor_y - tall + 3, 1, tall - 7), stone.darkened(0.25))
			ci.draw_rect(Rect2(cx + 1, floor_y - tall - 3, 5, 3), stone)
		"bones":
			var bone: Color = colors["bone"]
			ci.draw_rect(Rect2(cx - 5 + hv % 4, floor_y - 2, 7, 1), bone.darkened(0.2))
			ci.draw_rect(Rect2(cx - 6 + hv % 4, floor_y - 3, 2, 2), bone.darkened(0.2))
			ci.draw_rect(Rect2(cx + 2, floor_y - 4, 4, 4), bone)
			ci.draw_rect(Rect2(cx + 3, floor_y - 3, 1, 1), Palette.UI_SHADOW)
		"mound":
			var ash: Color = Color(colors["moss"]).darkened(0.35)
			var wide := 10 + hv % 12
			for i in 3:
				ci.draw_rect(Rect2(cx - wide * 0.5 + i * 3, floor_y - 1 - i, wide - i * 6, 1), ash.lightened(i * 0.06))
		"shards":
			var glass: Color = colors["vein"]
			glass.a = 0.8
			ci.draw_rect(Rect2(cx - 4 + hv % 5, floor_y - 3, 1, 3), glass)
			ci.draw_rect(Rect2(cx - 2 + hv % 5, floor_y - 5, 2, 5), glass)
			ci.draw_rect(Rect2(cx + 2 + hv % 3, floor_y - 2, 1, 2), glass)
		"banner":
			var cloth: Color = colors["cloth"]
			var long := 18 + hv % 10
			var trim := Palette.GOLD.darkened(0.35)
			ci.draw_rect(Rect2(cx - 6, top_y, 12, 2), colors["wood"])
			ci.draw_rect(Rect2(cx - 5, top_y + 2, 10, long), cloth)
			ci.draw_rect(Rect2(cx - 5, top_y + 2, 1, long), cloth.lightened(0.15))
			ci.draw_rect(Rect2(cx - 3, top_y + 6, 6, 1), trim)
			ci.draw_rect(Rect2(cx - 1, top_y + 8, 2, 5), trim)
			# ponta rasgada
			ci.draw_rect(Rect2(cx - 5, top_y + 2 + long, 3, 3), cloth)
			ci.draw_rect(Rect2(cx + 1, top_y + 2 + long, 4, 2 + hv % 3), cloth)
		"chain":
			var links := 3 + hv % 4
			var metal: Color = Color(colors["shadow"]).lightened(0.18)
			for i in links:
				if i % 2 == 0:
					ci.draw_rect(Rect2(cx - 1, top_y + i * 4, 3, 4), metal)
					ci.draw_rect(Rect2(cx, top_y + i * 4 + 1, 1, 2), colors["shadow"])
				else:
					ci.draw_rect(Rect2(cx, top_y + i * 4, 1, 4), metal)
			ci.draw_rect(Rect2(cx - 2, top_y + links * 4, 5, 2), metal)


func draw_area(ci: CanvasItem, area: Rect2i) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			match grid[y][x]:
				SOLID:
					_draw_stone(ci, x, y)
				FAKE:
					if not _revealed.has(Vector2i(x, y)):
						_draw_stone(ci, x, y)
					else:
						var ghost: Color = colors["top"]
						ghost.a = 0.18
						ci.draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), ghost)
				PLATFORM:
					_draw_plank(ci, x, y)


func _hash(x: int, y: int) -> int:
	return ((x * 73856093) ^ (y * 19349663)) & 0xff


func _solidish(x: int, y: int) -> bool:
	var c := cell(x, y)
	return c == SOLID or c == FAKE


func _draw_stone(ci: CanvasItem, x: int, y: int) -> void:
	var p := Vector2(x, y) * TILE
	var open_up := not _solidish(x, y - 1)
	var open_down := not _solidish(x, y + 1)
	var open_left := not _solidish(x - 1, y)
	var open_right := not _solidish(x + 1, y)
	var buried := not (open_up or open_down or open_left or open_right) \
		and _solidish(x - 1, y - 1) and _solidish(x + 1, y - 1) \
		and _solidish(x - 1, y + 1) and _solidish(x + 1, y + 1)

	if buried:
		_draw_buried(ci, x, y, p)
		return

	ci.draw_rect(Rect2(p, Vector2(TILE, TILE)), colors["stone"])
	for half in 2:
		var row := y * 2 + half
		var top := p.y + half * 8
		ci.draw_rect(Rect2(p.x, top + 7, TILE, 1), colors["shadow"])
		var joint := 2 if row % 2 == 0 else 6
		ci.draw_rect(Rect2(p.x + joint, top, 1, 7), colors["shadow"])
		ci.draw_rect(Rect2(p.x + joint + 8, top, 1, 7), colors["shadow"])
		ci.draw_rect(Rect2(p.x + joint + 1, top, 6, 1), Color(colors["top"]).darkened(0.35))

	if open_left:
		ci.draw_rect(Rect2(p, Vector2(1, TILE)), colors["top"])
	if open_right:
		ci.draw_rect(Rect2(p + Vector2(TILE - 1, 0), Vector2(1, TILE)), colors["shadow"])
	if open_down:
		ci.draw_rect(Rect2(p + Vector2(0, TILE - 2), Vector2(TILE, 2)), colors["shadow"])
	if open_up:
		ci.draw_rect(Rect2(p, Vector2(TILE, 3)), colors["top"])
		ci.draw_rect(Rect2(p, Vector2(TILE, 1)), colors["light"])
		var hv := _hash(x, y)
		if hv < 110:
			ci.draw_rect(Rect2(p + Vector2(hv % 11, -1), Vector2(3 + hv % 3, 1)), colors["moss"])
			ci.draw_rect(Rect2(p + Vector2(hv % 11 + 1, 1), Vector2(1, 1 + hv % 3)), Color(colors["moss"]).darkened(0.3))
		elif hv < 150:
			ci.draw_rect(Rect2(p + Vector2(hv % 13, -1), Vector2(2, 1)), Color(colors["top"]).darkened(0.2))
		# a cinza se acumula no pé das paredes
		var drift: Color = Color(colors["moss"]).darkened(0.12)
		if _solidish(x - 1, y - 1):
			for i in 5:
				ci.draw_rect(Rect2(p.x + i * 2, p.y - 5 + i, 2, 5 - i), drift)
		if _solidish(x + 1, y - 1):
			for i in 5:
				ci.draw_rect(Rect2(p.x + TILE - 2 - i * 2, p.y - 5 + i, 2, 5 - i), drift)


# Dentro da rocha: escurece com a profundidade e tem pedras, ossos
# enterrados e veios de vidro (onde os fulgurantes vivem).
func _draw_buried(ci: CanvasItem, x: int, y: int, p: Vector2) -> void:
	var k := clampf((depth(x, y) - 2) / 4.0, 0.0, 1.0)
	var base: Color = Color(colors["deep"]).lerp(colors["shadow"], k * 0.85)
	ci.draw_rect(Rect2(p, Vector2(TILE, TILE)), base)
	var hv := _hash(x, y)
	var hv2 := _hash(y + 17, x + 5)
	if hv < 64:
		var rock: Color = Color(colors["deep"]).lerp(colors["stone"], 0.3).lerp(colors["shadow"], k * 0.75)
		var at := p + Vector2(hv % 8 + 1, hv2 % 9 + 2)
		var size := Vector2(5 + hv % 4, 3 + hv2 % 2)
		ci.draw_rect(Rect2(at, size), rock)
		ci.draw_rect(Rect2(at, Vector2(size.x, 1)), rock.lightened(0.12))
		ci.draw_rect(Rect2(at + Vector2(0, size.y), Vector2(size.x, 1)), base.darkened(0.25))
	elif hv < 70 and k < 0.6:
		var bone: Color = Color(colors["bone"]).lerp(base, 0.45 + k * 0.4)
		var at := p + Vector2(3 + hv2 % 4, 5 + hv2 % 6)
		ci.draw_rect(Rect2(at, Vector2(7, 1)), bone)
		ci.draw_rect(Rect2(at + Vector2(-1, -1), Vector2(2, 3)), bone)
		ci.draw_rect(Rect2(at + Vector2(6, -1), Vector2(2, 3)), bone)
	elif hv < 84:
		var vein: Color = colors["vein"]
		vein.a = 0.4 * (1.0 - k * 0.6)
		var at := p + Vector2(2 + hv2 % 6, 3 + hv2 % 5)
		for i in 5:
			ci.draw_rect(Rect2(at + Vector2(i * 2, i if hv2 % 2 == 0 else -i), Vector2(2, 1)), vein)
	if hv2 < 90:
		ci.draw_rect(Rect2(p + Vector2(hv2 % 14 + 1, hv % 13 + 1), Vector2(1, 1)), base.lightened(0.1))


func _draw_plank(ci: CanvasItem, x: int, y: int) -> void:
	var p := Vector2(x, y) * TILE
	ci.draw_rect(Rect2(p, Vector2(TILE, 5)), colors["wood"])
	ci.draw_rect(Rect2(p, Vector2(TILE, 1)), colors["wood_top"])
	ci.draw_rect(Rect2(p + Vector2(0, 5), Vector2(TILE, 1)), colors["wood_dark"])
	if cell(x - 1, y) != PLATFORM or x % 3 == 0:
		ci.draw_rect(Rect2(p + Vector2(3, 6), Vector2(2, 5)), colors["wood_dark"])
	if (x + y) % 2 == 0:
		ci.draw_rect(Rect2(p + Vector2(9, 2), Vector2(1, 2)), colors["wood_dark"])
