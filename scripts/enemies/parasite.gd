class_name Parasite
extends Wolf

# O Ventre: aranha que mora dentro da carne. Abaixa e salta.


func _init() -> void:
	super._init()
	title = "PARASITA"
	sheet = "parasite"
	max_hp = 32
	hp = 32
	w = 22
	h = 14
