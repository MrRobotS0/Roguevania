class_name Player
extends Actor

signal died
signal health_changed(hp: int, max_hp: int)
signal gear_changed

enum State { MOVE, ATTACK, SHOOT, BLOCK, ROLL, DIVE, CLIMB, HEAL, HURT, DEAD }

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
const DIVE_DAMAGE := 18.0
const HURT_IFRAMES := 0.8
const FLASK_HEAL_RATIO := 0.5
const FLASK_TIME := 0.55
const BASE_FLASKS := 2
const BASE_HP := 100
const COMBO_GRACE := 0.3
const PARRY_WINDOW := 0.18
const INTERACT_RANGE := 22.0

var pad: PlayerInput = PlayerInput.new()
var state := State.MOVE
var weapons: Array = [null, null]
var skills: Array = [null, null]
var skill_cd: Array[float] = [0.0, 0.0]
var levels := {"furia": 0, "astucia": 0, "vigor": 0}
var max_flasks := BASE_FLASKS
var flasks := BASE_FLASKS
var essence := 0
var kills := 0
var wind := 0.0             # empurrão da tempestade (px/s)

var _state_time := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _roll_cd := 0.0
var _dodge := 0.0
var _invuln := 0.0
var _drop := 0.0
var _anim := 0.0
var _slot := 0
var _move_index := 0
var _combo_slot := -1
var _combo_next := 0
var _combo_grace := 0.0
var _combo_queued := false
var _swing_started := false
var _shot_fired := false
var _swing_hits: Array = []
var _dive_landed := false
var _block_slot := 0
var _climb_from := Vector2.ZERO
var _climb_to := Vector2.ZERO
var _was_grounded := true
var _death_sent := false
var _squash := 0.0
var skin: SkinData
var _scarf: Array[Vector2] = []
var _ghosts: Array = []          # rastros da rolagem/mergulho: [posição, tempo, quadro]
var _ghost_clock := 0.0


func _init() -> void:
	w = 10
	h = 22
	max_hp = BASE_HP
	hp = BASE_HP


func _ready() -> void:
	setup_body(2)
	floor_snap_length = 4.0
	z_index = 5
	add_to_group("player")
	if skin == null:
		skin = Meta.current_skin()
	Glow.attach(self, Color(1.0, 0.86, 0.68), 136.0, 0.8, Vector2(0, -12))


func weapon(slot: int) -> Gear:
	return weapons[slot]


func skill(slot: int) -> Gear:
	return skills[slot]


func stat_mult(stat: String) -> float:
	return Combat.stat_mult(levels, stat)


func recompute_max_hp() -> void:
	var before := max_hp
	max_hp = BASE_HP + 10 * (levels["furia"] + levels["astucia"]) + 20 * levels["vigor"]
	hp = clampi(hp + max_hp - before, 1, max_hp)
	health_changed.emit(hp, max_hp)


func add_level(stat: String) -> void:
	levels[stat] += 1
	recompute_max_hp()
	gear_changed.emit()


func equip(g: Gear) -> Gear:
	# Troca pelo slot do mesmo tipo: primeiro um vazio, senão o que está em uso.
	var list: Array = weapons if g.is_weapon() else skills
	var slot := list.find(null)
	if slot < 0:
		slot = _slot if g.is_weapon() else 0
	var old: Gear = list[slot]
	list[slot] = g
	if not g.is_weapon():
		skill_cd[slot] = 0.0
	gear_changed.emit()
	return old


func absorb_input() -> void:
	pad.sync()


func is_dodging() -> bool:
	return _dodge > 0.0


func blocking() -> bool:
	return state == State.BLOCK


func attack_rect(reach: Vector2) -> Rect2:
	var x := global_position.x + 2.0 if facing > 0 else global_position.x - 2.0 - reach.x
	return Rect2(x, global_position.y - h * 0.5 - reach.y * 0.5 - 1.0, reach.x, reach.y)


func nearest_interactable() -> Node2D:
	var best: Node2D = null
	var best_d := INTERACT_RANGE
	for it: Node2D in get_tree().get_nodes_in_group("interactables"):
		if not it.call("can_interact", self):
			continue
		var d := it.global_position.distance_to(global_position)
		if d < best_d:
			best = it
			best_d = d
	return best


# --- laço principal ----------------------------------------------------------

