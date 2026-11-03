class_name Scribe
extends Enemy

# Escriba Mudo (Torre de Babel): fica de longe e escreve no ar um glifo que
# persegue devagar. Chegou perto, ele recua.

const CAST := 0.7
const COOLDOWN := 2.2

var _cd := 1.0


func _init() -> void:
	title = "ESCRIBA MUDO"
	sheet = "scribe"
	max_hp = 46
	hp = 46
	w = 10
	h = 24
	essence_drop = Vector2i(2, 3)


func telegraphing() -> bool:
	return state == "cast"


func think(delta: float) -> void:
	_cd -= delta
	var d := to_player()
	match state:
		"idle", "chase":
			face_player()
			var away := -1 if d.x > 0.0 else 1
			if absf(d.x) < 70.0 and not blocked(away):
				velocity.x = away * 45.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if _cd <= 0.0 and sees_player(260.0, 120.0):
				set_state("cast")
		"cast":
			velocity.x = 0.0
			if state_time >= CAST:
				_cd = COOLDOWN
				var p := Projectile.new()
				p.room = room
				p.team = "enemy"
				p.style = "glyph"
				p.color = Palette.GOLD
				p.source = self
				p.position = center() + Vector2(facing * 8, -6)
				p.velocity = (player.center() - p.position).normalized() * 110.0
				p.homing = 1.4
				p.life = 4.0
				p.damage = Damage.make(13, facing, 90.0)
				p.damage.source = self
				get_parent().add_child(p)
				Sfx.play("omen", -10.0)
				set_state("idle")


func sprite_anim() -> Array:
	if state == "cast":
		return ["cast", int(state_time * 6.0)]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]
