class_name Player
extends CharacterBody2D

signal died
signal health_changed(hp: int, max_hp: int)
signal flasks_changed(count: int)

enum State { MOVE, ATTACK, ROLL, DIVE, CLIMB, HEAL, HURT, DEAD }

const W := 10
const H := 22

# Movimento. Em pixels/segundo; 1 bloco = 16 px.
const RUN_SPEED := 150.0
const GROUND_ACCEL := 1600.0
const GROUND_DECEL := 2200.0
const AIR_ACCEL := 1100.0
const GRAVITY_UP := 950.0
const GRAVITY_DOWN := 1500.0
const MAX_FALL := 430.0
const JUMP_VELOCITY := -315.0      # ~3,3 blocos de altura
const JUMP_CUT := 0.45             # soltar o pulo cedo = pulo curto
const COYOTE_TIME := 0.1           # ainda pula logo depois de sair da beirada
const JUMP_BUFFER := 0.12          # pulo apertado um pouco antes de tocar o chão vale
const CLIMB_TIME := 0.16

const ROLL_SPEED := 270.0
const ROLL_TIME := 0.32
const ROLL_DODGE := 0.27           # invencível durante quase toda a rolagem
const ROLL_COOLDOWN := 0.12

const DIVE_SPEED := 620.0
const DIVE_DAMAGE := 18
const HURT_IFRAMES := 0.8
const FLASK_HEAL := 45
const FLASK_TIME := 0.55
const MAX_FLASKS := 2
const COMBO_GRACE := 0.3           # janela para continuar o combo depois de um golpe

# Espada provisória: 3 golpes; o terceiro é sempre crítico.
const COMBO := [
	{"startup": 0.06, "active": 0.08, "recover": 0.16, "damage": 10, "knock": 90.0,
		"reach": Vector2(28, 18), "lunge": 70.0, "stop": 0.045, "shake": 1.5, "crit": false},
	{"startup": 0.06, "active": 0.08, "recover": 0.18, "damage": 12, "knock": 110.0,
		"reach": Vector2(28, 20), "lunge": 80.0, "stop": 0.05, "shake": 2.0, "crit": false},
	{"startup": 0.12, "active": 0.10, "recover": 0.30, "damage": 26, "knock": 240.0,
		"reach": Vector2(34, 22), "lunge": 150.0, "stop": 0.09, "shake": 4.0, "crit": true},
]

var pad: PlayerInput = PlayerInput.new()
var room: Room
var state := State.MOVE
var facing := 1
var max_hp := 100
var hp := 100
var flasks := MAX_FLASKS

var _state_time := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _roll_cd := 0.0
var _dodge := 0.0
var _invuln := 0.0
var _flash := 0.0
var _drop := 0.0
var _anim := 0.0
var _combo_index := 0
var _combo_next := 0
var _combo_grace := 0.0
var _combo_queued := false
var _swing_started := false
var _swing_hits: Array = []
var _dive_landed := false
var _climb_from := Vector2.ZERO
var _climb_to := Vector2.ZERO
var _was_grounded := true
var _death_sent := false
var _squash := 0.0


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(W, H)
	var holder := CollisionShape2D.new()
	holder.shape = shape
	holder.position = Vector2(0, -H * 0.5)
	add_child(holder)
	collision_layer = 2
	collision_mask = Room.WORLD_LAYER | Room.PLATFORM_LAYER
	floor_snap_length = 4.0
	z_index = 5
	add_to_group("player")


func alive() -> bool:
	return state != State.DEAD


func center() -> Vector2:
	return global_position + Vector2(0, -H * 0.5)


func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-W * 0.5, -H), Vector2(W, H))


func attack_rect(reach: Vector2) -> Rect2:
	var x := global_position.x + 2.0 if facing > 0 else global_position.x - 2.0 - reach.x
	return Rect2(x, global_position.y - H * 0.5 - reach.y * 0.5 - 1.0, reach.x, reach.y)


func is_dodging() -> bool:
	return _dodge > 0.0


# --- laço principal ----------------------------------------------------------

