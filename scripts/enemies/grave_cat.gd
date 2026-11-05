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


var _second := false


# Nunca morde uma vez só: errou ou acertou, emenda o segundo bote mais rápido.
func think(delta: float) -> void:
	var before := state
	super.think(delta)
	if before == "lunge" and state == "rest" and not _second:
		_second = true
		face_player()
		set_state("crouch")
		state_time = CROUCH - 0.18
	elif state == "chase":
		_second = false
