class_name Highwayman
extends Dancer

# Bosque Errante: o salteador da estrada. Gira a espada (aviso) e cruza o
# caminho num corte só. Depois fica tonto: é a hora.


func _init() -> void:
	super._init()
	title = "SALTEADOR"
	sheet = "highwayman"
	max_hp = 58
	hp = 58
	w = 12
	h = 30
