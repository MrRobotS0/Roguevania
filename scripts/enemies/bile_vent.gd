class_name BileVent
extends HazardEmitter

# O Ventre: um poro na carne incha e cospe bile para cima, de tempos em tempos.


func _init() -> void:
	style = "bile"
	every = 2.4
	width = 16.0
	height = 50.0
	damage = 16.0
	delay = 0.7
	linger = 0.45


func _draw() -> void:
	draw_rect(Rect2(-7, -3, 14, 3), Color("5a1a20"))
	draw_rect(Rect2(-3, -4, 6, 1), Color("c8d040"))
