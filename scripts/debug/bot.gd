class_name Bot
extends PlayerInput

# Um jogador de mentira, para medir o jogo sem tela (tests/robo.tscn).
# Joga como alguém razoável: anda pelo caminho do BotNav, pega item melhor,
# usa altar e Vigia, luta com quem aparece na frente, rola quando vê o
# aviso (nem sempre: `reflex` é a chance de reagir) e bebe frasco com a vida
# baixa. Os menus quem responde é o robo.gd, que roda mesmo com o jogo
# pausado.

const ARRIVE := 10.0
const STUCK_JUMP := 4.0
const STUCK_SKIP := 11.0

var player: Player
var level: Level
var nav := BotNav.new()
var reflex := 0.75
var rng := RandomNumberGenerator.new()
var stuck_events: Array = []     # [andar, célula] onde precisou ser empurrado
var exit_pick := 0               # qual saída da passagem tomar

var _want := {}
var _path: Array = []
var _goal: Node2D
var _goal_cell := Vector2i(-999, -999)
var _skip: Array = []            # objetos que não dá para alcançar ou já usados
var _replan := 0.0
var _progress_clock := 0.0
var _best_left := 999999
var _jumping := 0
var _frame := 0
var _reacted := {}               # inimigo -> instante do aviso já decidido
var _target: Enemy
var _target_clock := 0.0
var _ignored := {}               # inimigo -> até quando ignorar
var _interact_wait := 0.0
var _why := ""                   # o que decidiu no último quadro (para o relatório de travas)
var trace := false


func setup(p: Player, lv: Level) -> void:
	player = p
	level = lv
	nav.build(lv.room)
	_path.clear()
	_goal = null
	_skip.clear()
	_reacted.clear()
	_ignored.clear()
	_progress_clock = 0.0
	_best_left = 999999


func poll() -> void:
	_frame += 1
	if trace and _frame % 300 == 0 and player and is_instance_valid(player):
		print("    t%d %s cel %s alvo %s %s caminho %d | %s" % [int(Run.stage_time), level.kind, nav.cell_of(player.global_position),
			(_goal.get_script() as Script).get_global_name() if _goal and is_instance_valid(_goal) and _goal.get_script() else "-",
			nav.cell_of(_goal.global_position) if _goal and is_instance_valid(_goal) else Vector2i.ZERO, _path.size(), _why])
	_want.clear()
	if player and is_instance_valid(player) and player.alive() and level and is_instance_valid(level):
		_think(player.get_physics_process_delta_time())
	super.poll()


func _read(action: String) -> bool:
	return _want.get(action, false)


func _press(action: String) -> void:
	# só conta como "apertou agora" se estava solto no quadro anterior
	if not held(action):
		_want[action] = true


func _hold(action: String) -> void:
	_want[action] = true


func _dir(d: float) -> void:
	if d > 0.5:
		_hold("right")
	elif d < -0.5:
		_hold("left")


# --- decisão ------------------------------------------------------------------

func _think(delta: float) -> void:
	_interact_wait -= delta
	if player.state == Player.State.CLIMB or player.state == Player.State.HEAL:
		return
	if _dodge_projectiles():
		_why = "desviando"
		return
	var e := _pick_target(delta)
	if e:
		_why = "lutando com " + e.title
		_fight(e)
		return
	_why = "andando"
	if player.hp < player.max_hp * 0.5 and player.flasks > 0 and player.is_on_floor() and _nearest_enemy_distance() > 140.0:
		_press("heal")
		return
	_navigate(delta)


func _nearest_enemy_distance() -> float:
	var best := INF
	for e: Enemy in level.enemies():
		if e.alive():
			best = minf(best, e.center().distance_to(player.center()))
	return best


func _pick_target(delta: float) -> Enemy:
	var best: Enemy = null
	var best_d := INF
	var now := Time.get_ticks_msec()
	for e: Enemy in level.enemies():
		if not e.alive() or e.ghost:
			continue
		if _ignored.get(e, 0) > now:
			continue
		var d := e.center() - player.center()
		var boss_room := level.is_boss_room and e == level.boss
		if not boss_room and (absf(d.x) > 170.0 or absf(d.y) > 44.0):
			continue
		if not boss_room and not level.room.clear_line(player.center(), e.center()):
			continue
		var score := d.length() - (400.0 if boss_room else 0.0)
		if score < best_d:
			best = e
			best_d = score
	if best != _target:
		_target = best
		_target_clock = 0.0
	elif best:
		_target_clock += delta
		# briga longa demais com alguém que não dá para alcançar: deixa para lá
		if _target_clock > 25.0 and not level.is_boss_room:
			_ignored[best] = Time.get_ticks_msec() + 10000
			_target = null
			return null
	return best


