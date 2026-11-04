class_name LevelGen
extends RefCounted

# Monta uma fase encaixando salas feitas à mão pelas portas.
#
#   caminho principal:  início → combate × N (com 1 elite perto do fim) → saída
#   desvios:            os da lista `branches` (tesouro, fragmento, loja, cofre,
#                       sala da runa...) presos nas portas que sobraram, e uma
#                       sala secreta que entra por parede falsa. Desvio pedido
#                       como [tipo, "K"] entra por parede rachada.
#
# O resultado é um único mapa de texto que a Room sabe carregar.

const OPPOSITE := {"L": "R", "R": "L", "T": "B", "B": "T"}
const MARGIN := 3

class Placed:
	var t: RoomTemplate
	var pos: Vector2i
	var used := {}          # índice da porta -> true
	var entry: Variant = "P"   # por onde o herói entra (porta) ou "P" no início
	var exit := -1          # porta por onde o caminho principal segue (-1 = beco)

	func rect() -> Rect2i:
		return Rect2i(pos, Vector2i(t.width, t.height))

	# Dá para ir da entrada até a porta `di` e voltar para seguir viagem?
	func can_branch(di: int) -> bool:
		if not t.connects(entry, di):
			return false
		if exit >= 0:
			return t.connects(di, exit)
		return entry is String or t.connects(di, entry)


var rng := RandomNumberGenerator.new()
var templates: Array[RoomTemplate] = []
var placed: Array[Placed] = []
var links: Array[Dictionary] = []     # {a, da, b, db, fill}
var main_path: Array[Placed] = []


static func load_dir(dir: String) -> Array[RoomTemplate]:
	var out: Array[RoomTemplate] = []
	var files := DirAccess.get_files_at(dir)
	files.sort()
	for f in files:
		if f.ends_with(".txt"):
			out.append(RoomTemplate.parse(FileAccess.get_file_as_string(dir.path_join(f)), f.get_basename()))
	return out


const DEFAULT_BRANCHES := ["tesouro", "fragmento", "tesouro"]

var branches: Array = DEFAULT_BRANCHES


func generate(pool: Array[RoomTemplate], seed_value: int, combat_rooms := 6, branch_list: Array = DEFAULT_BRANCHES) -> PackedStringArray:
	templates = pool
	branches = branch_list
	for attempt in 60:
		rng.seed = seed_value + attempt * 7919
		if _try_build(combat_rooms):
			return _compose()
	push_error("LevelGen: não consegui montar a fase")
	return PackedStringArray()


func _of_kind(kind: String) -> Array[RoomTemplate]:
	var out: Array[RoomTemplate] = []
	for t in templates:
		if t.kind == kind:
			out.append(t)
	return out


func _weighted_shuffle(list: Array[RoomTemplate]) -> Array[RoomTemplate]:
	var bag := list.duplicate()
	var out: Array[RoomTemplate] = []
	while not bag.is_empty():
		var total := 0
		for t: RoomTemplate in bag:
			total += t.weight
		var roll := rng.randi_range(1, total)
		for i in bag.size():
			roll -= bag[i].weight
			if roll <= 0:
				out.append(bag[i])
				bag.remove_at(i)
				break
	return out


func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


# Para onde o caminho principal tende a ir: mais para a direita, mas desce,
# sobe e volta. Sorteado de novo a cada sala.
const MAIN_SIDES := {"R": 3, "B": 3, "T": 3, "L": 1}
const PORTALS := 4

var portals: Array[Dictionary] = []   # {room: Placed, cell: Vector2i}


func _main_sides() -> Array:
	var bag := MAIN_SIDES.duplicate()
	var out: Array = []
	while not bag.is_empty():
		var total := 0
		for k in bag:
			total += int(bag[k])
		var roll := rng.randi_range(1, total)
		for k: String in bag.keys():
			roll -= int(bag[k])
			if roll <= 0:
				out.append(k)
				bag.erase(k)
				break
	return out


func _try_build(combat_rooms: int) -> bool:
	placed.clear()
	links.clear()
	main_path.clear()
	portals.clear()

	var starts := _of_kind("inicio")
	if starts.is_empty():
		return false
	var first := Placed.new()
	first.t = _weighted_shuffle(starts)[0]
	first.pos = Vector2i.ZERO
	placed.append(first)
	main_path.append(first)

	var plan: Array[String] = []
	for i in combat_rooms:
		plan.append("corredor" if rng.randf() < 0.25 else "combate")
	plan.insert(combat_rooms - 1, "elite")
	plan.append("saida")

	var current := first
	for kind in plan:
		var kinds := [kind] if kind != "corredor" else ["corredor", "combate"]
		var next := _attach(current, kinds, _main_sides(), ".", "saida" if kind == "saida" else "main")
		if next == null:
			return false
		main_path.append(next)
		current = next

	# Desvios: um ou dois cômodos de passagem antes do prêmio, para qualquer lado.
	var hosts := main_path.slice(1, main_path.size() - 1)
	var ends: Array[Placed] = []
	for b in branches:
		var kind: String = b if b is String else b[0]
		var fill: String = "." if b is String else b[1]
		if _of_kind(kind).is_empty():
			continue
		_shuffle(hosts)
		for host: Placed in hosts:
			var tip := _branch(host, kind, fill, rng.randi_range(0, 2))
			if tip != null:
				ends.append(tip)
				break
	_shuffle(hosts)
	for host: Placed in hosts:
		if _branch(host, "tesouro", "F", 0) != null:
			break
	_place_portals(ends)
	return true