func _physics_process(delta: float) -> void:
	pad.poll()
	_tick(delta)
	tick_statuses(delta)
	match state:
		State.MOVE: _move_state(delta)
		State.ATTACK: _attack_state(delta)
		State.SHOOT: _shoot_state(delta)
		State.BLOCK: _block_state(delta)
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
	_update_scarf(delta)
	_update_ghosts(delta)
	queue_redraw()


func _tick(delta: float) -> void:
	_state_time += delta
	_anim += delta
	_coyote -= delta
	_jump_buffer -= delta
	_roll_cd -= delta
	_dodge -= delta
	_invuln -= delta
	flash -= delta
	_drop -= delta
	_combo_grace -= delta
	for i in skill_cd.size():
		skill_cd[i] = maxf(skill_cd[i] - delta, 0.0)
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
			Sfx.play("land", -8.0)
			_squash = clampf(falling / 430.0, 0.3, 1.0)
	_was_grounded = grounded
	if state != State.ROLL and state != State.DEAD and grounded:
		_separate_from_enemies()


# Inimigos não são paredes, mas também não dá para atravessá-los andando:
# o herói é empurrado para fora devagar. Rolando, passa direto.
func _separate_from_enemies() -> void:
	var me := hurt_rect()
	for e: Actor in get_tree().get_nodes_in_group("enemies"):
		if not e.alive() or not me.intersects(e.hurt_rect()) or e.get("ghost"):
			continue
		var dx := global_position.x - e.global_position.x
		var side := signf(dx) if absf(dx) > 0.5 else float(-facing)
		var overlap := (w + e.w) * 0.5 - absf(dx)
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
	velocity.x = move_toward(velocity.x, dir * RUN_SPEED + wind, accel * delta)
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

	for slot in 2:
		if pad.just("attack%d" % (slot + 1)) and _use_weapon(slot):
			return
		if pad.just("skill%d" % (slot + 1)) and _use_skill(slot):
			return
	if pad.just("roll") and _can_roll():
		_start_roll()
		return
	if pad.just("heal") and flasks > 0 and is_on_floor() and hp < max_hp:
		_start_heal()
		return
	if pad.just("interact"):
		var it := nearest_interactable()
		if it:
			it.call("interact", self)
			return
	if not is_on_floor() and velocity.y > -60.0 and dir != 0.0 and is_on_wall():
		_try_ledge(int(signf(dir)))


func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_buffer = 0.0
	_coyote = 0.0
	Fx.dust(global_position, 3)
	Sfx.play("jump", -10.0)


func _on_platform() -> bool:
	return room != null and room.is_platform_at(global_position + Vector2(0, 2))


func _try_ledge(dir: int) -> bool:
	if room == null:
		return false
	var t := Room.TILE
	var front := floori((global_position.x + dir * (w * 0.5 + 3.0)) / t)
	var own := floori(global_position.x / t)
	var head := global_position.y - h
	var first := floori((head - 4.0) / t)
	for row: int in [first, first + 1]:
		var top := float(row * t)
		if top < head - 6.0 or top > head + 12.0:
			continue
		if room.is_solid(front, row) and not room.is_solid(front, row - 1) \
				and not room.is_solid(front, row - 2) and not room.is_solid(own, row - 2):
			var edge := float(front * t) if dir > 0 else float((front + 1) * t)
			_climb_from = global_position
			_climb_to = Vector2(edge + dir * (w * 0.5 + 1.0), top)
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


# --- armas --------------------------------------------------------------------

func _use_weapon(slot: int) -> bool:
	var g := weapon(slot)
	if g == null:
		return false
	var data: WeaponData = g.data
	var dir := pad.axis()
	if dir != 0.0:
		facing = int(signf(dir))
	_slot = slot
	if data.category == "bow":
		_shot_fired = false
		_enter(State.SHOOT)
		return true
	if not is_on_floor() and pad.held("down"):
		_start_dive()
		return true
	var index := _combo_next if (_combo_grace > 0.0 and _combo_slot == slot) else 0
	_start_move(slot, index)
	return true


func _start_move(slot: int, index: int) -> void:
	_slot = slot
	_combo_slot = slot
	_move_index = index
	_combo_queued = false
	_swing_started = false
	_swing_hits.clear()
	_enter(State.ATTACK)


func current_move() -> Dictionary:
	var g := weapon(_slot)
	if g == null:
		return {}
	var data: WeaponData = g.data
	return data.moves[_move_index]


