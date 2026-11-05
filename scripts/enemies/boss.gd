class_name Boss
extends Enemy

# Base dos chefes de andar. Cada chefe é uma lista de golpes (dicionários) e
# esta classe executa: aviso (windup) → golpe (act) → respiro (recover). A
# cada `rest_every` golpes ele para, exausto (dano x1,5): é a janela.
# Com metade da vida entra na fase 2: golpes extras e tudo mais rápido.
#
# Tipos de golpe:
#   melee   {reach, height, push, status}        golpe na frente
#   leap    {radius}                              salta até o herói e cai com onda
#   charge  {speed, time}                         investida até a parede
#   volley  {count, spread, style, speed, aimed, radial, arc, homing, rate}
#   rain    {style, count, width, height, delay, predict}  perigos caindo do chão/céu
#   summon  {script, count}
#   teleport{reach}                               some e reaparece atrás, com golpe
#   beam    {}                                    raio horizontal na altura do herói
#   wave    {speed}                               ondas que correm pelo chão
#   custom  {...}                                 golpe só dele: custom_start / custom_update

signal phase_changed(phase: int)

var arena: Rect2
var phase := 1
var moves: Array = []
var moves2: Array = []
var subtitle := ""
var defeat_text := ""
var walk_speed := 50.0
var keep_distance := 0.0     # chefes de longe se afastam até essa distância
var rest_every := 3
var _move: Dictionary = {}
var _done_moves := 0
var _hit_done := false
var _shots := 0
var _clock := 0.0
var _alpha := 1.0
var _last := -1
var aggro_range := 0.0       # > 0: modo elite (só age quando vê o herói, sem apresentação)
var sounds := {}             # tipo de golpe -> som (o padrão está em _sound)


func _ready() -> void:
	tier_scaling = aggro_range > 0.0
	super._ready()
	unstoppable = true
	poise = 1.0
	set_state("idle" if aggro_range > 0.0 else "intro")
	if aggro_range <= 0.0:
		Sfx.play("boss_intro", -2.0)
	if arena.size == Vector2.ZERO:
		arena = Rect2(global_position.x - 240.0, global_position.y - 200.0, 480.0, 200.0)


func _tm() -> float:
	return 0.75 if phase == 2 else 1.0


func hurt(d: Damage) -> bool:
	if state == "intro" or _alpha < 0.5:
		return false
	if state == "rest" and not d.over_time:
		d.amount *= 1.5
		d.crit = true
	var hit := super.hurt(d)
	if hit and phase == 1 and hp <= max_hp / 2 and alive():
		phase = 2
		phase_changed.emit(2)
		Fx.add_shake(6.0)
		Fx.toast(title + " SE ENFURECE")
		Sfx.play("boss_phase")
		custom_abort()
		set_state("idle")
	return hit


func telegraphing() -> bool:
	return state == "windup"


func _pool() -> Array:
	return moves + (moves2 if phase == 2 else [])


func _choose() -> void:
	var pool := _pool()
	var d := to_player()
	var options: Array[int] = []
	for i in pool.size():
		var m: Dictionary = pool[i]
		if i == _last and pool.size() > 1:
			continue
		if m.has("max_range") and absf(d.x) > float(m["max_range"]):
			continue
		if m.has("min_range") and absf(d.x) < float(m["min_range"]):
			continue
		if m["type"] == "summon" and _adds() >= 3:
			continue
		options.append(i)
	if options.is_empty():
		options.append(randi_range(0, pool.size() - 1))
	_last = options[randi_range(0, options.size() - 1)]
	_move = pool[_last]
	face_player()
	_hit_done = false
	_shots = 0
	_clock = 0.0
	if _move["type"] == "teleport":
		set_state("vanish")
	else:
		set_state("windup")
		if _move["type"] in ["volley", "rain", "summon", "beam"]:
			Sfx.play("omen", -4.0)


