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


var small := false


func _ready() -> void:
	if small:
		max_hp = 9
		hp = 9
		w = 9
		h = 8
		essence_drop = Vector2i(0, 0)
		hop_every = 0.45
	super._ready()
	add_to_group("larvas")
	if small:
		_draw_scale *= 0.62


# Cortada ao meio, vira duas menores (além da poça).
func _die() -> void:
	if not small and is_inside_tree():
		for side: int in [-1, 1]:
			var kid := Larva.new()
			kid.small = true
			kid.room = room
			kid.player = player
			kid.position = global_position + Vector2(side * 8.0, -2.0)
			kid.velocity = Vector2(side * 70.0, -160.0)
			get_parent().add_child.call_deferred(kid)
	super._die()
