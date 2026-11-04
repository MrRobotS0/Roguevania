class_name DreamFlash
extends HazardEmitter

# Penhascos do Sonho: o ar sobre você brilha e um lampejo do sonho desce.


func _init() -> void:
	style = "dream"
	every = 3.4
	follow = true
	width = 20.0
	height = 70.0
	damage = 16.0
	delay = 0.9
	linger = 0.35
