class_name Nightmare
extends MossBeast

# Penhascos do Sonho: o cavalo de fogo azul que corre por cima de quem dorme. Abaixa a cabeça e dispara.


func _init() -> void:
	super._init()
	title = "PESADELO"
	sheet = "nightmare"
	max_hp = 66
	hp = 66
	w = 28
	h = 26


var _trail := 0.0


# Onde o pesadelo corre, o chão queima logo depois.
func think(delta: float) -> void:
	super.think(delta)
	if state == "charge":
		_trail -= delta
		if _trail <= 0.0:
			_trail = 0.1
			make_hazard("dream", global_position.x - facing * 14.0, 0.45, 10.0, 18.0, 20.0, true)
