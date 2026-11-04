class_name Sleepwalker
extends Archer

# Penhascos do Sonho: atira dormindo. A mira trava um instante antes da flecha.


func _init() -> void:
	super._init()
	title = "SONÂMBULA"
	sheet = "sleepwalker"
	max_hp = 44
	hp = 44
	w = 12
	h = 28
