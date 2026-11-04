class_name Risen
extends Assassin

# Necrópole: dorme debaixo da terra da cova. A terra que se mexe é ele.


func _init() -> void:
	super._init()
	title = "MORTO DESPERTO"
	sheet = "risen"
	max_hp = 46
	hp = 46
	w = 12
	h = 30
