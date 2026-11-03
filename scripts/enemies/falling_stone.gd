class_name FallingStone
extends Icicle

# Torre de Babel: um bloco solto no teto. Treme e cai em quem passa embaixo.


func _draw() -> void:
	if _state == "gone":
		return
	var shake := randf_range(-1.0, 1.0) if _state == "shake" else 0.0
	var stone := Color("a89878")
	draw_rect(Rect2(-6 + shake, _y, 12, 10), stone)
	draw_rect(Rect2(-6 + shake, _y, 12, 1), stone.lightened(0.3))
	draw_rect(Rect2(-6 + shake, _y + 9, 12, 1), stone.darkened(0.4))
	draw_rect(Rect2(-1 + shake, _y + 3, 1, 4), stone.darkened(0.4))
