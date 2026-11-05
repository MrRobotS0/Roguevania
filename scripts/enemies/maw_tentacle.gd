class_name MawTentacle
extends ThornPlant

# O Ventre: raiz de carne que não anda. Abre (aviso) e cospe dentes em arco.


func _init() -> void:
	super._init()
	title = "TENTÁCULO FAMINTO"
	sheet = "maw_tentacle"
	max_hp = 54
	hp = 54
	w = 18
	h = 34


var _sweep_cd := 0.0


func telegraphing() -> bool:
	return state in ["windup", "coil"]


# Perto da raiz não é ponto cego: ela se enrola e varre os dois lados.
func think(delta: float) -> void:
	_sweep_cd -= delta
	var d := to_player()
	match state:
		"coil":
			velocity.x = 0.0
			if state_time >= 0.45:
				strike(Rect2(global_position.x - 54.0, global_position.y - h, 108.0, h), 16.0, 240.0)
				Fx.burst(global_position + Vector2(0, -10), Color("c86a7a"), 14, 170.0, 0.35)
				Sfx.play("swing_heavy", -6.0)
				_sweep_cd = 2.2
				set_state("attack")
			return
	if state in ["idle", "chase"] and _sweep_cd <= 0.0 and absf(d.x) < 50.0 and absf(d.y) < 34.0:
		face_player()
		set_state("coil")
		return
	super.think(delta)


func sprite_anim() -> Array:
	if state == "coil":
		return ["windup", 0]
	return super.sprite_anim()
