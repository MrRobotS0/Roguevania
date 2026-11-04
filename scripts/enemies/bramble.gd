class_name Bramble
extends HazardEmitter

# Bosque Errante: a estrada não quer que você passe. Um espinheiro brota do chão.


func _init() -> void:
	style = "vine"
	every = 2.2
	proximity = 56.0
	follow = true
	width = 18.0
	height = 34.0
	damage = 14.0
	delay = 0.6


func _draw() -> void:
	var c := Color("4a6a2a")
	c.a = 0.45
	draw_rect(Rect2(-8, -1, 16, 1), c)