func _attack_state(delta: float) -> void:
	var g := weapon(_slot)
	if g == null:
		_enter(State.MOVE)
		return
	var data: WeaponData = g.data
	var m := current_move()
	var startup: float = m["startup"]
	var active_end: float = startup + float(m["active"])
	var total: float = active_end + float(m["recover"])

	_gravity(delta)
	if pad.just("attack%d" % (_slot + 1)):
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
			velocity.x = facing * float(m.get("lunge", 0.0))
		Sfx.play("swing_heavy" if m.get("shape", "") == "smash" else "swing", -6.0)
	if _state_time >= startup and _state_time < active_end:
		_check_swing(g, m)

	var next := (_move_index + 1) % data.moves.size()
	if _combo_queued and _state_time >= active_end + 0.03:
		_start_move(_slot, next)
		return
	if _state_time >= total:
		_combo_next = next
		_combo_grace = COMBO_GRACE
		_enter(State.MOVE)


func _check_swing(g: Gear, m: Dictionary) -> void:
	var data: WeaponData = g.data
	var box := attack_rect(m["reach"])
	var landed := false
	var crit_any := false
	for e: Actor in get_tree().get_nodes_in_group("enemies"):
		if not e.alive() or _swing_hits.has(e):
			continue
		if not box.intersects(e.hurt_rect()):
			continue
		_swing_hits.append(e)
		var d := Damage.make(float(m["damage"]) * g.power() * stat_mult(data.stat), facing, float(m["knock"]))
		d.source = self
		d.status = m.get("status", {}).duplicate()
		d.crit = bool(m.get("crit", false)) or Combat.situational_crit(data.crit_rule, self, e)
		if d.crit:
			d.amount *= data.crit_mult
			d.knock *= 1.3
			d.lift = 90.0
		crit_any = crit_any or d.crit
		if e.hurt(d):
			landed = true
	if landed:
		Fx.hitstop(float(m["stop"]) * (1.4 if crit_any else 1.0))
		Fx.add_shake(float(m["shake"]))
		Sfx.play("crit" if crit_any else "hit", -4.0)


func _shoot_state(delta: float) -> void:
	var g := weapon(_slot)
	if g == null:
		_enter(State.MOVE)
		return
	var data: WeaponData = g.data
	var s := data.shot
	velocity.x = move_toward(velocity.x, 0.0, GROUND_DECEL * delta)
	_gravity(delta, 0.5 if velocity.y > 0.0 else 1.0)
	if pad.just("roll") and _can_roll():
		_start_roll()
		return
	if not _shot_fired and _state_time >= float(s["draw"]):
		_shot_fired = true
		var p := Projectile.new()
		p.room = room
		p.team = "player"
		p.style = "arrow"
		p.source = self
		p.position = center() + Vector2(facing * 8, -1)
		p.velocity = Vector2(facing * float(s["speed"]), 0)
		p.pierce = int(s.get("pierce", 0))
		p.crit_rule = data.crit_rule
		p.crit_mult = data.crit_mult
		p.color = data.color
		p.damage = Damage.make(float(s["damage"]) * g.power() * stat_mult(data.stat), facing, 40.0)
		p.damage.source = self
		p.damage.status = s.get("status", {}).duplicate()
		p.damage.stop = 0.03
		get_parent().add_child(p)
		Sfx.play("bow", -6.0)
	if _state_time >= float(s["draw"]) + float(s["recover"]):
		_enter(State.MOVE)


# --- habilidades --------------------------------------------------------------

func _use_skill(slot: int) -> bool:
	var g := skill(slot)
	if g == null or skill_cd[slot] > 0.0:
		return false
	var data: SkillData = g.data
	var power := data.damage * g.power() * stat_mult(data.stat)
	match data.kind:
		"shield":
			if not is_on_floor():
				return false
			_block_slot = slot
			_enter(State.BLOCK)
			Sfx.play("shield_up", -8.0)
			return true
		"bomb":
			var p := _skill_projectile("bomb", Vector2(facing * 150.0, -130.0), power)
			p.gravity = 700.0
			p.radius = float(data.params.get("radius", 34.0))
			p.fuse = 1.5
			p.damage.status = {"burn": float(data.params.get("burn", 3.0))}
			p.damage.knock = 150.0
			p.damage.stop = 0.05
		"javelin":
			var p := _skill_projectile("javelin", Vector2(facing * 460.0, 0), power)
			p.pierce = int(data.params.get("pierce", 4))
			p.crit_rule = "stunned"
			p.damage.knock = 120.0
			p.damage.status = {"stun": 0.4}
			p.damage.stop = 0.04
	skill_cd[slot] = data.cooldown
	Sfx.play("throw", -6.0)
	return true


