class_name TendrilRoot
extends HazardEmitter

# Carcosa: o chão escurece e um tentáculo sobe onde você pisou.


func _init() -> void:
	style = "tendril"
	every = 2.4
	proximity = 60.0
	follow = true
	height = 52.0
	damage = 18.0


func _draw() -> void:
	var c := Color("5a2a7a")
	c.a = 0.5
	draw_rect(Rect2(-8, -1, 16, 1), c)
