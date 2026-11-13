class_name ContactShadow
extends Node2D

# Sombra de contato: um elipse escuro no chão embaixo do personagem. Pisando,
# fica colada nos pés; no ar, fica no chão lá embaixo e encolhe com a altura.
# Dá peso aos corpos e mostra onde um pulo vai cair.

const REACH := 96.0

var who: Actor
var _ground := 0.0       # distância até o chão (0 = pisando); <0 = sem chão perto


func _ready() -> void:
	who = get_parent() as Actor
	show_behind_parent = true
	z_index = -1


func _physics_process(_delta: float) -> void:
	if who == null or not who.is_inside_tree():
		return
	var space := who.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(who.global_position + Vector2(0, -2), who.global_position + Vector2(0, REACH), Room.WORLD_LAYER | Room.PLATFORM_LAYER)
	q.exclude = [who.get_rid()]
	var hit := space.intersect_ray(q)
	var before := _ground
	_ground = (hit["position"].y - who.global_position.y) if hit else -1.0
	if absf(before - _ground) > 0.5:
		queue_redraw()


func _draw() -> void:
	if who == null or _ground < 0.0 or not Options.get_value("postfx"):
		return
	var k := 1.0 - clampf(_ground / REACH, 0.0, 1.0)
	var half := roundf(maxf(who.w * 0.75 * (0.45 + 0.55 * k), 3.0))
	var a := 0.42 * k
	var y := roundf(_ground)
	# três faixas: miolo mais escuro, bordas mais claras (elipse em pixels)
	draw_rect(Rect2(-half, y - 1, half * 2, 2), Color(0, 0, 0, a * 0.55))
	draw_rect(Rect2(-half + 2, y - 2, half * 2 - 4, 3), Color(0, 0, 0, a * 0.6))
	draw_rect(Rect2(-half + 4, y - 1, half * 2 - 8, 1), Color(0, 0, 0, a))
