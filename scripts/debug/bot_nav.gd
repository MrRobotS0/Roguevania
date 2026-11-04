class_name BotNav
extends RefCounted

# Mapa de onde o herói pode ficar em pé e como ir de um lugar ao outro, com
# o mesmo alcance do verificador de salas (tools/validar_salas.py): anda,
# cai, desce da plataforma, pula até 3 blocos e agarra a beirada no 4º.
# Usado só pelo robô que joga sozinho.

const JUMP_UP := 3
const LEDGE_UP := 4

var room: Room
var _edges := {}      # Vector2i -> Array[[Vector2i, tipo]]


func build(r: Room) -> void:
	room = r
	_edges.clear()
	for y in room.rows:
		for x in room.cols:
			if stand(x, y):
				_edges[Vector2i(x, y)] = _moves(x, y)


func open_at(x: int, y: int) -> bool:
	return not room.is_solid(x, y)


func stand(x: int, y: int) -> bool:
	if x < 0 or y < 1 or x >= room.cols or y >= room.rows - 1:
		return false
	var below := room.cell(x, y + 1)
	return open_at(x, y) and open_at(x, y - 1) and (below == Room.SOLID or below == Room.CRACKED or below == Room.PLATFORM)


func _fall(x: int, y: int) -> Variant:
	while y < room.rows - 1:
		if stand(x, y):
			return Vector2i(x, y)
		if not open_at(x, y + 1):
			return null
		y += 1
	return null


func _clear_column(x: int, a: int, b: int) -> bool:
	for y in range(mini(a, b), maxi(a, b) + 1):
		if not open_at(x, y):
			return false
	return true


func _moves(x: int, y: int) -> Array:
	var out: Array = []
	for dx: int in [-1, 1]:
		if stand(x + dx, y):
			out.append([Vector2i(x + dx, y), "walk"])
		elif open_at(x + dx, y) and open_at(x + dx, y - 1):
			var f: Variant = _fall(x + dx, y)
			if f != null:
				out.append([f, "fall"])
	if room.cell(x, y + 1) == Room.PLATFORM:
		var f: Variant = _fall(x, y + 1)
		if f != null:
			out.append([f, "drop"])
	for dy in range(-8, LEDGE_UP + 1):
		for dx in range(-5, 6):
			if dx == 0 and dy <= 0:
				continue
			var tx := x + dx
			var ty := y - dy
			if not stand(tx, ty):
				continue
			var reach := 5 if dy <= 0 else (4 if dy <= 2 else 3)
			if absi(dx) > reach:
				continue
			if dy > JUMP_UP:
				if absi(dx) > 1 or not room.is_solid(tx, ty + 1):
					continue
			var top := mini(y, ty) - 1
			if not _clear_column(x, y, top) or not _clear_column(tx, ty, top):
				continue
			var blocked := false
			var step := 1 if tx > x else -1
			var mx := x + step
			while mx != tx:
				if not _clear_column(mx, top, top + 1):
					blocked = true
					break
				mx += step
			if blocked:
				continue
			if absi(dx) <= 1 and dy <= 0:
				continue
			out.append([Vector2i(tx, ty), "jump"])
	return out


# Célula onde o herói está em pé (ou a mais perto embaixo dele, no ar).
func cell_of(p: Vector2) -> Vector2i:
	var c := Vector2i(floori(p.x / Room.TILE), floori((p.y - 2.0) / Room.TILE))
	for i in 6:
		if _edges.has(c + Vector2i(0, i)):
			return c + Vector2i(0, i)
	for dx: int in [-1, 1]:
		if _edges.has(c + Vector2i(dx, 0)):
			return c + Vector2i(dx, 0)
	return c


func knows(c: Vector2i) -> bool:
	return _edges.has(c)


# Caminho (lista de [célula, tipo]) até a célula mais perto do alvo que
# esteja a até `near` blocos dele. Vazio = não tem como chegar.
func path(from: Vector2i, goal: Vector2i, near := 1) -> Array:
	if not _edges.has(from):
		return []
	var came := {from: null}
	var how := {}
	var queue: Array[Vector2i] = [from]
	var head := 0
	var best: Variant = null
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if absi(c.x - goal.x) <= near and absi(c.y - goal.y) <= near + 1:
			best = c
			break
		for e: Array in _edges[c]:
			var n: Vector2i = e[0]
			if not came.has(n):
				came[n] = c
				how[n] = e[1]
				queue.append(n)
	if best == null:
		return []
	var out: Array = []
	var c: Vector2i = best
	while came[c] != null:
		out.push_front([c, how[c]])
		c = came[c]
	return out


static func center_of(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * Room.TILE, (c.y + 1) * Room.TILE)
