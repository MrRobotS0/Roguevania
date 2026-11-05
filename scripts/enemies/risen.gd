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


var _rose := false


# Morto uma vez, volta para a cova e levanta de novo com metade da vida.
func _die() -> void:
	if _rose:
		super._die()
		return
	_rose = true
	hp = ceili(max_hp * 0.5)
	_shown_hp = hp
	statuses.clear()
	ghost = true
	velocity = Vector2.ZERO
	set_state("sink")
	Fx.burst(center(), Palette.DUST, 16, 120.0, 0.5, 300.0, 2.0, 40.0)
	Sfx.play("burrow", -4.0)
