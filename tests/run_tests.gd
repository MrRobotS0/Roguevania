extends Node

# Roda com:  Godot --headless --fixed-fps 60 --path . res://tests/run_tests.tscn
# Cada teste monta uma sala mínima, troca o controle por um roteiro e
# confere o resultado na física real do jogo.

const FLAT := """
######################
#....................#
#....................#
#....................#
#....................#
#....................#
#....................#
#..P.................#
######################
"""

const LEDGE := """
##################
#................#
#................#
#................#
#................#
#................#
#.........########
#.........########
#.........########
#..P......########
##################
"""

const CLIFF := """
######################
#....................#
#....................#
#....................#
#....................#
#..P.................#
##########...........#
##########...........#
##########...........#
##########...........#
##########...........#
##########...........#
##########...........#
##########...........#
##########...........#
##########...........#
######################
"""

const PLATFORM := """
##############
#............#
#............#
#....P.......#
#..=======...#
#............#
#............#
##############
"""

var level: Level
var input: ScriptedInput
var _failures: Array[String] = []
var _passed := 0


func _ready() -> void:
	await _case("pulo sobe ~3 blocos", _jump_height)
	await _case("soltar o pulo cedo dá pulo curto", _short_hop)
	await _case("ainda pula logo depois de sair da beirada", _coyote)
	await _case("não pula no ar depois da tolerância", _no_air_jump)
	await _case("rolagem deixa invencível", _roll_dodges)
	await _case("combo de 3 golpes tira 48 de vida", _combo_damage)
	await _case("agarra a beirada e sobe muro de 4 blocos", _ledge_climb)
	await _case("S + pulo desce da plataforma", _drop_through)
	await _case("brutamontes avisa e acerta quem fica parado", _grunt_hits)
	await _case("golpe durante o aviso interrompe o brutamontes", _interrupt)
	await _case("flecha acerta quem fica parado", _arrow_hits)
	await _case("flecha atravessa quem rola", _arrow_dodged)
	await _case("mergulho machuca quem está embaixo", _dive)
	await _case("frasco cura", _heal)
	await _case("sala de treino carrega", _training_room)

	print("")
	print("%d ok, %d falhas" % [_passed, _failures.size()])
	for f in _failures:
		print("  FALHOU: " + f)
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _case(name: String, test: Callable) -> void:
	var before := _failures.size()
	await test.call()
	if _failures.size() == before:
		_passed += 1
		print("ok      " + name)
	else:
		print("FALHOU  " + name + "  -> " + _failures[-1])
		_failures[-1] = name + ": " + _failures[-1]
	Engine.time_scale = 1.0


func _check(cond: bool, why: String) -> void:
	if not cond:
		_failures.append(why)


func _load(text: String) -> void:
	if level:
		remove_child(level)
		level.queue_free()
	level = Level.new()
	add_child(level)
	level.build(text, false)
	input = ScriptedInput.new()
	level.player.pad = input
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _run_until_idle(limit := 600) -> void:
	var n := 0
	while input.busy() and n < limit:
		await get_tree().physics_frame
		n += 1


# --- casos --------------------------------------------------------------------

func _jump_height() -> void:
	await _load(FLAT)
	var p := level.player
	var ground := p.global_position.y
	var top := ground
	input.then(["jump"], 50)
	for i in 50:
		await get_tree().physics_frame
		top = minf(top, p.global_position.y)
	var rise := ground - top
	_check(rise > 46.0 and rise < 58.0, "subiu %.1f px (esperado 46-58)" % rise)


func _short_hop() -> void:
	await _load(FLAT)
	var p := level.player
	var ground := p.global_position.y
	var top := ground
	input.then(["jump"], 3).wait(40)
	for i in 43:
		await get_tree().physics_frame
		top = minf(top, p.global_position.y)
	var rise := ground - top
	_check(rise > 4.0 and rise < 30.0, "pulo curto subiu %.1f px (esperado 4-30)" % rise)


func _walk_off_cliff(extra_frames: int) -> void:
	await _load(CLIFF)
	var p := level.player
	input.then(["right"], 300)
	var n := 0
	while p.is_on_floor() and n < 200:
		await get_tree().physics_frame
		n += 1
	await _frames(extra_frames)
	input.clear().then(["right", "jump"], 6)
	await _frames(3)


func _coyote() -> void:
	await _walk_off_cliff(2)
	var vy := level.player.velocity.y
	_check(vy < -150.0, "velocidade vertical %.0f, devia estar subindo" % vy)


func _no_air_jump() -> void:
	await _walk_off_cliff(14)
	var vy := level.player.velocity.y
	_check(vy > 0.0, "pulou no ar (vy %.0f)" % vy)


