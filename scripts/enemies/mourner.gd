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


# Depois de cada mergulho ela chora: três lamentos lentos em leque.
func think(delta: float) -> void:
	var before := state
	super.think(delta)
	if before == "dive" and state == "climb":
		var aim := (player.center() - center()).normalized()
		for i in 3:
			shoot("glyph", center(), aim.rotated((i - 1) * 0.42) * 105.0, 10.0, Color("a8c0e8"))
		Sfx.play("gargoyle_screech", -14.0)