func _physics_process(delta: float) -> void:
	pad.poll()
	_tick(delta)
	match state:
		State.MOVE: _move_state(delta)
		State.ATTACK: _attack_state(delta)
		State.ROLL: _roll_state(delta)
		State.DIVE: _dive_state(delta)
		State.CLIMB: _climb_state()
		State.HEAL: _heal_state(delta)
		State.HURT: _hurt_state(delta)
		State.DEAD: _dead_state(delta)
	if state != State.CLIMB:
		var falling := velocity.y
		move_and_slide()
		_after_move(falling)
	queue_redraw()


func _tick(delta: float) -> void:
	_state_time += delta
	_anim += delta
	_coyote -= delta
	_jump_buffer -= delta
	_roll_cd -= delta
	_dodge -= delta
	_invuln -= delta
	_flash -= delta
	_drop -= delta
	_combo_grace -= delta
	_squash = move_toward(_squash, 0.0, delta * 6.0)
	collision_mask = Room.WORLD_LAYER if _drop > 0.0 else Room.WORLD_LAYER | Room.PLATFORM_LAYER


func _enter(next: State) -> void:
	state = next
	_state_time = 0.0


func _after_move(falling: float) -> void:
	var grounded := is_on_floor()
	if grounded:
		_coyote = COYOTE_TIME
		if not _was_grounded and falling > 200.0:
			Fx.dust(global_position, 4 if falling < 380.0 else 8)
			_squash = clampf(falling / 430.0, 0.3, 1.0)
	_was_grounded = grounded
	if state != State.ROLL and state != State.DEAD and grounded:
		_separate_from_enemies()


# Inimigos não são paredes, mas também não dá para atravessá-los andando:
# o herói é empurrado para fora devagar. Rolando, passa direto.
func _separate_from_enemies() -> void:
	var me := hurt_rect()
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not e.alive() or not me.intersects(e.hurt_rect()):
			continue
		var dx := global_position.x - e.global_position.x
		var side := signf(dx) if absf(dx) > 0.5 else float(-facing)
		var overlap := (W + e.w) * 0.5 - absf(dx)
		if overlap > 0.0:
			move_and_collide(Vector2(side * minf(overlap, 2.0), 0))


func _gravity(delta: float, scale := 1.0) -> void:
	var g := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
	velocity.y = minf(velocity.y + g * scale * delta, MAX_FALL)


# --- estados ------------------------------------------------------------------

func _move_state(delta: float) -> void:
	var dir := pad.axis()
	if dir != 0.0:
		facing = int(signf(dir))
	var accel := AIR_ACCEL
	if is_on_floor():
		accel = GROUND_ACCEL if dir != 0.0 else GROUND_DECEL
	velocity.x = move_toward(velocity.x, dir * RUN_SPEED, accel * delta)
	_gravity(delta)

	if pad.just("jump"):
		_jump_buffer = JUMP_BUFFER
	if pad.released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
	if _jump_buffer > 0.0:
		if is_on_floor() and pad.held("down") and _on_platform():
			_drop = 0.25
			_jump_buffer = 0.0
		elif is_on_floor() or _coyote > 0.0:
			_jump()

	if pad.just("attack"):
		if not is_on_floor() and pad.held("down"):
			_start_dive()
		else:
			_start_attack(_combo_next if _combo_grace > 0.0 else 0)
		return
	if pad.just("roll") and _can_roll():
		_start_roll()
		return
	if pad.just("heal") and flasks > 0 and is_on_floor() and hp < max_hp:
		_start_heal()
		return
	if not is_on_floor() and velocity.y > -60.0 and dir != 0.0 and is_on_wall():
		_try_ledge(int(signf(dir)))


func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_buffer = 0.0
	_coyote = 0.0
	Fx.dust(global_position, 3)


func _on_platform() -> bool:
	return room != null and room.is_platform_at(global_position + Vector2(0, 2))


func _try_ledge(dir: int) -> bool:
	if room == null:
		return false
	var t := Room.TILE
	var front := floori((global_position.x + dir * (W * 0.5 + 3.0)) / t)
	var own := floori(global_position.x / t)
	var head := global_position.y - H
	var first := floori((head - 4.0) / t)
	for row: int in [first, first + 1]:
		var top := float(row * t)
		if top < head - 6.0 or top > head + 12.0:
			continue
		if room.is_solid(front, row) and not room.is_solid(front, row - 1) \
				and not room.is_solid(front, row - 2) and not room.is_solid(own, row - 2):
			var edge := float(front * t) if dir > 0 else float((front + 1) * t)
			_climb_from = global_position
			_climb_to = Vector2(edge + dir * (W * 0.5 + 1.0), top)
			velocity = Vector2.ZERO
			facing = dir
			_enter(State.CLIMB)
			return true
	return false


