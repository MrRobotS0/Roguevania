class_name Geyser
extends HazardEmitter

# Catedral Submersa: uma fresta no piso alagado borbulha e solta um jorro.


func _init() -> void:
	style = "water"
	every = 3.0
	proximity = 70.0
	width = 18.0
	height = 64.0
	damage = 14.0
	delay = 0.75
	linger = 0.5


func _draw() -> void:
	draw_rect(Rect2(-8, -2, 16, 2), Color("1a3a5a"))
	draw_rect(Rect2(-5, -2, 2, 1), Color("6ab8e8"))
	draw_rect(Rect2(3, -2, 2, 1), Color("6ab8e8"))
