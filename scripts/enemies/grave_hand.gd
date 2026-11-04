class_name GraveHand
extends HazardEmitter

# Necrópole: a terra afunda onde você pisou e uma mão de osso sobe da cova.


func _init() -> void:
	style = "bone"
	every = 2.6
	proximity = 64.0
	follow = true
	width = 14.0
	height = 40.0
	damage = 15.0
	delay = 0.65


func _draw() -> void:
	var c := Color("e8e0c8")
	c.a = 0.35
	draw_rect(Rect2(-7, -1, 14, 1), c)
