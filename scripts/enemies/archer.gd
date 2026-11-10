class_name Archer
extends Enemy

# Arqueiro: parado, mira (linha visível que segue o herói), trava a mira
# um instante antes de soltar e recua se o herói chega perto.
# A flecha atravessa quem está rolando.

const AIM := 0.85
const LOCK := 0.25
const COOLDOWN := 1.2
const ARROW_SPEED := 250.0
const DAMAGE := 12
# No primeiro andar (Mar de Cinzas, sem brasas) ele avisa mais e atira menos:
# o robô morria ali para ele em 3 de 4 partidas, e é onde o jogador novo aprende.
const GENTLE_AIM := 1.15
const GENTLE_LOCK := 0.4
const GENTLE_COOLDOWN := 1.7
const GENTLE_DAMAGE := 9

var aim_time := AIM
var lock_time := LOCK
var cooldown_time := COOLDOWN
var damage := DAMAGE
var _lock_sound := false

var _target := Vector2.ZERO


var shard := true   # true = atira estilhaço de vidro (Mar de Cinzas)


func _init() -> void:
	title = "ATIRADOR DE VIDRO"
	sheet = "archer"
	max_hp = 34
	hp = 34
	w = 10
	h = 22


func _ready() -> void:
	super._ready()
	if Run.heat == 0 and Run.mode == "":
		if Run.stage_id == Run.FIRST:
			aim_time = GENTLE_AIM
			lock_time = GENTLE_LOCK
			cooldown_time = GENTLE_COOLDOWN
			damage = GENTLE_DAMAGE
		elif Run.path.size() <= 2:
			# 2º andar (Forja ou Salões): meio-termo. O robô morria 80% na Forja, quase sempre para ele.
			aim_time = lerpf(AIM, GENTLE_AIM, 0.5)
			lock_time = lerpf(LOCK, GENTLE_LOCK, 0.5)
			cooldown_time = lerpf(COOLDOWN, GENTLE_COOLDOWN, 0.5)
			damage = 10


func body_color() -> Color:
	return Palette.ARCHER


func telegraphing() -> bool:
	return state == "aim" and state_time >= aim_time - lock_time


func bow() -> Vector2:
	return global_position + Vector2(facing * 7, -13)


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle", "chase":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if sees_player(240.0, 140.0):
				_lock_sound = false
				set_state("aim")
		"aim":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time < aim_time - lock_time:
				facing = 1 if d.x > 0.0 else -1
				_target = player.center()
				if not sees_player(280.0, 170.0):
					set_state("idle")
					return
			# o som de "travou": quem não está olhando para ele também sabe que vem tiro
			if not _lock_sound and state_time >= aim_time - lock_time:
				_lock_sound = true
				if sees_player(320.0, 200.0):
					Sfx.play("laser_charge", -15.0)
			if state_time >= aim_time:
				_lock_sound = false
				_shoot()
				set_state("cooldown")
		"cooldown":
			var away := -1 if d.x > 0.0 else 1
			if absf(d.x) < 60.0 and absf(d.y) < 30.0 and not blocked(away):
				velocity.x = away * 55.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time >= cooldown_time:
				set_state("aim" if sees_player(240.0, 140.0) else "idle")


func _shoot() -> void:
	var p := Projectile.new()
	p.room = room
	p.team = "enemy"
	p.style = "shard" if shard else "arrow"
	p.source = self
	p.position = bow()
	p.velocity = (_target - bow()).normalized() * ARROW_SPEED
	p.damage = Damage.make(damage, facing, 120.0)
	p.damage.source = self
	get_parent().add_child(p)
	Sfx.play("bow", -8.0)


func _draw() -> void:
	if state == "aim" and alive():
		var locked := state_time >= aim_time - lock_time
		var c := Palette.DANGER if locked else Palette.TELEGRAPH
		c.a = 0.9 if locked else 0.25 + 0.3 * (state_time / aim_time)
		if not locked or int(state_time * 20.0) % 2 == 0:
			draw_line(bow() - global_position, _target - global_position, c, 1.0)
	super._draw()


func sprite_anim() -> Array:
	if state == "aim":
		return ["aim_lock" if state_time >= aim_time - lock_time else "aim", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]


func draw_body() -> void:
	pass