func _adds() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self:
			n += 1
	return n


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"intro":
			velocity.x = 0.0
			if state_time >= 1.6:
				set_state("idle")
		"idle", "chase":
			if aggro_range > 0.0 and state == "idle" and not sees_player(aggro_range, 90.0):
				velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
				return
			if state == "idle" and aggro_range > 0.0:
				set_state("chase")
			face_player()
			var want := 0.0
			if keep_distance > 0.0 and absf(d.x) < keep_distance:
				want = -facing * walk_speed
			elif absf(d.x) > 70.0:
				want = facing * walk_speed
			if want != 0.0 and blocked(int(signf(want))):
				want = 0.0
			velocity.x = move_toward(velocity.x, want, 600.0 * delta)
			if state_time >= (0.8 if aggro_range <= 0.0 else 1.0) * _tm():
				_choose()
		"windup":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _move["type"] in ["melee", "charge", "leap"]:
				face_player()
			if state_time >= float(_move.get("windup", 0.6)) * _tm():
				set_state("act")
				_act_start()
		"act":
			_act_update(delta)
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if state_time >= float(_move.get("recover", 0.5)) * _tm():
				_done_moves += 1
				set_state("rest" if _done_moves % rest_every == 0 else ("chase" if aggro_range > 0.0 else "idle"))
		"rest":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if state_time >= 1.6:
				set_state("chase" if aggro_range > 0.0 else "idle")
		"vanish":
			if state_time < get_physics_process_delta_time() * 1.5:
				Sfx.play("teleport", -6.0)
			_alpha = 1.0 - clampf(state_time / 0.3, 0.0, 1.0)
			if state_time >= 0.3:
				var side := -1 if d.x > 0.0 else 1
				global_position.x = clampf(player.global_position.x - side * 34.0, arena.position.x + 24.0, arena.end.x - 24.0)
				face_player()
				set_state("appear")
		"appear":
			_alpha = clampf(state_time / 0.25, 0.0, 1.0)
			if state_time >= 0.25:
				_alpha = 1.0
				_move = {"type": "melee", "windup": 0.35, "reach": float(_move.get("reach", 44.0)),
					"height": 30.0, "damage": float(_move.get("damage", 20.0)), "recover": 0.5}
				set_state("windup")


func _sound(kind: String) -> String:
	if sounds.has(kind):
		return sounds[kind]
	return {"melee": "swing_heavy", "leap": "swing", "charge": "swing", "volley": "bow", "rain": "omen",
		"summon": "omen", "beam": "laser_charge", "wave": "hammer_slam", "teleport": "teleport"}.get(kind, "swing")


func _act_start() -> void:
	var m := _move
	Sfx.play(_sound(m["type"]), -4.0)
	match m["type"]:
		"melee":
			pass
		"custom":
			custom_start(m)
		"leap":
			var dx := clampf(player.global_position.x - global_position.x, -260.0, 260.0)
			velocity = Vector2(dx / 0.7, -360.0)
		"charge":
			velocity.x = facing * float(m.get("speed", 300.0))
		"summon":
			for i in int(m.get("count", 2)):
				var side := -1 if i % 2 == 0 else 1
				var x := clampf(global_position.x + side * (90.0 + i * 20.0), arena.position.x + 24.0, arena.end.x - 24.0)
				var add: Enemy = load(m["script"]).new()
				add.room = room
				add.player = player
				add.essence_drop = Vector2i(0, 0)
				add.position = Vector2(x, global_position.y)
				get_parent().add_child(add)
				Fx.burst(add.position + Vector2(0, -10), Palette.DUST, 14, 120.0, 0.5)
		"beam":
			var beam := Hazard.new()
			beam.player = player
			beam.style = "light"
			beam.source = self
			beam.width = arena.size.x
			beam.height = 14.0
			beam.delay = 0.7 * _tm()
			beam.linger = 0.35
			beam.damage = float(m.get("damage", 22.0))
			beam.position = Vector2(arena.get_center().x, player.center().y + 7.0)
			get_parent().add_child(beam)
		"rain":
			_rain(m)
		"wave":
			for dir in [-1, 1]:
				var p := Projectile.new()
				p.room = room
				p.team = "enemy"
				p.style = "wave"
				p.source = self
				p.position = global_position + Vector2(dir * 14.0, -6.0)
				p.velocity = Vector2(dir * float(m.get("speed", 220.0)), 0)
				p.life = 2.5
				p.pierce = 99
				p.damage = Damage.make(float(m.get("damage", 18.0)), dir, 160.0)
				p.damage.source = self
				p.damage.unblockable = true
				get_parent().add_child(p)
			Fx.add_shake(5.0)


# A mecânica própria de cada chefe. custom_update devolve true quando termina.
func custom_start(_m: Dictionary) -> void:
	pass


func custom_update(_m: Dictionary, _delta: float) -> bool:
	return true


func custom_abort() -> void:
	pass


