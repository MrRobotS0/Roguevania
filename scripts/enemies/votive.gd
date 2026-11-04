class_name Votive
extends ShieldGuard

# Catedral Submersa: jurou guardar a nave. O escudo segura a frente; as costas, não.


func _init() -> void:
	super._init()
	title = "CAVALEIRO VOTIVO"
	sheet = "votive"
	max_hp = 70
	hp = 70
	w = 14
	h = 30
