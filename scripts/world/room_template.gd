class_name RoomTemplate
extends RefCounted

# Uma sala feita à mão (arquivo .txt), usada como peça pelo gerador.
# Cabeçalho:
#   ; tipo: inicio | combate | corredor | elite | tesouro | fragmento | saida
#   ; peso: 10
# Portas: letras D na borda da sala. Na borda esquerda/direita, uma coluna
# de D é uma passagem; no teto/chão, uma fileira de D é um poço.
# Porta que o gerador não usar vira parede.

var name := ""
var kind := "combate"
var weight := 10
var lines: PackedStringArray = []
var width := 0
var height := 0
var doors: Array[Dictionary] = []    # {side: "L"|"R"|"T"|"B", start: int, size: int}

# Que portas se ligam de verdade, com o pulo do herói: "2>0" = quem entra
# pela porta 2 consegue sair pela 0; "P>1" = do início até a porta 1.
# Calculado uma vez por sala (é o mesmo modelo do tools/validar_salas.py).
static var _links_cache := {}
var _links := {}
var _reach := {}                        # entrada -> células alcançáveis (lugar de portal)


# A sala como grade para o JumpMap (porta conta como passagem livre).
class Grid:
	var cols := 0
	var rows := 0
	var g: PackedStringArray

	func cell(x: int, y: int) -> String:
		if x < 0 or y < 0 or x >= cols or y >= rows:
			return Room.SOLID
		var c := g[y][x]
		return c if c == Room.SOLID or c == Room.PLATFORM or c == Room.CRACKED else "."

	func is_solid(x: int, y: int) -> bool:
		var c := cell(x, y)
		return c == Room.SOLID or c == Room.CRACKED


static func parse(text: String, file_name := "") -> RoomTemplate:
	var t := RoomTemplate.new()
	t.name = file_name
	for raw in text.split("\n"):
		var line := raw.strip_edges(false, true)
		if line.begins_with(";"):
			var meta := line.trim_prefix(";").strip_edges()
			if meta.begins_with("tipo:"):
				t.kind = meta.trim_prefix("tipo:").strip_edges()
			elif meta.begins_with("peso:"):
				t.weight = int(meta.trim_prefix("peso:").strip_edges())
			continue
		if line.is_empty():
			continue
		t.lines.append(line)
	t.height = t.lines.size()
	for l in t.lines:
		t.width = maxi(t.width, l.length())
	for i in t.height:
		t.lines[i] = t.lines[i].rpad(t.width, ".")
	t._find_doors()
	return t


func links() -> Dictionary:
	if not _links.is_empty():
		return _links
	var key := "
".join(lines)
	if _links_cache.has(key):
		var cached: Array = _links_cache[key]
		_links = cached[0]
		_reach = cached[1]
		return _links
	var grid := Grid.new()
	grid.cols = width
	grid.rows = height
	grid.g = lines
	var map := JumpMap.new()
	map.build(grid)
	var froms := {}
	for i in doors.size():
		froms[str(i)] = _door_entry(map, doors[i])
	for y in height:
		var x := lines[y].find("P")
		if x >= 0:
			var f: Variant = map.fall_from(x, y)
			froms["P"] = [f] if f != null else []
	var goal := Vector2i(-99, -99)
	for y in height:
		var x := lines[y].find("X")
		if x >= 0:
			goal = Vector2i(x, y)
	for from: String in froms:
		var seen := map.reach(froms[from])
		_reach[from] = seen.keys()
		for j in doors.size():
			_links["%s>%d" % [from, j]] = _door_exit_ok(doors[j], seen, map)
		for c: Vector2i in seen:
			if absi(c.x - goal.x) <= 1 and absi(c.y - goal.y) <= 1:
				_links["%s>X" % from] = true
	_links["_"] = true
	_links_cache[key] = [_links, _reach]
	return _links


# Um lugar no chão, perto do meio da sala, que quem entrou por `from` alcança.
func spot_from(from: Variant) -> Variant:
	links()
	var best: Variant = null
	var best_d := 1 << 30
	for c: Vector2i in _reach.get(str(from), []):
		if lines[c.y][c.x] != "." or c.y < 2:
			continue
		var d := absi(c.x - width / 2) + absi(c.y - height / 2) * 2
		if d < best_d:
			best = c
			best_d = d
	return best


func reaches_exit(from: Variant) -> bool:
	return links().get("%s>X" % str(from), false)


# Entrando por `from` (índice ou "P"), dá para sair pela porta `to`?
func connects(from: Variant, to: int) -> bool:
	return links().get("%s>%d" % [str(from), to], false)


func _door_entry(map: JumpMap, d: Dictionary) -> Array:
	var out: Array = []
	var s: int = d["start"]
	var e: int = s + int(d["size"]) - 1
	match d["side"]:
		"L", "R":
			var f: Variant = map.fall_from(1 if d["side"] == "L" else width - 2, e)
			if f != null:
				out.append(f)
		"T":
			for x in range(s, e + 1):
				var f: Variant = map.fall_from(x, 1)
				if f != null:
					out.append(f)
		_:
			for x in range(s - 2, e + 3):
				if map.stand(x, height - 2):
					out.append(Vector2i(x, height - 2))
	return out


func _door_exit_ok(d: Dictionary, seen: Dictionary, map: JumpMap) -> bool:
	var s: int = d["start"]
	var e: int = s + int(d["size"]) - 1
	match d["side"]:
		"L", "R":
			var f: Variant = map.fall_from(1 if d["side"] == "L" else width - 2, e)
			return f != null and seen.has(f)
		"T":
			for c: Vector2i in seen:
				if c.y <= 1 and c.x >= s and c.x <= e:
					return true
			return false
	for c: Vector2i in seen:
		if c.y == height - 2 and c.x >= s - 1 and c.x <= e + 1:
			return true
	return false


func at(x: int, y: int) -> String:
	return lines[y][x]


func _find_doors() -> void:
	doors.clear()
	_scan("L", func(i: int) -> String: return at(0, i), height)
	_scan("R", func(i: int) -> String: return at(width - 1, i), height)
	_scan("T", func(i: int) -> String: return at(i, 0), width)
	_scan("B", func(i: int) -> String: return at(i, height - 1), width)


func _scan(side: String, read: Callable, length: int) -> void:
	var i := 0
	while i < length:
		if read.call(i) != "D":
			i += 1
			continue
		var start := i
		while i < length and read.call(i) == "D":
			i += 1
		doors.append({"side": side, "start": start, "size": i - start})


func doors_on(side: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in doors:
		if d["side"] == side:
			out.append(d)
	return out


# Células de uma porta, em coordenadas da própria sala.
func door_cells(d: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in d["size"]:
		var k: int = d["start"] + i
		match d["side"]:
			"L": out.append(Vector2i(0, k))
			"R": out.append(Vector2i(width - 1, k))
			"T": out.append(Vector2i(k, 0))
			"B": out.append(Vector2i(k, height - 1))
	return out
