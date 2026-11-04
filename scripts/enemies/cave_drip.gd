class_name CaveDrip
extends Icicle

# Cavernas Fundas: uma ponta de rocha molhada se solta do teto em quem passa.


func _draw() -> void:
	if _state == "gone":
		return
	var shake := randf_range(-1.0, 1.0) if _state == "shake" else 0.0
	var rock := Color("4a4a5a")
	draw_colored_polygon(PackedVector2Array([Vector2(-5 + shake, _y), Vector2(5 + shake, _y), Vector2(shake, _y + 14)]), rock)
	draw_rect(Rect2(-5 + shake, _y, 10, 1), rock.lightened(0.3))
	draw_rect(Rect2(-1 + shake, _y + 10, 1, 2), Color("8ac8e8"))
