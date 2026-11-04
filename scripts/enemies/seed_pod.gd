class_name SeedPod
extends Enemy

# Broto do Jardim: anda devagar até você, finca as raízes e incha. Se não
# levar um golpe a tempo, estoura em espinhos para todo lado. Depois fecha
# de novo e recomeça.

const RANGE := 46.0
const SWELL := 0.9


func _init() -> void:
	title = "BROTO ESPINHENTO"
	sheet = "seed_pod"
	max_hp = 40
	hp = 40
	w = 12
	h = 18
	essence_drop = Vector2i(1, 3)


func telegraphing() -> bool:
	return state == "swell"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			velocity.x = 0.0
			if sees_player(200.0, 60.0):
				set_state("chase")
		"chase":
			face_player()
			velocity.x = 0.0 if blocked(facing) else facing * 32.0
			if d.length() < RANGE and state_time > 0.6:
				velocity.x = 0.0
				set_state("swell")
				Sfx.play("moss_charge", -10.0)
		"swell":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time >= SWELL:
				_burst()
				set_state("spent")
		"spent":
			velocity.x = 0.0
			if state_time >= 1.6:
				set_state("chase")


func _burst() -> void:
	for i in 8:
		var a := -PI * 0.5 + (i - 3.5) * PI / 7.0
		var p := Projectile.new()
		p.room = room
		p.team = "enemy"
		p.style = "thorn"
		p.source = self
		p.position = center() + Vector2(0, -2)
		p.velocity = Vector2(cos(a), sin(a)) * 170.0
		p.gravity = 260.0
		p.life = 1.2
		p.damage = Damage.make(9, 1 if cos(a) >= 0.0 else -1, 90.0)
		p.damage.source = self
		get_parent().add_child(p)
	Fx.burst(center(), Color("c8e07a"), 14, 140.0, 0.35)
	Fx.add_shake(1.5)
	Sfx.play("thorn_shoot", -4.0)


func sprite_anim() -> Array:
	match state:
		"swell":
			return ["windup", int(state_time * 8.0)]
		"spent":
			return ["attack", 0] if state_time < 0.25 else ["idle", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]