func _dodge_projectiles() -> bool:
	if not player.is_on_floor():
		return false
	for p: Node in level.get_children():
		if not (p is Projectile) or p.team != "enemy":
			continue
		var to_me: Vector2 = player.center() - p.global_position
		if to_me.length() > 46.0 or p.velocity.dot(to_me) <= 0.0:
			continue
		if _decide(p):
			_dir(signf(p.velocity.x))
			_press("roll")
			return true
	return false


# Cada aviso é decidido uma vez: reage (com a chance `reflex`) ou não.
func _decide(who: Object) -> bool:
	var key := who.get_instance_id()
	if not _reacted.has(key):
		_reacted[key] = rng.randf() < reflex
		if _reacted.size() > 400:
			_reacted.clear()
	return _reacted[key]


func _fight(e: Enemy) -> void:
	var d := e.center() - player.center()
	var dist := absf(d.x)
	var toward := signf(d.x) if d.x != 0.0 else float(player.facing)
	if e.telegraphing() and dist < 90.0:
		if _decide(e) and player.is_on_floor():
			var away := -toward
			var wall_behind := level.room.is_solid_at(player.global_position + Vector2(away * 40.0, -8.0))
			_dir(toward if wall_behind else away)
			_press("roll")
			return
	elif _reacted.has(e.get_instance_id()) and not e.telegraphing():
		_reacted.erase(e.get_instance_id())
	if player.hp < player.max_hp * 0.35 and player.flasks > 0 and dist > 80.0 and player.is_on_floor():
		_press("heal")
		return
	for slot in 2:
		var g := player.skill(slot)
		if g and player.skill_cd[slot] <= 0.0 and (g.data as SkillData).kind != "shield" and dist < 120.0:
			_dir(toward)
			_press("skill%d" % (slot + 1))
			return
	var slot := _weapon_for(dist)
	var g := player.weapon(slot)
	if g == null:
		_dir(toward)
		return
	var data: WeaponData = g.data
	if data.category == "bow":
		if dist < 60.0 and not level.room.is_solid_at(player.global_position + Vector2(-toward * 20.0, -8.0)):
			_dir(-toward)
			return
		_dir(toward if player.facing != int(toward) else 0.0)
		if _frame % 4 == 0:
			_press("attack%d" % (slot + 1))
		return
	var reach: Vector2 = data.moves[0]["reach"]
	if dist > reach.x * 0.8 or absf(d.y) > 20.0:
		_dir(toward)
		if absf(d.y) > 20.0 and d.y < 0.0 and player.is_on_floor() and dist < 40.0:
			_press("jump")
		return
	_dir(toward)
	if _frame % 3 == 0:
		_press("attack%d" % (slot + 1))


func _weapon_for(dist: float) -> int:
	var melee := -1
	var bow := -1
	for slot in 2:
		var g := player.weapon(slot)
		if g == null:
			continue
		if (g.data as WeaponData).category == "bow":
			bow = slot
		else:
			melee = slot
	if melee >= 0 and (dist < 60.0 or bow < 0):
		return melee
	return bow if bow >= 0 else 0


# --- caminho ------------------------------------------------------------------

func _navigate(delta: float) -> void:
	if _goal == null or not is_instance_valid(_goal) or not _wanted(_goal):
		_choose_goal()
		if _goal == null:
			return
	var target := _goal.global_position
	var close := absf(target.x - player.global_position.x) < ARRIVE and absf(target.y - player.global_position.y) < 20.0
	if close and player.is_on_floor():
		if _interact_wait <= 0.0:
			_press("interact")
			_interact_wait = 0.6
			if not (_goal is ExitGate):
				_skip.append(_goal)
				_goal = null
		return
	_replan -= delta
	var here := nav.cell_of(player.global_position)
	if player.is_on_floor() and (_path.is_empty() or _replan <= 0.0 or not _on_track(here)):
		_path = nav.path(here, _goal_cell)
		_replan = 2.0
		if _path.is_empty() and nav.knows(here):
			_skip.append(_goal)
			_goal = null
			return
	while not _path.is_empty() and here == _path[0][0] and player.is_on_floor():
		_path.pop_front()
	_watch_progress(delta, here)
	if _path.is_empty():
		_dir(signf(target.x - player.global_position.x))
		return
	_follow(_path[0])


