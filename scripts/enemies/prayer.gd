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
