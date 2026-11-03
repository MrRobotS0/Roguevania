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

	func rect() -> Rect2i:
		return Rect2i(pos, Vector2i(t.width, t.height))


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


func _try_build(combat_rooms: int) -> bool:
	placed.clear()
	links.clear()
	main_path.clear()

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
		var next := _attach(current, [kind] if kind != "corredor" else ["corredor", "combate"], ["R", "B"])
		if next == null:
			return false
		main_path.append(next)
		current = next

	# Desvios presos ao caminho principal (se couberem).
	var hosts := main_path.slice(1, main_path.size() - 1)
	for b in branches:
		var kind: String = b if b is String else b[0]
		var fill: String = "." if b is String else b[1]
		if _of_kind(kind).is_empty():
			continue
		_shuffle(hosts)
		for host: Placed in hosts:
			if _attach(host, [kind], ["T", "B", "R", "L"], fill) != null:
				break
	_shuffle(hosts)
	for host: Placed in hosts:
		if _attach(host, ["tesouro"], ["T", "B", "L", "R"], "F") != null:
			break
	return true


# Tenta prender uma sala nova numa porta livre de `host`.
func _attach(host: Placed, kinds: Array, side_pref: Array, fill := ".") -> Placed:
	var options: Array[RoomTemplate] = []
	for k: String in kinds:
		options.append_array(_of_kind(k))
	if options.is_empty():
		return null
	var door_order: Array[int] = []
	for side: String in side_pref:
		for i in host.t.doors.size():
			if host.t.doors[i]["side"] == side and not host.used.has(i) and not door_order.has(i):
				door_order.append(i)
	for di in door_order:
		var dh: Dictionary = host.t.doors[di]
		var want: String = OPPOSITE[dh["side"]]
		for t in _weighted_shuffle(options):
			for dj in t.doors.size():
				var dn: Dictionary = t.doors[dj]
				if dn["side"] != want:
					continue
				var pos := _place_for(host, dh, t, dn)
				var r := Rect2i(pos, Vector2i(t.width, t.height))
				if _overlaps(r):
					continue
				var p := Placed.new()
				p.t = t
				p.pos = pos
				p.used[dj] = true
				host.used[di] = true
				placed.append(p)
				links.append({"a": host, "da": dh, "b": p, "db": dn, "fill": fill})
				return p
	return null


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

	var out := PackedStringArray()
	for row: Array in rows:
		out.append("".join(PackedStringArray(row)))
	return out
