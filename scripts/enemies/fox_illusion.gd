class_name FoxIllusion
extends Enemy

# Uma das caudas fingindo ser a Raposa: corre junto com ela, pisca e some com um golpe.


func _init() -> void:
	title = "ILUSÃO"
	sheet = "boss_fox"
	max_hp = 1
	hp = 1
	w = 40
	h = 40
	essence_drop = Vector2i(0, 0)
	tier_scaling = false


func _ready() -> void:
	super._ready()
	set_state("wait")
	face_player()


func telegraphing() -> bool:
	return state == "wait"


func think(_delta: float) -> void:
	match state:
		"wait":
			velocity.x = 0.0
			face_player()
			if state_time >= BossFox.WAIT:
				set_state("dash")
		"dash":
			velocity.x = 0.0 if blocked(facing) else facing * BossFox.DASH
			strike(front_rect(20.0, h * 0.8, 0.0), 10.0, 160.0)
			if state_time >= 0.6 or blocked(facing):
				_vanish()


func sprite_anim() -> Array:
	body.modulate.a = 0.45 + 0.3 * sin(_anim * 22.0)
	return ["attack", 0] if state == "dash" else ["windup", 0]


func _die() -> void:
	_vanish()


# Ilusão não é morte de verdade: não conta abate nem dá nada.
func _vanish() -> void:
	Fx.burst(center(), Color("9fd8ff"), 14, 120.0, 0.4)
	remove_from_group("enemies")
	queue_free()
