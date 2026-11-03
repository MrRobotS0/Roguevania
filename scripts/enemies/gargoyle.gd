class_name Gargoyle
extends Enemy

# Gárgula (Torre de Babel): voa, paira acima do herói e mergulha em
# diagonal. Depois do mergulho sobe devagar: é a hora de bater.

const HOVER := 70.0
const DIVE := 300.0

var _dive_dir := Vector2.ZERO


func _init() -> void:
	title = "GÁRGULA"
	sheet = "gargoyle"
	max_hp = 38
	hp = 38
	w = 16
	h = 14
	uses_gravity = false
	essence_drop = Vector2i(2, 3)


func _ready() -> void:
	super._ready()
	collision_mask = Room.WORLD_LAYER


func telegraphing() -> bool:
	return state == "windup"


func think(delta: float) -> void:
	var target := player.center() + Vector2(-signf(to_player().x) * 40.0, -HOVER)
	match state:
		"idle":
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			if sees_player(220.0, 200.0):
				set_state("chase")
		"chase":
			face_player()
			velocity = velocity.lerp((target - global_position).limit_length(1.0) * 90.0, 1.0 - exp(-3.0 * delta))
			if state_time > 1.4 and global_position.distance_to(target) < 30.0:
				set_state("windup")
		"windup":
			velocity = velocity.move_toward(Vector2(0, -20), 300.0 * delta)
			face_player()
			if state_time >= 0.5:
				_dive_dir = (player.center() - center()).normalized()
				set_state("dive")
				Sfx.play("swing", -6.0)
		"dive":
			velocity = _dive_dir * DIVE
			strike(hurt_rect().grow(3.0), 15, 160.0)
			if state_time > 0.7 or is_on_floor() or is_on_wall():
				set_state("climb")
		"climb":
			velocity = Vector2(0, -50)
			if state_time > 1.0:
				set_state("chase")
		"stun":
			velocity.y = 30.0


func sprite_anim() -> Array:
	match state:
		"windup":
			return ["windup", 0]
		"dive":
			return ["dive", 0]
	return ["fly", int(_anim * 10.0)]
