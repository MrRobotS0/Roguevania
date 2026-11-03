class_name ThornPlant
extends Enemy

# Espinheiro (Jardim Primordial): planta que não anda. Abre a flor (aviso)
# e lança três espinhos em arco onde você está.

const RANGE := 220.0
const EVERY := 2.6

var _cd := 1.2


func _init() -> void:
	title = "ESPINHEIRO"
	sheet = "thorn"
	max_hp = 34
	hp = 34
	w = 12
	h = 16
	weight = 99.0
	essence_drop = Vector2i(1, 2)


func telegraphing() -> bool:
	return state == "windup"


func think(delta: float) -> void:
	velocity.x = 0.0
	_cd -= delta
	match state:
		"idle", "chase":
			face_player()
			if _cd <= 0.0 and absf(to_player().x) < RANGE and absf(to_player().y) < 120.0:
				set_state("windup")
		"windup":
			if state_time >= 0.6:
				_cd = EVERY
				for i in 3:
					var p := Projectile.new()
					p.room = room
					p.team = "enemy"
					p.style = "thorn"
					p.source = self
					p.position = center() + Vector2(0, -6)
					var t := 0.9
					var target := player.center() + Vector2((i - 1) * 26.0, 0)
					p.gravity = 380.0
					p.velocity = Vector2((target.x - p.position.x) / t, (target.y - p.position.y) / t - 0.5 * p.gravity * t)
					p.damage = Damage.make(11, facing, 80.0)
					p.damage.source = self
					get_parent().add_child(p)
				Sfx.play("thorn_shoot", -6.0)
				set_state("attack")
		"attack":
			if state_time >= 0.3:
				set_state("idle")


func sprite_anim() -> Array:
	match state:
		"windup":
			return ["windup", 0]
		"attack":
			return ["attack", 0]
	return ["idle", int(_anim * 2.0)]
