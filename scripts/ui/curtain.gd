class_name Curtain
extends Node2D

# Entrada de fase: a tela começa escura e abre em pontilhado (padrão
# ordenado 4x4), como pixel art, sem degradê borrado.

const TIME := 0.45
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var _t := TIME


func reveal() -> void:
	_t = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if _t < TIME:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if _t >= TIME:
		return
	var k := 1.0 - _t / TIME
	var size := get_viewport_rect().size
	var ink := Color("07060b")
	if k > 0.97:
		draw_rect(Rect2(Vector2.ZERO, size), ink)
		return
	# cada célula 4x4 apaga os pontos cujo limiar já passou
	var cell := 4
	for by in range(0, int(size.y), cell * 4):
		for bx in range(0, int(size.x), cell * 4):
			for i in 16:
				if BAYER[i] / 16.0 < k:
					draw_rect(Rect2(bx + (i % 4) * cell, by + (i / 4) * cell, cell, cell), ink)