func _on_track(here: Vector2i) -> bool:
	if _path.is_empty():
		return false
	if here == _path[0][0]:
		return true
	# ainda na célula de onde o próximo passo parte?
	for i in mini(2, _path.size()):
		if _path[i][0] == here:
			return true
	var first: Vector2i = _path[0][0]
	return absi(first.x - here.x) <= 6 and absi(first.y - here.y) <= 5


func _follow(step: Array) -> void:
	var cell: Vector2i = step[0]
	var kind: String = step[1]
	var at := BotNav.center_of(cell)
	var dx := at.x - player.global_position.x
	var below := player.global_position.y - at.y     # > 0: o alvo está acima
	match kind:
		"drop":
			if player.is_on_floor():
				_hold("down")
				_press("jump")
			return
		"jump":
			if player.is_on_floor() and _jumping <= 0:
				_jumping = 22
				_press("jump")
				if below <= 8.0:
					_dir(signf(dx))
				return
			if _jumping > 0:
				_jumping -= 1
				_hold("jump")
			var rising := player.velocity.y < -60.0
			if below > 4.0 and rising and absf(dx) < 22.0:
				return
			_dir(signf(dx) if absf(dx) > 2.0 else 0.0)
		_:
			_jumping = 0
			_dir(signf(dx) if absf(dx) > 3.0 else 0.0)


func _watch_progress(delta: float, here: Vector2i) -> void:
	var left := _path.size() * 100 + absi(here.x - _goal_cell.x) + absi(here.y - _goal_cell.y)
	if left < _best_left:
		_best_left = left
		_progress_clock = 0.0
		return
	_progress_clock += delta
	if _progress_clock > STUCK_SKIP and not _path.is_empty():
		# preso: anota onde foi e empurra o herói para o próximo passo
		stuck_events.append([level.kind, here, _path.slice(0, 3), player.global_position.round(), "%s estado %d %s" % [_goal.name if _goal else "", player.state, _why]])
		player.global_position = BotNav.center_of(_path[0][0])
		player.velocity = Vector2.ZERO
		_progress_clock = 0.0
		_best_left = 999999
	elif _progress_clock > STUCK_JUMP and player.is_on_floor() and _frame % 40 == 0:
		_press("jump")
		_dir(-1.0 if rng.randf() < 0.5 else 1.0)


# --- o que fazer no andar -----------------------------------------------------

func _wanted(it: Node2D) -> bool:
	if _skip.has(it) or not it.visible:
		return false
	if it is ExitGate:
		return true
	if not it.has_method("can_interact") or not it.call("can_interact", player):
		return false
	if it is Pickup:
		return _better(it.gear)
	if it is Chest:
		return not it.cursed
	if it is Merchant:
		return player.gold >= 75
	return it is Altar or it is RuneAltar or it is Keeper or it is MutationAltar


func _better(g: Gear) -> bool:
	var list: Array = player.weapons if g.is_weapon() else player.skills
	for cur in list:
		if cur == null:
			return true
	var worst := 99
	for cur: Gear in list:
		worst = mini(worst, cur.tier)
	return g.tier > worst


func _choose_goal() -> void:
	_goal = null
	_path.clear()
	var here := nav.cell_of(player.global_position)
	var gates: Array[Node2D] = []
	var best: Node2D = null
	var best_d := INF
	for it: Node2D in level.get_tree().get_nodes_in_group("interactables"):
		if not _wanted(it):
			continue
		if it is ExitGate:
			gates.append(it)
			continue
		var d := it.global_position.distance_to(player.global_position)
		if d < best_d:
			best = it
			best_d = d
	if best == null and not gates.is_empty():
		gates.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.x < b.global_position.x)
		best = gates[exit_pick % gates.size()] if level.kind == "passagem" else gates[0]
	if best == null:
		return
	_goal = best
	_goal_cell = nav.cell_of(best.global_position)
	_best_left = 999999
	_progress_clock = 0.0
	if not nav.knows(here):
		return
