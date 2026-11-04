class_name Mourner
extends Gargoyle

# Necrópole: espectro de capuz que chora os mortos. Plana acima de você e mergulha gritando.


func _init() -> void:
	super._init()
	title = "CARPIDEIRA"
	sheet = "mourner"
	max_hp = 40
	hp = 40
	w = 16
	h = 16
