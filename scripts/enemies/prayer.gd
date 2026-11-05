class_name Prayer
extends LivingLens

# Catedral Submersa: uma prece que ficou boiando e aprendeu a mirar. Trava o fio antes do choque.


func _init() -> void:
	super._init()
	title = "PRECE VIVA"
	sheet = "prayer"
	max_hp = 36
	hp = 36
	w = 22
	h = 30


# O fio é a prece; as duas luzes que saem junto seguem você por um tempo.
func _fire() -> void:
	super._fire()
	for side: int in [-1, 1]:
		shoot("glyph", center(), _aim.rotated(side * 0.8) * 115.0, 9.0, Color("6ae88a"), 0.0, 1.5, 2.6)
