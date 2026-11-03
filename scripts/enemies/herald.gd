class_name Herald
extends Enemy

# Arauto Pálido (Carcosa): toca o sino e chama duas almas que flutuam até
# você e estouram. Sozinho é fraco: chegue nele.

var _cd := 1.0


func _init() -> void:
	title = "ARAUTO PÁLIDO"
	sheet = "herald"
	max_hp = 40
	hp = 40
	w = 10
	h = 24
	essence_drop = Vector2i(2, 3)


func telegraphing() -> bool:
	return state == "cast"


func think(delta: float) -> void:
	_cd -= delta
	match state:
		"idle", "chase":
			face_player()
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if _cd <= 0.0 and sees_player(240.0, 100.0) and _wisps() < 3:
				set_state("cast")
		"cast":
			if state_time >= 0.8:
				_cd = 4.0
				for i in 2:
					var w2 := FallenStar.new()
					w2.look = "wisp"
					w2.room = room
					w2.player = player
					w2.essence_drop = Vector2i(0, 0)
					w2.position = global_position + Vector2((i * 2 - 1) * 18.0, -22.0)
					get_parent().add_child(w2)
				Sfx.play("bell", -4.0)
				set_state("idle")


func _wisps() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is FallenStar:
			n += 1
	return n


func sprite_anim() -> Array:
	if state == "cast":
		return ["cast", int(state_time * 6.0)]
	return ["idle", int(_anim * 2.0)]