func _skill_projectile(style: String, vel: Vector2, power: float) -> Projectile:
	var p := Projectile.new()
	p.room = room
	p.team = "player"
	p.style = style
	p.source = self
	p.position = center() + Vector2(facing * 6, -4)
	p.velocity = vel
	p.damage = Damage.make(power, facing, 80.0)
	p.damage.source = self
	get_parent().add_child(p)
	return p


func _block_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, GROUND_DECEL * delta)
	_gravity(delta)
	var dir := pad.axis()
	if dir != 0.0 and _state_time < 0.05:
		facing = int(signf(dir))
	if not pad.held("skill%d" % (_block_slot + 1)) and _state_time > 0.12:
		_enter(State.MOVE)
	elif pad.just("roll") and _can_roll():
		_start_roll()


func _guard(d: Damage) -> bool:
	# Defende só o que vem pela frente.
	if state != State.BLOCK or d.unblockable or d.over_time or d.dir == facing:
		return false
	d.blocked = true
	if _state_time <= PARRY_WINDOW:
		d.parried = true
		Fx.hitstop(0.12)
		Fx.add_shake(3.0)
		Fx.burst(center() + Vector2(facing * 8, 0), Palette.DANGER, 14, 160.0, 0.3)
		Sfx.play("parry")
		var foe := d.source as Actor
		if foe and foe.has_method("stagger"):
			foe.call("stagger", 1.2)
	else:
		Fx.burst(center() + Vector2(facing * 8, 0), Palette.BLADE, 6, 90.0, 0.2)
		Sfx.play("block", -4.0)
		velocity.x = -facing * 60.0
	return true


# --- esquiva, mergulho, cura ----------------------------------------------------

func _can_roll() -> bool:
	return _roll_cd <= 0.0 and is_on_floor()


func _start_roll() -> void:
	var dir := pad.axis()
	if dir != 0.0:
		facing = int(signf(dir))
	_dodge = ROLL_DODGE
	Fx.dust(global_position, 4)
	Sfx.play("roll", -10.0)
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
	for e: Actor in get_tree().get_nodes_in_group("enemies"):
		if e.alive() and not _swing_hits.has(e) and feet.intersects(e.hurt_rect()):
			_swing_hits.append(e)
			var d := Damage.make(DIVE_DAMAGE * stat_mult("furia"), facing, 60.0)
			d.source = self
			e.hurt(d)
			Fx.hitstop(0.05)
	if is_on_floor():
		_land_dive()


func _land_dive() -> void:
	_dive_landed = true
	_state_time = 0.0
	velocity.y = 0.0
	var wave := Rect2(global_position.x - 28.0, global_position.y - 16.0, 56.0, 16.0)
	var landed := false
	for e: Actor in get_tree().get_nodes_in_group("enemies"):
		if e.alive() and not _swing_hits.has(e) and wave.intersects(e.hurt_rect()):
			var side := 1 if e.global_position.x >= global_position.x else -1
			var d := Damage.make(DIVE_DAMAGE * stat_mult("furia"), side, 160.0)
			d.source = self
			e.hurt(d)
			landed = true
	Fx.add_shake(4.0 if landed else 2.5)
	if landed:
		Fx.hitstop(0.06)
	Fx.burst(global_position, Palette.DUST, 10, 110.0, 0.35, 150.0, 2.0, 30.0)
	Sfx.play("slam", -4.0)
	_squash = 1.0


func _start_heal() -> void:
	flasks -= 1
	gear_changed.emit()
	Sfx.play("drink", -6.0)
	_enter(State.HEAL)


func _heal_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, GROUND_DECEL * delta)
	_gravity(delta)
	if _state_time >= FLASK_TIME:
		heal(roundi(max_hp * FLASK_HEAL_RATIO))
		_enter(State.MOVE)


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)
	Fx.burst(center(), Palette.HEAL, 12, 70.0, 0.6, -80.0, 2.0)


func add_essence(n: int) -> void:
	essence += n
	gear_changed.emit()


# --- dano recebido --------------------------------------------------------------

