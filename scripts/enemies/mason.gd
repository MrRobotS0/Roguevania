class_name Mason
extends Enemy

# Pedreiro da Torre: de longe joga tijolo em arco (cai onde você estava);
# de perto bate com o próprio tijolo. Andar de cima não protege ninguém.

const REACH := 26.0
const THROW_CD := 2.4

var _cd := 1.2
var _done := false


func _init() -> void:
	title = "PEDREIRO DA TORRE"
	sheet = "mason"
	max_hp = 58
	hp = 58
	w = 11
	h = 24
	poise = 0.2
	essence_drop = Vector2i(2, 4)


func telegraphing() -> bool:
	return state in ["windup", "aim"]


func think(delta: float) -> void:
	_cd -= delta
	var d := to_player()
	match state:
		"idle":
			velocity.x = 0.0
			if sees_player(240.0, 140.0):
				set_state("chase")
		"chase":
			face_player()
			if absf(d.x) < REACH and absf(d.y) < 24.0:
				velocity.x = 0.0
				set_state("windup")
			elif _cd <= 0.0 and (absf(d.x) > 70.0 or d.y < -30.0) and sees_player(240.0, 160.0):
				velocity.x = 0.0
				set_state("aim")
			else:
				velocity.x = 0.0 if blocked(facing) else facing * 40.0
		"windup":
			velocity.x = 0.0
			if state_time >= 0.45:
				_done = false
				Sfx.play("swing_heavy", -6.0)
				set_state("attack")
		"attack":
			if not _done:
				_done = strike(front_rect(REACH, 22.0), 16, 190.0) or true
			if state_time >= 0.45:
				set_state("chase")
		"aim":
			velocity.x = 0.0
			face_player()
			if state_time >= 0.55:
				_throw()
				_cd = THROW_CD
				set_state("chase")


# Arco que cai no ponto onde o herói está agora.
func _throw() -> void:
	var p := Projectile.new()
	p.room = room
	p.team = "enemy"
	p.style = "brick"
	p.color = EnemyLooks.palette(look)[6]
	p.source = self
	p.position = center() + Vector2(facing * 6, -10)
	var target := player.center()
	var fly := clampf(absf(target.x - p.position.x) / 150.0, 0.45, 1.1)
	p.gravity = 600.0
	p.velocity = Vector2((target.x - p.position.x) / fly, (target.y - p.position.y) / fly - 0.5 * p.gravity * fly)
	p.life = 3.0
	p.damage = Damage.make(14, facing, 110.0)
	p.damage.source = self
	get_parent().add_child(p)
	Sfx.play("throw", -6.0)


func sprite_anim() -> Array:
	match state:
		"windup", "aim":
			return ["windup", 0]
		"attack":
			return ["attack", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]