func _climb_state() -> void:
	var k := clampf(_state_time / CLIMB_TIME, 0.0, 1.0)
	var up := clampf(k / 0.6, 0.0, 1.0)
	var forward := clampf((k - 0.5) / 0.5, 0.0, 1.0)
	global_position = Vector2(
		lerpf(_climb_from.x, _climb_to.x, forward),
		lerpf(_climb_from.y, _climb_to.y, up))
	if k >= 1.0:
		velocity = Vector2.ZERO
		_was_grounded = true
		_enter(State.MOVE)


func _start_attack(index: int) -> void:
	_combo_index = index
	_combo_queued = false
	_swing_started = false
	_swing_hits.clear()
	var dir := pad.axis()
	if dir != 0.0:
		facing = int(signf(dir))
	_enter(State.ATTACK)


func _attack_state(delta: float) -> void:
	var a: Dictionary = COMBO[_combo_index]
	var startup: float = a["startup"]
	var active_end: float = startup + float(a["active"])
	var total: float = active_end + float(a["recover"])

	_gravity(delta)
	if pad.just("attack"):
		_combo_queued = true
	if pad.just("roll") and _can_roll():
		_start_roll()
		return
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, pad.axis() * RUN_SPEED * 0.5, AIR_ACCEL * delta)

	if _state_time >= startup and not _swing_started:
		_swing_started = true
		if is_on_floor():
			velocity.x = facing * float(a["lunge"])
	if _state_time >= startup and _state_time < active_end:
		_check_swing(a)

	var next := (_combo_index + 1) % COMBO.size()
	if _combo_queued and _state_time >= active_end + 0.03:
		_start_attack(next)
		return
	if _state_time >= total:
		_combo_next = next
		_combo_grace = COMBO_GRACE
		_enter(State.MOVE)


func _check_swing(a: Dictionary) -> void:
	var box := attack_rect(a["reach"])
	var landed := false
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not e.alive() or _swing_hits.has(e):
			continue
		if box.intersects(e.hurt_rect()):
			_swing_hits.append(e)
			e.take_hit(int(a["damage"]), facing, float(a["knock"]), bool(a["crit"]))
			landed = true
	if landed:
		Fx.hitstop(a["stop"])
		Fx.add_shake(a["shake"])


func _can_roll() -> bool:
	return _roll_cd <= 0.0 and is_on_floor()


func _start_roll() -> void:
	var dir := pad.axis()
	if dir != 0.0:
		facing = int(signf(dir))
	_dodge = ROLL_DODGE
	Fx.dust(global_position, 4)
	_enter(State.ROLL)


func _roll_state(delta: float) -> void:
	var k := _state_time / ROLL_TIME
	var speed := ROLL_SPEED if k < 0.7 else lerpf(ROLL_SPEED, RUN_SPEED * 0.6, (k - 0.7) / 0.3)
	velocity.x = facing * speed
	_gravity(delta)
	if pad.just("jump"):
		_jump_buffer = JUMP_BUFFER
	if _state_time >= ROLL_TIME:
		_roll_cd = ROLL_COOLDOWN
		_enter(State.MOVE)


func _start_dive() -> void:
	_dive_landed = false
	_swing_hits.clear()
	_enter(State.DIVE)


func _dive_state(delta: float) -> void:
	velocity.x = 0.0
	if _dive_landed:
		if _state_time >= 0.2:
			_enter(State.MOVE)
		else:
			_gravity(delta)
		return
	var windup := 0.08
	velocity.y = -70.0 if _state_time < windup else DIVE_SPEED
	if _state_time < windup:
		return

	var feet := Rect2(global_position.x - 7.0, global_position.y - 8.0, 14.0, 12.0)
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if e.alive() and not _swing_hits.has(e) and feet.intersects(e.hurt_rect()):
			_swing_hits.append(e)
			e.take_hit(DIVE_DAMAGE, facing, 60.0, false)
			Fx.hitstop(0.05)
	if is_on_floor():
		_land_dive()