func hurt(d: Damage) -> bool:
	if state == State.DEAD:
		return false
	if d.over_time:
		hp = maxi(hp - d.value(), 1)
		health_changed.emit(hp, max_hp)
		return true
	if _invuln > 0.0 or _dodge > 0.0:
		return false
	if _guard(d):
		return false
	hp = maxi(hp - d.value(), 0)
	apply_statuses(d)
	_invuln = HURT_IFRAMES
	flash = 0.1
	health_changed.emit(hp, max_hp)
	var dir := d.dir if d.dir != 0 else -facing
	velocity = Vector2(dir * 170.0, -140.0)
	Fx.hitstop(0.08)
	Fx.add_shake(5.0)
	Fx.burst(center(), Palette.HURT, 10, 140.0)
	Sfx.play("hurt")
	if hp <= 0:
		Fx.burst(center(), Palette.HURT, 26, 200.0, 0.7)
		Sfx.play("death")
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

func _draw() -> void:
	_draw_ghosts()
	var stretch := Vector2.ONE
	if state == State.MOVE and not is_on_floor() and velocity.y < -120.0:
		stretch = Vector2(0.9, 1.1)
	draw_set_transform(Vector2.ZERO, 0.0, stretch)
	begin_tint()
	var blink := _invuln > 0.0 and state != State.DEAD and int(_invuln * 16.0) % 2 == 0
	if not blink:
		match state:
			State.ROLL: _draw_roll()
			State.DEAD: _draw_dead()
			_: _draw_body()
	end_tint()
	draw_set_transform(Vector2.ZERO)
	if state == State.ATTACK:
		_draw_slash()
	draw_statuses(_anim)
	if Fx.debug:
		_draw_debug()


func _blade_color() -> Color:
	var g := weapon(_slot)
	return g.data.color if g else Palette.BLADE


func _draw_body() -> void:
	var running := is_on_floor() and absf(velocity.x) > 20.0 and state == State.MOVE
	var stride := sin(_anim * 18.0) * 2.0 if running else 0.0
	var squash := _squash * 3.0
	var lift := 0.0 if is_on_floor() else -1.0
	var top := -h + squash

	px(-4 + stride, -7 + lift, 3, 7 + absf(lift), skin.hood)
	px(1 - stride, -7 + lift, 3, 7 + absf(lift), skin.hood)
	px(-5, top + 6, 10, 10 - squash, skin.cloak)
	px(-5, top + 13, 10, 3 - squash * 0.5, skin.cloak_dark)
	px(-6, top + 8, 1, 7, skin.cloak_dark)
	_draw_scarf()
	px(-3, top + 5, 7, 2, skin.scarf)
	px(-4, top, 8, 6, skin.hood)
	px(1, top + 2, 2, 1, _eye_color())

	match state:
		State.ATTACK:
			var m := current_move()
			var reach: Vector2 = m["reach"]
			if _state_time < float(m["startup"]):
				px(-3, top - 6, 1, 10, _blade_color())
				px(-4, top + 5, 3, 1, skin.scarf)
			else:
				px(4, top + 10, reach.x - 8.0, 1, _blade_color())
				px(3, top + 9, 2, 3, skin.scarf)
		State.SHOOT:
			var pull := clampf(_state_time / 0.25, 0.0, 1.0) * 3.0
			px(6, top + 4, 1, 12, Palette.WOOD_TOP)
			px(6 - pull, top + 5, 1, 10, Palette.UI_DIM)
			px(0, top + 9, 7, 1, Palette.ARROW)
		State.BLOCK:
			var parry := _state_time <= PARRY_WINDOW
			px(5, top + 3, 3, 15, Palette.DANGER if parry else Palette.GOLD)
			px(6, top + 5, 1, 11, Palette.STONE_TOP)
		State.DIVE:
			px(-1, -2, 1, 9, _blade_color())
		State.HEAL:
			px(2, top + 3, 3, 4, Palette.HEAL)
		_:
			px(-6, top + 3, 1, 10, _blade_color())


func _draw_roll() -> void:
	var frame := int(_state_time / ROLL_TIME * 8.0) % 4
	px(-6, -12, 12, 12, skin.cloak)
	px(-6, -3, 12, 3, skin.cloak_dark)
	var hood := [Vector2(1, -12), Vector2(2, -6), Vector2(-3, -4), Vector2(-5, -11)]
	var spot: Vector2 = hood[frame]
	px(spot.x, spot.y, 5, 5, skin.hood)
	px(-8 - frame, -6, 3, 2, skin.scarf)


func _draw_dead() -> void:
	px(-9, -5, 18, 5, skin.cloak_dark)
	px(5, -6, 6, 5, skin.hood)
	px(-10, -2, 4, 2, skin.scarf)


