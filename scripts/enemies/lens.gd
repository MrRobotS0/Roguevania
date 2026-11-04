class_name LivingLens
extends Enemy

# Lente Viva (Observatório): paira longe e mira um fio de luz em você, de
# qualquer ângulo. O fio segue você e, no fim, trava (fica vermelho): é o
# instante de sair da linha. Chegou perto, ela se afasta.

const AIM := 0.9
const LOCK := 0.28
const COOLDOWN := 2.6

var _cd := 1.0
var _aim := Vector2.RIGHT
var _home := Vector2.ZERO


func _init() -> void:
	title = "LENTE VIVA"
	sheet = "lens"
	max_hp = 34
	hp = 34
	w = 14
	h = 16
	uses_gravity = false
	weight = 1.6
	essence_drop = Vector2i(2, 3)


func _ready() -> void:
	super._ready()
	collision_mask = Room.WORLD_LAYER
	_home = global_position + Vector2(0, -26)


func telegraphing() -> bool:
	return state == "aim"


func think(delta: float) -> void:
	_cd -= delta
	var d := to_player()
	var bob := Vector2(0, sin(_anim * 2.0) * 6.0)
	match state:
		"idle", "chase":
			face_player()
			var want := _home + bob
			if d.length() < 80.0:
				want = global_position - d.normalized() * 40.0
			velocity = velocity.lerp((want - global_position).limit_length(1.0) * 60.0, 1.0 - exp(-3.0 * delta))
			if _cd <= 0.0 and sees_player(250.0, 200.0):
				set_state("aim")
				Sfx.play("laser_charge", -10.0)
		"aim":
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			face_player()
			if state_time < AIM - LOCK:
				_aim = (player.center() - center()).normalized()
			if state_time >= AIM:
				_fire()
				_cd = COOLDOWN
				set_state("idle")
		"stun":
			velocity.y = 20.0


func _fire() -> void:
	var p := Projectile.new()
	p.room = room
	p.team = "enemy"
	p.style = "shard"
	p.color = Palette.GLASS
	p.source = self
	p.position = center() + _aim * 8.0
	p.velocity = _aim * 520.0
	p.life = 1.2
	p.damage = Damage.make(15, 1 if _aim.x >= 0.0 else -1, 100.0)
	p.damage.source = self
	get_parent().add_child(p)
	Sfx.play("laser_fire", -6.0)


func _draw() -> void:
	if state == "aim" and alive():
		var locked := state_time >= AIM - LOCK
		var c := Palette.DANGER if locked else Palette.GLASS
		c.a = 0.3 + 0.5 * state_time / AIM
		var from := center() - global_position
		draw_line(from + _aim * 8.0, from + _aim * 260.0, c, 1.0)
	super._draw()


func sprite_anim() -> Array:
	match state:
		"aim":
			return ["windup", int(state_time * 10.0)]
	return ["idle", int(_anim * 6.0)]