func _act_update(delta: float) -> void:
	var m := _move
	match m["type"]:
		"custom":
			if custom_update(m, delta):
				set_state("recover")
		"melee":
			if not _hit_done:
				_hit_done = true
				strike(front_rect(float(m.get("reach", 50.0)), float(m.get("height", 30.0))), float(m.get("damage", 20.0)),
					float(m.get("push", 220.0)), {"status": m.get("status", {})})
				Fx.burst(global_position + Vector2(facing * float(m.get("reach", 50.0)) * 0.7, -12.0), Palette.SLASH, 10, 140.0, 0.3)
			if state_time >= 0.2:
				set_state("recover")
		"leap":
			if state_time > 0.15 and is_on_floor():
				velocity = Vector2.ZERO
				var r := float(m.get("radius", 60.0))
				strike(Rect2(global_position.x - r, global_position.y - 16.0, r * 2.0, 16.0), float(m.get("damage", 22.0)), 240.0)
				Fx.burst(global_position, Palette.DUST, 22, 180.0, 0.5, 200.0, 3.0, 30.0)
				Fx.add_shake(6.0)
				Sfx.play("slam")
				set_state("recover")
		"charge":
			if not _hit_done:
				_hit_done = strike(front_rect(20.0, h * 0.8, 0.0), float(m.get("damage", 22.0)), 260.0)
			if state_time >= float(m.get("time", 1.0)) or blocked(facing):
				velocity.x = 0.0
				if blocked(facing):
					Fx.add_shake(4.0)
					Sfx.play("slam", -4.0)
				set_state("recover")
		"volley":
			_clock -= delta
			if _clock <= 0.0 and _shots < int(m.get("bursts", 1)):
				_clock = float(m.get("rate", 0.25)) * _tm()
				_shots += 1
				_volley(m)
			if _shots >= int(m.get("bursts", 1)) and _clock <= 0.0:
				set_state("recover")
		_:
			if state_time >= 0.3:
				set_state("recover")


func _volley(m: Dictionary) -> void:
	var count := int(m.get("count", 3))
	var spread := float(m.get("spread", 0.3))
	var origin := center() + Vector2(facing * 10.0, -8.0)
	var base := (player.center() - origin).angle()
	for i in count:
		var ang := base
		if m.get("radial", false):
			ang = i * TAU / count + _shots * 0.3
		elif count > 1:
			ang = base + (i - (count - 1) * 0.5) * spread
		var p := Projectile.new()
		p.room = room
		p.team = "enemy"
		p.style = m.get("style", "orb")
		p.color = m.get("color", Palette.DANGER)
		p.source = self
		p.position = origin
		var speed := float(m.get("speed", 200.0))
		if m.get("arc", false):
			var t := 0.9
			var target := player.center() + Vector2((i - (count - 1) * 0.5) * 28.0, 0)
			p.gravity = 380.0
			p.velocity = Vector2((target.x - origin.x) / t, (target.y - origin.y) / t - 0.5 * p.gravity * t)
		else:
			p.velocity = Vector2.from_angle(ang) * speed
		p.homing = float(m.get("homing", 0.0))
		p.life = 4.0
		p.damage = Damage.make(float(m.get("damage", 14.0)), facing, 100.0)
		p.damage.source = self
		get_parent().add_child(p)


func _rain(m: Dictionary) -> void:
	var count := int(m.get("count", 4))
	for i in count:
		var x := 0.0
		if m.get("predict", false) and i == 0:
			x = player.global_position.x + player.velocity.x * 0.6
		elif i == 0:
			x = player.global_position.x
		else:
			x = randf_range(arena.position.x + 20.0, arena.end.x - 20.0)
		x = clampf(x, arena.position.x + 16.0, arena.end.x - 16.0)
		var hz := Hazard.new()
		hz.player = player
		hz.style = m.get("style", "glass")
		hz.source = self
		hz.width = float(m.get("width", 18.0))
		hz.height = float(m.get("height", 60.0))
		hz.delay = float(m.get("delay", 0.8)) * _tm() + i * 0.08
		hz.damage = float(m.get("damage", 18.0))
		hz.position = Vector2(x, global_position.y)
		get_parent().add_child(hz)


func sprite_anim() -> Array:
	body.modulate.a = _alpha
	body.visible = _alpha > 0.02
	match state:
		"intro":
			return ["cast", int(state_time * 6.0)]
		"windup":
			return ["windup", 0]
		"act":
			if _move.get("type", "") in ["volley", "rain", "summon", "beam", "wave"]:
				return ["cast", int(state_time * 6.0)]
			return ["attack", 0]
		"rest", "stun":
			return ["rest", 0]
	if absf(velocity.x) > 8.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]


func overhead_text() -> String:
	return "EXAUSTO" if state == "rest" else ""
