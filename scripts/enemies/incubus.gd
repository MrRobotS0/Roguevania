class_name Incubus
extends Masked

# Penhascos do Sonho: some e aparece atrás de você, como num sonho ruim.


func _init() -> void:
	super._init()
	title = "ÍNCUBO"
	sheet = "incubus"
	max_hp = 52
	hp = 52
	w = 16
	h = 34


var _chained := false


# Dois sumiços seguidos, e o lugar de onde ele saiu estoura.
func think(delta: float) -> void:
	var before := state
	super.think(delta)
	if state == "vanish" and before != "vanish":
		make_hazard("dream", global_position.x, 0.5, 14.0, 24.0, 46.0)
	if before == "attack" and state == "chase":
		if not _chained:
			_chained = true
			set_state("vanish")
			make_hazard("dream", global_position.x, 0.5, 14.0, 24.0, 46.0)
		else:
			_chained = false
