class_name Masked
extends Enemy

# Mascarado (Carcosa): some e reaparece atrás de você, e corta. A máscara
# brilha um instante antes do golpe.

const REACH := 34.0


func _init() -> void:
	title = "MASCARADO"
	sheet = "masked"
	max_hp = 52
	hp = 52
	w = 10
	h = 24
	essence_drop = Vector2i(2, 4)

var _alpha := 1.0
var _done := false


func telegraphing() -> bool:
	return state == "windup"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			if sees_player(220.0, 60.0):
				set_state("chase")
		"chase":
			face_player()
			velocity.x = 0.0 if blocked(facing) else facing * 85.0
			if absf(d.x) < 150.0 and state_time > 1.0:
				set_state("vanish")
		"vanish":
			velocity.x = 0.0
			if state_time == 0.0 or state_time < get_physics_process_delta_time():
				Sfx.play("teleport", -8.0)
			_alpha = 1.0 - clampf(state_time / 0.25, 0.0, 1.0)
			if state_time >= 0.25:
				var side := 1 if player.facing > 0 else -1
				var x := player.global_position.x - side * 26.0
				if not room.is_solid_at(Vector2(x, player.global_position.y - 8.0)):
					global_position = Vector2(x, player.global_position.y)
				face_player()
				set_state("windup")
		"windup":
			_alpha = clampf(state_time / 0.2, 0.0, 1.0)
			if state_time >= 0.4:
				_done = false
				set_state("attack")
				Sfx.play("swing", -6.0)
		"attack":
			if not _done:
				_done = strike(front_rect(REACH, 26.0), 18, 200.0) or true
			if state_time >= 0.4:
				set_state("chase")


func hurt(dmg: Damage) -> bool:
	if _alpha < 0.4:
		return false
	return super.hurt(dmg)


func sprite_anim() -> Array:
	body.modulate.a = _alpha
	match state:
		"windup":
			return ["windup", 0]
		"attack":
			return ["attack", 0]
		"vanish":
			return ["cast", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]
