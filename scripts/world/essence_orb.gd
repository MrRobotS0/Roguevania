class_name EssenceOrb
extends Node2D

# Essência que sai dos inimigos: espirra, cai e é atraída pelo herói.

var player: Player
var room: Room
var velocity := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	z_index = 7
	Glow.attach(self, Palette.ESSENCE, 22.0, 0.7)
	velocity = Vector2(randf_range(-90, 90), randf_range(-200, -110))


func _physics_process(delta: float) -> void:
	_t += delta
	if not is_instance_valid(player):
		queue_free()
		return
	var to := player.center() - global_position
	if _t > 0.35 and to.length() < 90.0:
		velocity = velocity.lerp(to.normalized() * 260.0, 1.0 - exp(-10.0 * delta))
		position += velocity * delta
	else:
		velocity.y = minf(velocity.y + 700.0 * delta, 300.0)
		var next := position + velocity * delta
		if room.is_ground_at(next + Vector2(0, 2)) and velocity.y > 0.0:
			velocity = Vector2(velocity.x * 0.5, 0.0)
		else:
			position = next
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
	if to.length() < 8.0 and player.alive():
		player.add_essence(1)
		Sfx.play("essence", -14.0, 0.2)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var c := Palette.ESSENCE
	c.a = 0.6 + 0.4 * sin(_t * 12.0)
	draw_rect(Rect2(-1, -1, 3, 3), c)
	draw_rect(Rect2(0, 0, 1, 1), Palette.FLASH)
