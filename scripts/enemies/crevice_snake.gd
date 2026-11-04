class_name CreviceSnake
extends Assassin

# Cavernas Fundas: mora na fenda do chão e sobe num bote.


func _init() -> void:
	super._init()
	title = "SERPENTE DA FENDA"
	sheet = "crevice_snake"
	max_hp = 40
	hp = 40
	w = 12
	h = 22
