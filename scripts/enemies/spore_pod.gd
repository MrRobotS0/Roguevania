class_name SporePod
extends HazardEmitter

# Jardim Primordial: um casulo no chão estoura numa nuvem de esporos quando
# alguém passa perto.


func _init() -> void:
	style = "spore"
	every = 3.2
	proximity = 50.0
	width = 44.0
	height = 36.0
	damage = 12.0
	delay = 0.5
	linger = 1.0


func _draw() -> void:
	draw_rect(Rect2(-4, -5, 8, 5), Color("6a8a3a"))
	draw_rect(Rect2(-3, -6, 6, 1), Color("b8d05a"))
