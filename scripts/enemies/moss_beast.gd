class_name MossBeast
extends Enemy

# Fera-Musgo (Jardim Primordial): abaixa a cabeça (aviso) e dispara numa
# investida em linha reta. Bate na parede, fica tonta.

const CHARGE := 280.0


func _init() -> void:
	title = "FERA-MUSGO"
	sheet = "moss_beast"
	max_hp = 80
	hp = 80
	w = 26
	h = 20
	weight = 2.2
	poise = 0.4
	essence_drop = Vector2i(2, 4)


func telegraphing() -> bool:
	return state == "windup"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if sees_player(220.0, 40.0):
				set_state("chase")
		"chase":
			face_player()
			if absf(d.x) < 160.0 and absf(d.y) < 30.0:
				set_state("windup")
			else:
				velocity.x = 0.0 if blocked(facing) else facing * 40.0
		"windup":
			velocity.x = 0.0
			if state_time >= 0.6:
				set_state("charge")
				Sfx.play("swing_heavy", -6.0)
		"charge":
			velocity.x = facing * CHARGE
			strike(front_rect(14.0, h, 0.0), 20, 240.0)
			if is_on_wall() or blocked(facing) or state_time > 1.4:
				velocity.x = 0.0
				if is_on_wall():
					Fx.add_shake(3.0)
					stagger(1.0)
				else:
					set_state("rest")
		"rest":
			if state_time >= 0.6:
				set_state("chase")


func sprite_anim() -> Array:
	match state:
		"windup", "rest", "stun":
			return ["windup", 0]
		"charge":
			return ["charge", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]
