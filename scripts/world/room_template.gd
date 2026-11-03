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
