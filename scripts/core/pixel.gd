class_name Pixel
extends RefCounted

# Formas na grade do pixel do jogo.
# draw_colored_polygon e draw_line desenham na resolução da tela: com a câmera
# lisa (4 pixels de tela para cada pixel do jogo) o arco do golpe e a flecha
# saíam lisos no meio da pixel art. Aqui a forma é varrida linha por linha, como
# num rasterizador de 1 pixel do jogo, e sai em retângulos inteiros. De quebra,
# retângulo entra em lote e polígono nunca entra (cada um era um desenho à parte).
# As coordenadas são as do nó que desenha: a grade é a do próprio sprite dele.


# Polígono qualquer (côncavo também), regra par-ímpar, amostrado no meio de cada linha.
static func polygon(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	var n := points.size()
	if n < 3:
		return
	var top := points[0].y
	var bottom := top
	for p in points:
		top = minf(top, p.y)
		bottom = maxf(bottom, p.y)
	var xs := PackedFloat32Array()
	for y in range(floori(top), ceili(bottom)):
		var sy := y + 0.5
		xs.clear()
		for i in n:
			var a := points[i]
			var b := points[(i + 1) % n]
			if (a.y <= sy) != (b.y <= sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var x0 := roundf(xs[k])
			var x1 := roundf(xs[k + 1])
			if x1 <= x0 and xs[k + 1] - xs[k] >= 0.4:
				# ponta fina: não some, vira 1 pixel
				x0 = floorf((xs[k] + xs[k + 1]) * 0.5)
				x1 = x0 + 1.0
			if x1 > x0:
				ci.draw_rect(Rect2(x0, y, x1 - x0, 1), color)
			k += 2


# Linha de 1 pixel (ou `width`) em degraus; os pixels seguidos na mesma linha ou
# coluna viram um retângulo só.
static func line(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width := 1) -> void:
	var a := Vector2i(from.round())
	var b := Vector2i(to.round())
	var d := (b - a).abs()
	var steps := maxi(d.x, d.y)
	var flat := d.x >= d.y
	var start := a
	var prev := a
	for i in range(1, steps + 1):
		var p := Vector2i(Vector2(a).lerp(Vector2(b), float(i) / steps).round())
		if (p.y if flat else p.x) != (prev.y if flat else prev.x):
			_run(ci, start, prev, color, width)
			start = p
		prev = p
	_run(ci, start, prev, color, width)


static func polyline(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	for i in points.size() - 1:
		line(ci, points[i], points[i + 1], color)


static func _run(ci: CanvasItem, from: Vector2i, to: Vector2i, color: Color, width: int) -> void:
	var corner := Vector2(mini(from.x, to.x), mini(from.y, to.y))
	var size := Vector2(absi(to.x - from.x) + width, absi(to.y - from.y) + width)
	ci.draw_rect(Rect2(corner, size), color)