func _roll_dodges() -> void:
	await _load(FLAT)
	var p := level.player
	input.then(["roll"], 2).wait(30)
	await _frames(4)
	var hit := p.take_damage(20, 1)
	_check(not hit and p.hp == p.max_hp, "levou dano rolando (hp %d)" % p.hp)


func _combo_damage() -> void:
	await _load(FLAT)
	var p := level.player
	var e := level.spawn("grunt", p.global_position + Vector2(20, 0))
	e.set_physics_process(false)
	for i in 3:
		input.then(["attack"], 2).wait(14)
	input.wait(30)
	await _run_until_idle()
	var dealt := e.max_hp - e.hp if is_instance_valid(e) else e.max_hp
	_check(dealt == 48, "tirou %d de vida (esperado 10+12+26)" % dealt)


func _ledge_climb() -> void:
	await _load(LEDGE)
	var p := level.player
	input.then(["right"], 20).then(["right", "jump"], 30).then(["right"], 40)
	await _run_until_idle()
	var wall_top := 6 * Room.TILE
	_check(absf(p.global_position.y - wall_top) < 2.0 and p.global_position.x > 10 * Room.TILE,
		"terminou em %s, devia estar em cima do muro (y=%d)" % [p.global_position, wall_top])


func _drop_through() -> void:
	await _load(PLATFORM)
	var p := level.player
	await _frames(30)
	var on_plank := p.global_position.y
	input.then(["down", "jump"], 4).wait(40)
	await _run_until_idle()
	_check(p.global_position.y > on_plank + 20.0, "continuou na plataforma (y %.0f)" % p.global_position.y)


func _grunt_hits() -> void:
	await _load(FLAT)
	var p := level.player
	level.spawn("grunt", p.global_position + Vector2(60, 0))
	var saw_warning := false
	for i in 150:
		await get_tree().physics_frame
		for e: Enemy in level.enemies():
			saw_warning = saw_warning or e.telegraphing()
	_check(saw_warning, "o golpe veio sem aviso")
	_check(p.hp < p.max_hp, "o brutamontes não acertou")


func _interrupt() -> void:
	await _load(FLAT)
	var p := level.player
	var e: Grunt = level.spawn("grunt", p.global_position + Vector2(22, 0))
	var n := 0
	while e.state != "windup" and n < 120:
		await get_tree().physics_frame
		n += 1
	input.then(["attack"], 2).wait(20)
	await _frames(12)
	_check(e.state == "stun", "brutamontes em '%s', devia estar atordoado" % e.state)
	await _frames(20)
	_check(p.hp == p.max_hp, "levou o golpe mesmo interrompendo (hp %d)" % p.hp)


func _shoot_at_player(roll: bool) -> Player:
	await _load(FLAT)
	var p := level.player
	var arrow := Arrow.new()
	arrow.room = level.room
	arrow.position = p.center() + Vector2(70, 0)
	arrow.velocity = Vector2(-250, 0)
	level.add_child(arrow)
	if roll:
		input.then(["right", "roll"], 2).wait(40)
	else:
		input.wait(40)
	await _run_until_idle()
	return p


func _arrow_hits() -> void:
	var p := await _shoot_at_player(false)
	_check(p.hp == p.max_hp - 12, "hp %d, esperado %d" % [p.hp, p.max_hp - 12])


func _arrow_dodged() -> void:
	var p := await _shoot_at_player(true)
	_check(p.hp == p.max_hp, "a flecha acertou rolando (hp %d)" % p.hp)


func _dive() -> void:
	await _load(FLAT)
	var p := level.player
	var e := level.spawn("grunt", p.global_position + Vector2(0, 0))
	e.set_physics_process(false)
	p.global_position.y -= 70.0
	await _frames(2)
	input.then(["down", "attack"], 3).wait(40)
	await _run_until_idle()
	var dealt := e.max_hp - e.hp if is_instance_valid(e) else e.max_hp
	_check(dealt >= Player.DIVE_DAMAGE, "mergulho tirou %d" % dealt)


func _heal() -> void:
	await _load(FLAT)
	var p := level.player
	p.hp = 40
	input.then(["heal"], 2).wait(50)
	await _run_until_idle()
	_check(p.hp == 40 + Player.FLASK_HEAL and p.flasks == Player.MAX_FLASKS - 1,
		"hp %d, frascos %d" % [p.hp, p.flasks])


func _training_room() -> void:
	await _load(FileAccess.get_file_as_string("res://rooms/treino.txt"))
	_check(level.room.cols == 80 and level.room.rows == 22, "tamanho %dx%d" % [level.room.cols, level.room.rows])
	_check(level.enemies().size() == 5, "%d inimigos" % level.enemies().size())
	await _frames(30)
	_check(level.player.is_on_floor(), "herói não pousou no chão")