func _draw_slash() -> void:
	var m := current_move()
	if m.is_empty():
		return
	var shown := _state_time - float(m["startup"])
	var span := float(m["active"]) + 0.06
	if shown < 0.0 or shown > span:
		return
	var fade := 1.0 - shown / span
	var reach: Vector2 = m["reach"]
	var color := Palette.SLASH.lerp(_blade_color(), 0.3)
	color.a = 0.35 + 0.6 * fade

	var points := PackedVector2Array()
	var origin := Vector2(0, -h * 0.5)
	var shape: String = m.get("shape", "down")
	match shape:
		"thrust":
			points = PackedVector2Array([origin + Vector2(2, -3), origin + Vector2(reach.x + 4, -1),
				origin + Vector2(reach.x + 6, 0), origin + Vector2(reach.x + 4, 1), origin + Vector2(2, 3)])
		"smash":
			var r := reach.x
			for i in 9:
				var ang := lerpf(-1.6, 0.6, i / 8.0)
				points.append(origin + Vector2(cos(ang) * r, sin(ang) * r * 0.8))
			points.append(origin + Vector2(4, 4))
		_:
			var from := -1.2 if shape == "down" else 0.9
			var to := 0.9 if shape == "down" else -1.2
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
	draw_rect(Rect2(-w * 0.5, -h, w, h), Color(0.3, 1, 0.5, 0.8), false)
	if state == State.ATTACK:
		var r := attack_rect(current_move()["reach"])
		r.position -= global_position
		draw_rect(r, Color(1, 0.3, 0.3, 0.8), false)
	PixelFont.draw(self, State.keys()[state], Vector2(-12, -h - 10), Palette.UI_TEXT)


func _eye_color() -> Color:
	return skin.hood.lightened(0.3) if skin.closed_eyes else skin.eye


# --- cachecol (segue o pescoço com atraso; vento e queda balançam) -------------

const SCARF_LINKS := 5
const SCARF_GAP := 2.5


func _neck() -> Vector2:
	return global_position + Vector2(-2.0 * facing, -h + 6.0 + _squash * 3.0)


func _update_scarf(delta: float) -> void:
	if _scarf.size() != SCARF_LINKS:
		_scarf.clear()
		for i in SCARF_LINKS:
			_scarf.append(_neck() + Vector2(-facing * SCARF_GAP * i, 0))
	_scarf[0] = _neck()
	var drift := Vector2(wind * 0.06 - velocity.x * 0.012, 0.6 - velocity.y * 0.006)
	for i in range(1, SCARF_LINKS):
		var rest := _scarf[i - 1] + Vector2(-facing * SCARF_GAP, 0.4)
		var flutter := Vector2(0, sin(_anim * 13.0 + i * 1.3) * 0.5 * clampf(absf(velocity.x) / RUN_SPEED, 0.2, 1.0))
		_scarf[i] = _scarf[i].lerp(rest + drift + flutter, 1.0 - exp(-14.0 * delta))
		var link := _scarf[i] - _scarf[i - 1]
		if link.length() > SCARF_GAP:
			_scarf[i] = _scarf[i - 1] + link.normalized() * SCARF_GAP


func _draw_scarf() -> void:
	if _scarf.size() != SCARF_LINKS:
		return
	for i in range(1, SCARF_LINKS):
		var at := (_scarf[i] - global_position).round()
		var size := Vector2(3, 2) if i < SCARF_LINKS - 1 else Vector2(2, 2)
		raw(Rect2(at - Vector2(1, 1), size), skin.scarf if i % 2 == 1 else skin.scarf.darkened(0.12))


# --- rastro (rolagem e mergulho deixam silhuetas que somem) ----------------------

func _update_ghosts(delta: float) -> void:
	for g in _ghosts:
		g[1] -= delta
	_ghosts = _ghosts.filter(func(g: Array) -> bool: return g[1] > 0.0)
	_ghost_clock -= delta
	if (state == State.ROLL or state == State.DIVE) and _ghost_clock <= 0.0:
		_ghost_clock = 0.035
		_ghosts.append([global_position, 0.18, state])


func _draw_ghosts() -> void:
	for g in _ghosts:
		var at: Vector2 = g[0] - global_position
		var c := skin.cloak.lightened(0.15)
		c.a = 0.45 * g[1] / 0.18
		if g[2] == State.ROLL:
			draw_rect(Rect2(at + Vector2(-6, -12), Vector2(12, 12)), c)
		else:
			draw_rect(Rect2(at + Vector2(-5, -h), Vector2(10, h)), c)
