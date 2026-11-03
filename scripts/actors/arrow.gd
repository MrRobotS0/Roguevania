class_name Arrow
extends Node2D

var room: Room
var velocity := Vector2.ZERO
var damage := 12
var _life := 3.0


func _ready() -> void:
	z_index = 6


func _physics_process(delta: float) -> void:
	_life -= delta
	position += velocity * delta
	if _life <= 0.0 or room.is_solid_at(global_position):
		Fx.burst(global_position, Palette.ARROW, 4, 60.0, 0.25)
		queue_free()
		return
	for p: Player in get_tree().get_nodes_in_group("player"):
		if p.hurt_rect().has_point(global_position):
			if p.take_damage(damage, int(signf(velocity.x))):
				queue_free()
				return
	queue_redraw()


func _draw() -> void:
	var dir := velocity.normalized()
	draw_line(-dir * 9.0, Vector2.ZERO, Palette.ARROW, 1.0)
	draw_line(-dir * 9.0, -dir * 7.0 + dir.orthogonal() * 2.0, Palette.UI_DIM, 1.0)
	draw_rect(Rect2(dir * 1.0 - Vector2(1, 1), Vector2(2, 2)), Palette.BLADE)
