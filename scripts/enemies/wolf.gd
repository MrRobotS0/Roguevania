class_name Wolf
extends Enemy

# Lobo Pálido: rápido. Para de correr, abaixa (aviso) e investe mordendo em
# linha reta. Rolar por baixo do bote ou bater durante o aviso.

const RUN := 145.0
const LUNGE := 330.0
const CROUCH := 0.4
const BITE := 16.0

var _hit := false


func _init() -> void:
	title = "LOBO PÁLIDO"
	sheet = "wolf"
	max_hp = 44
	hp = 44
	w = 22
	h = 14
	weight = 1.0
	essence_drop = Vector2i(2, 3)


func body_color() -> Color:
	return Color("c8d4e0")


func telegraphing() -> bool:
	return state == "crouch"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if sees_player(240.0, 60.0):
				set_state("chase")
		"chase":
			face_player()
			if absf(d.x) < 90.0 and absf(d.y) < 24.0 and is_on_floor():
				velocity.x = 0.0
				set_state("crouch")
			elif blocked(facing):
				velocity.x = 0.0
			else:
				velocity.x = facing * RUN
		"crouch":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_time >= CROUCH:
				_hit = false
				velocity = Vector2(facing * LUNGE, -110.0)
				set_state("lunge")
				Sfx.play("wolf_bite", -4.0)
		"lunge":
			if not _hit:
				_hit = strike(front_rect(16.0, 14.0, 0.0), BITE, 180.0)
			if state_time > 0.15 and is_on_floor():
				velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
				if absf(velocity.x) < 10.0:
					set_state("rest")
		"rest":
			if state_time >= 0.55:
				set_state("chase")


func sprite_anim() -> Array:
	match state:
		"crouch", "rest":
			return ["crouch", 0]
		"lunge":
			return ["lunge", 0]
		"stun":
			return ["stun", 0]
	if absf(velocity.x) > 10.0:
		return ["run", int(_anim * 12.0)]
	return ["idle", int(_anim * 2.0)]