func _land_dive() -> void:
	_dive_landed = true
	_state_time = 0.0
	velocity.y = 0.0
	var wave := Rect2(global_position.x - 28.0, global_position.y - 16.0, 56.0, 16.0)
	var landed := false
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if e.alive() and not _swing_hits.has(e) and wave.intersects(e.hurt_rect()):
			var side := 1 if e.global_position.x >= global_position.x else -1
			e.take_hit(DIVE_DAMAGE, side, 160.0, false)
			landed = true
	Fx.add_shake(4.0 if landed else 2.5)
	if landed:
		Fx.hitstop(0.06)
	Fx.burst(global_position, Palette.DUST, 10, 110.0, 0.35, 150.0, 2.0, 30.0)
	_squash = 1.0


func _start_heal() -> void:
	flasks -= 1
	flasks_changed.emit(flasks)
	_enter(State.HEAL)


func _heal_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, GROUND_DECEL * delta)
	_gravity(delta)
	if _state_time >= FLASK_TIME:
		hp = mini(max_hp, hp + FLASK_HEAL)
		health_changed.emit(hp, max_hp)
		Fx.burst(center(), Palette.HEAL, 12, 70.0, 0.6, -80.0, 2.0)
		_enter(State.MOVE)


func take_damage(amount: int, from_dir: int) -> bool:
	if state == State.DEAD or _invuln > 0.0 or _dodge > 0.0:
		return false
	hp = maxi(hp - amount, 0)
	_invuln = HURT_IFRAMES
	_flash = 0.1
	health_changed.emit(hp, max_hp)
	var dir := from_dir if from_dir != 0 else -facing
	velocity = Vector2(dir * 170.0, -140.0)
	Fx.hitstop(0.08)
	Fx.add_shake(5.0)
	Fx.burst(center(), Palette.HURT, 10, 140.0)
	if hp <= 0:
		Fx.burst(center(), Palette.HURT, 26, 200.0, 0.7)
		_enter(State.DEAD)
	else:
		_enter(State.HURT)
	return true


func _hurt_state(delta: float) -> void:
	_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	if _state_time >= 0.22:
		_enter(State.MOVE)


func _dead_state(delta: float) -> void:
	_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	if _state_time >= 1.1 and not _death_sent:
		_death_sent = true
		died.emit()


# --- desenho provisório --------------------------------------------------------
# Tudo em retângulos, espelhado pelo lado em que o herói olha. Quando a arte
# final chegar, isto vira um AnimatedSprite2D e o resto do arquivo fica igual.

var _tint := Color(0, 0, 0, 0)


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	if facing < 0:
		x = -x - w
	draw_rect(Rect2(x, y, w, h), _tint if _tint.a > 0.0 else c)


func _draw() -> void:
	_tint = Palette.FLASH if _flash > 0.0 else Color(0, 0, 0, 0)
	var blink := _invuln > 0.0 and state != State.DEAD and int(_invuln * 16.0) % 2 == 0
	if not blink:
		match state:
			State.ROLL: _draw_roll()
			State.DEAD: _draw_dead()
			_: _draw_body()
	if state == State.ATTACK:
		_draw_slash()
	if Fx.debug:
		_draw_debug()


