class_name GraveCat
extends Wolf

# Necrópole: o gato-sombra que come as oferendas. Abaixa antes do bote.


func _init() -> void:
	super._init()
	title = "FOME DAS COVAS"
	sheet = "grave_cat"
	max_hp = 40
	hp = 40
	w = 26
	h = 16
