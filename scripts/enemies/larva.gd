class_name Larva
extends Slag

# O Ventre: pula atrás de você e queima com ácido. Morta, vira poça.


func _init() -> void:
	super._init()
	title = "LARVA DO VENTRE"
	sheet = "larva"
	max_hp = 30
	hp = 30
	w = 14
	h = 12
	hop_every = 0.6
	hop_reach = 1.4
