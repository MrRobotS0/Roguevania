class_name Interactable
extends Node2D

# Base de tudo que se usa com E (ou ↑ no controle): itens no chão, altares,
# inscrições, saídas, a Vigia. O HUD mostra prompt() quando o herói chega perto.

var level: Node
var reach := 0.0     # desenhos largos: alcance a mais para usar
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


# Corpo em sprite (folha "props" de tools/gen_props.py). Fica atrás do que o
# objeto desenha em código (brilho, item flutuando, chama).
func prop(anim: String, index := 0) -> Sprite2D:
	var s := SpriteSheet.region_sprite("props", props_palette(), anim, index)
	s.show_behind_parent = true
	add_child(s)
	return s


static func props_palette() -> PackedColorArray:
	var stone := Color("6b5f58")
	var iron := Color("3a3236")
	var cloth := Color("2b2f3a")
	var wood := Color("5b3f2c")
	return PackedColorArray([
		Color(0, 0, 0, 0), Color("0b0910"),
		stone.lightened(0.25), stone, stone.darkened(0.35),
		iron.lightened(0.3), iron, iron.darkened(0.4),
		Color("d9a93f"),
		cloth.lightened(0.25), cloth, cloth.darkened(0.4),
		Color("9fe8ff"), wood, wood.darkened(0.4), Color("f2c14e"),
	])
