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


func _init() -> void:
	colors = default_colors()


static func default_colors() -> Dictionary:
	return {
		"stone": Palette.STONE, "deep": Palette.STONE_DEEP, "top": Palette.STONE_TOP,
		"light": Palette.STONE_LIGHT, "shadow": Palette.STONE_SHADOW, "moss": Palette.MOSS,
		"wood": Palette.WOOD, "wood_top": Palette.WOOD_TOP, "wood_dark": Palette.WOOD_DARK,
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

	func _draw() -> void:
		room.draw_area(self, area)


func _build_chunks() -> void:
	for c in _chunks.values():
		c.queue_free()
	_chunks.clear()
	for cy in range(0, rows, CHUNK):
		for cx in range(0, cols, CHUNK):
			var chunk := Chunk.new()
			chunk.room = self
			chunk.area = Rect2i(cx, cy, mini(CHUNK, cols - cx), mini(CHUNK, rows - cy))
			add_child(chunk)
			_chunks[Vector2i(cx / CHUNK, cy / CHUNK)] = chunk


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
		ci.draw_rect(Rect2(p, Vector2(TILE, TILE)), colors["deep"])
		if _hash(x, y) < 40:
			ci.draw_rect(Rect2(p + Vector2(_hash(y, x) % 12 + 2, _hash(x, y) % 12 + 2), Vector2(2, 1)), colors["shadow"])
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


func _draw_plank(ci: CanvasItem, x: int, y: int) -> void:
	var p := Vector2(x, y) * TILE
	ci.draw_rect(Rect2(p, Vector2(TILE, 5)), colors["wood"])
	ci.draw_rect(Rect2(p, Vector2(TILE, 1)), colors["wood_top"])
	ci.draw_rect(Rect2(p + Vector2(0, 5), Vector2(TILE, 1)), colors["wood_dark"])
	if cell(x - 1, y) != PLATFORM or x % 3 == 0:
		ci.draw_rect(Rect2(p + Vector2(3, 6), Vector2(2, 5)), colors["wood_dark"])
	if (x + y) % 2 == 0:
		ci.draw_rect(Rect2(p + Vector2(9, 2), Vector2(1, 2)), colors["wood_dark"])