func _draw_body() -> void:
	var running := is_on_floor() and absf(velocity.x) > 20.0 and state == State.MOVE
	var stride := sin(_anim * 18.0) * 2.0 if running else 0.0
	var squash := _squash * 3.0
	var lift := 0.0 if is_on_floor() else -1.0
	var top := -H + squash

	# pernas
	_px(-4 + stride, -7 + lift, 3, 7 + absf(lift), Palette.HERO_HOOD)
	_px(1 - stride, -7 + lift, 3, 7 + absf(lift), Palette.HERO_HOOD)
	# capa e tronco
	_px(-5, top + 6, 10, 10 - squash, Palette.HERO_CLOAK)
	_px(-5, top + 13, 10, 3 - squash * 0.5, Palette.HERO_CLOAK_DARK)
	_px(-6, top + 8, 1, 7, Palette.HERO_CLOAK_DARK)
	# cachecol, que voa mais quanto mais rápido ele anda
	var trail := clampf(absf(velocity.x) / RUN_SPEED, 0.0, 1.0) * 4.0
	_px(-5 - trail - 2, top + 6 + sin(_anim * 14.0), 3 + trail, 2, Palette.HERO_SCARF)
	_px(-3, top + 5, 7, 2, Palette.HERO_SCARF)
	# capuz e olho
	_px(-4, top, 8, 6, Palette.HERO_HOOD)
	_px(1, top + 2, 2, 1, Palette.HERO_EYE)

	match state:
		State.ATTACK:
			var a: Dictionary = COMBO[_combo_index]
			if _state_time < float(a["startup"]):
				_px(-3, top - 6, 1, 10, Palette.BLADE)
				_px(-4, top + 5, 3, 1, Palette.HERO_SCARF)
			else:
				_px(4, top + 10, float(a["reach"].x) - 8.0, 1, Palette.BLADE)
				_px(3, top + 9, 2, 3, Palette.HERO_SCARF)
		State.DIVE:
			_px(-1, -2, 1, 9, Palette.BLADE)
		State.HEAL:
			_px(2, top + 3, 3, 4, Palette.HEAL)
		_:
			_px(-6, top + 3, 1, 10, Palette.BLADE)


func _draw_roll() -> void:
	var frame := int(_state_time / ROLL_TIME * 8.0) % 4
	_px(-6, -12, 12, 12, Palette.HERO_CLOAK)
	_px(-6, -3, 12, 3, Palette.HERO_CLOAK_DARK)
	var hood := [Vector2(1, -12), Vector2(2, -6), Vector2(-3, -4), Vector2(-5, -11)]
	var spot: Vector2 = hood[frame]
	_px(spot.x, spot.y, 5, 5, Palette.HERO_HOOD)
	_px(-8 - frame, -6, 3, 2, Palette.HERO_SCARF)


func _draw_dead() -> void:
	_px(-9, -5, 18, 5, Palette.HERO_CLOAK_DARK)
	_px(5, -6, 6, 5, Palette.HERO_HOOD)
	_px(-10, -2, 4, 2, Palette.HERO_SCARF)


func _draw_slash() -> void:
	var a: Dictionary = COMBO[_combo_index]
	var startup: float = a["startup"]
	var shown := _state_time - startup
	var span := float(a["active"]) + 0.06
	if shown < 0.0 or shown > span:
		return
	var fade := 1.0 - shown / span
	var reach: Vector2 = a["reach"]
	var color := Palette.SLASH
	color.a = 0.35 + 0.6 * fade

	var points := PackedVector2Array()
	var origin := Vector2(0, -H * 0.5)
	if _combo_index == 2:
		# estocada: cunha longa e reta
		points = PackedVector2Array([origin + Vector2(2, -3), origin + Vector2(reach.x + 4, -1),
			origin + Vector2(reach.x + 6, 0), origin + Vector2(reach.x + 4, 1), origin + Vector2(2, 3)])
	else:
		var from := -1.2 if _combo_index == 0 else 0.9
		var to := 0.9 if _combo_index == 0 else -1.2
		var outer := reach.x + 2.0
		var inner := outer - 7.0
		for i in 9:
			var ang := lerpf(from, to, i / 8.0)
			points.append(origin + Vector2(cos(ang) * outer, sin(ang) * outer * 0.55))
		for i in range(8, -1, -1):
			var ang := lerpf(from, to, i / 8.0)
			points.append(origin + Vector2(cos(ang) * inner, sin(ang) * inner * 0.55))
	if facing < 0:
		for i in points.size():
			points[i] = Vector2(-points[i].x, points[i].y)
	draw_colored_polygon(points, color)


func _draw_debug() -> void:
	draw_rect(Rect2(-W * 0.5, -H, W, H), Color(0.3, 1, 0.5, 0.8), false)
	if state == State.ATTACK:
		var a: Dictionary = COMBO[_combo_index]
		var r := attack_rect(a["reach"])
		r.position -= global_position
		draw_rect(r, Color(1, 0.3, 0.3, 0.8), false)
	PixelFont.draw(self, State.keys()[state], Vector2(-12, -H - 10), Palette.UI_TEXT)