func _branch(host: Placed, kind: String, fill: String, depth: int) -> Placed:
	var sides := ["T", "B", "R", "L"]
	var at := host
	var first_fill := fill
	var made: Array[Placed] = []
	for i in depth:
		_shuffle(sides)
		var mid := _attach(at, ["corredor", "combate"], sides, first_fill, "dead_end")
		if mid == null:
			break
		made.append(mid)
		at = mid
		first_fill = "."
	_shuffle(sides)
	var tip := _attach(at, [kind], sides, first_fill, "dead_end")
	if tip == null and not made.is_empty():
		return made[-1]
	return tip


# Portais: no começo, no meio do caminho e na ponta dos desvios. Com eles o
# herói volta de um desvio comprido sem refazer o caminho todo.
func _place_portals(ends: Array[Placed]) -> void:
	var picks: Array[Placed] = [main_path[0], main_path[main_path.size() / 2], main_path[-1]]
	_shuffle(ends)
	for e in ends:
		if picks.size() >= PORTALS + 1:
			break
		if not picks.has(e):
			picks.append(e)
	for p in picks:
		var c: Variant = p.t.spot_from(p.entry)
		if c != null:
			portals.append({"room": p, "cell": c})


# Prende uma sala nova numa porta livre de `host`.
#   mode "main": no caminho principal (a sala nova precisa ter por onde seguir)
#   mode "dead_end": desvio (precisa dar para voltar pela mesma porta)
#   mode "saida": a última sala
func _attach(host: Placed, kinds: Array, side_pref: Array, fill := ".", mode := "dead_end") -> Placed:
	var options: Array[RoomTemplate] = []
	for k: String in kinds:
		options.append_array(_of_kind(k))
	if options.is_empty():
		return null
	var door_order: Array[int] = []
	for side: String in side_pref:
		for i in host.t.doors.size():
			if host.t.doors[i]["side"] != side or host.used.has(i) or door_order.has(i):
				continue
			if mode == "dead_end" and not host.can_branch(i):
				continue
			if mode != "dead_end" and not host.t.connects(host.entry, i):
				continue
			door_order.append(i)
	for di in door_order:
		var dh: Dictionary = host.t.doors[di]
		var want: String = OPPOSITE[dh["side"]]
		for t in _weighted_shuffle(options):
			for dj in t.doors.size():
				var dn: Dictionary = t.doors[dj]
				if dn["side"] != want or not _fits(t, dj, mode):
					continue
				var pos := _place_for(host, dh, t, dn)
				var r := Rect2i(pos, Vector2i(t.width, t.height))
				if _overlaps(r):
					continue
				var p := Placed.new()
				p.t = t
				p.pos = pos
				p.entry = dj
				p.used[dj] = true
				host.used[di] = true
				if mode != "dead_end":
					host.exit = di
				placed.append(p)
				links.append({"a": host, "da": dh, "b": p, "db": dn, "fill": fill})
				return p
	return null


func _fits(t: RoomTemplate, dj: int, mode: String) -> bool:
	match mode:
		"main":
			for k in t.doors.size():
				if k != dj and t.connects(dj, k):
					return true
			return false
		"dead_end":
			return t.connects(dj, dj)
		"saida":
			return t.reaches_exit(dj)
	return true


func _place_for(host: Placed, dh: Dictionary, t: RoomTemplate, dn: Dictionary) -> Vector2i:
	var hp := host.pos
	match dh["side"]:
		"R":
			return Vector2i(hp.x + host.t.width, hp.y + dh["start"] + dh["size"] - dn["start"] - dn["size"])
		"L":
			return Vector2i(hp.x - t.width, hp.y + dh["start"] + dh["size"] - dn["start"] - dn["size"])
		"T":
			return Vector2i(hp.x + dh["start"] - dn["start"], hp.y - t.height)
		_:
			return Vector2i(hp.x + dh["start"] - dn["start"], hp.y + host.t.height)


func _overlaps(r: Rect2i) -> bool:
	for p in placed:
		if p.rect().intersects(r):
			return true
	return false


func _compose() -> PackedStringArray:
	var bounds := placed[0].rect()
	for p in placed:
		bounds = bounds.merge(p.rect())
	bounds = bounds.grow(MARGIN)
	var rows: Array = []
	for y in bounds.size.y:
		var row := []
		row.resize(bounds.size.x)
		row.fill("#")
		rows.append(row)

	for p in placed:
		for y in p.t.height:
			for x in p.t.width:
				var c := p.t.at(x, y)
				if c == "D":
					c = "#"
				rows[p.pos.y - bounds.position.y + y][p.pos.x - bounds.position.x + x] = c
		# Só o início fica com o "P".
		if p != placed[0]:
			for y in p.t.height:
				for x in p.t.width:
					if p.t.at(x, y) == "P":
						rows[p.pos.y - bounds.position.y + y][p.pos.x - bounds.position.x + x] = "."

	for link in links:
		var fill: String = link["fill"]
		for side in [["a", "da"], ["b", "db"]]:
			var p: Placed = link[side[0]]
			for c in p.t.door_cells(link[side[1]]):
				var gx := p.pos.x - bounds.position.x + c.x
				var gy := p.pos.y - bounds.position.y + c.y
				rows[gy][gx] = fill

	for portal in portals:
		var p: Placed = portal["room"]
		var c: Vector2i = portal["cell"]
		rows[p.pos.y - bounds.position.y + c.y][p.pos.x - bounds.position.x + c.x] = "O"

	var out := PackedStringArray()
	for row: Array in rows:
		out.append("".join(PackedStringArray(row)))
	return out
