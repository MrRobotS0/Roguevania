class_name Votive
extends ShieldGuard

# Catedral Submersa: jurou guardar a nave. O escudo segura a frente; as costas, não.


func _init() -> void:
	super._init()
	title = "CAVALEIRO VOTIVO"
	sheet = "votive"
	max_hp = 70
	hp = 70
	w = 14
	h = 30


const BASH_SPEED := 300.0

var _bash_cd := 1.5


func telegraphing() -> bool:
	return state in ["windup", "vow"]


# Cumpre o voto: de média distância ergue o escudo e atropela. Bate na parede, fica tonto.
func think(delta: float) -> void:
	_bash_cd -= delta
	match state:
		"vow":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if state_time >= 0.55:
				set_state("bash")
				Sfx.play("moss_charge", -6.0)
			return
		"bash":
			velocity.x = facing * BASH_SPEED
			strike(front_rect(12.0, h, 0.0), 20.0, 260.0)
			if blocked(facing) or is_on_wall() or state_time > 0.75:
				velocity.x = 0.0
				if is_on_wall():
					Fx.add_shake(3.0)
					stagger(1.1)
				else:
					_bash_cd = 3.0
					set_state("recover")
			return
	if state == "chase" and _bash_cd <= 0.0:
		var d := to_player()
		if absf(d.x) > 64.0 and absf(d.x) < 180.0 and absf(d.y) < 26.0 and signf(d.x) == facing:
			_bash_cd = 3.0
			velocity.x = 0.0
			set_state("vow")
			return
	super.think(delta)


func sprite_anim() -> Array:
	match state:
		"vow":
			return ["windup", 0]
		"bash":
			return ["attack", 0]
	return super.sprite_anim()
