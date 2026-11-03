class_name MeteorMark
extends HazardEmitter

# Observatório: de tempos em tempos, uma estrela cai onde você está. O chão
# brilha antes.


func _init() -> void:
	style = "light"
	every = 4.0
	proximity = 200.0
	follow = true
	width = 20.0
	height = 160.0
	damage = 18.0
	delay = 0.9
