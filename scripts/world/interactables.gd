class_name Interactable
extends Node2D

# Base de tudo que se usa com E (ou ↑ no controle): itens no chão, altares,
# inscrições, saídas, a Vigia. O HUD mostra prompt() quando o herói chega perto.

var level: Node
var _t := 0.0


func _ready() -> void:
	add_to_group("interactables")
	z_index = 2


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func can_interact(_p: Player) -> bool:
	return visible


func prompt() -> String:
	return ""


func detail() -> String:
	return ""


func interact(_p: Player) -> void:
	pass


func menu() -> Node:
	return get_tree().get_first_node_in_group("menu")
