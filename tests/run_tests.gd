extends Node

# Roda com:  Godot --headless --fixed-fps 60 --path . res://tests/run_tests.tscn
# Cada teste monta uma sala mínima, troca o controle por um roteiro e
# confere o resultado na física real do jogo. Nada aqui toca o save real.

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

const WIDE := """
##################################
#................................#
#................................#
#................................#
#................................#
#................................#
#................................#
#..P.............................#
##################################
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
	Meta.use_path("user://teste.save", true)
	Sfx.muted = true

	await _case("pulo sobe ~3 blocos", _jump_height)
	await _case("soltar o pulo cedo dá pulo curto", _short_hop)
	await _case("ainda pula logo depois de sair da beirada", _coyote)
	await _case("não pula no ar depois da tolerância", _no_air_jump)
	await _case("rolagem deixa invencível", _roll_dodges)
	await _case("combo da espada tira 10+12+26", _combo_damage)
	await _case("agarra a beirada e sobe muro de 4 blocos", _ledge_climb)
	await _case("S + pulo desce da plataforma", _drop_through)
	await _case("penitente avisa e acerta quem fica parado", _grunt_hits)
	await _case("golpe durante o aviso interrompe o penitente", _interrupt)
	await _case("estilhaço acerta quem fica parado", _shard_hits)
	await _case("estilhaço atravessa quem rola", _shard_dodged)
	await _case("mergulho machuca quem está embaixo", _dive)
	await _case("frasco cura metade da vida", _heal)
	await _case("arco atira e crítico de longe vale mais", _bow_far_crit)
	await _case("granada explode e queima", _bomb)
	await _case("atributo aumenta o dano da arma certa", _stat_scaling)
	await _case("guarda defende de frente e apanha pelas costas", _guard_shield)
	await _case("aparo devolve o estilhaço", _parry_reflects)
	await _case("peregrino explode e queima", _pilgrim)
	await _case("assassino enterrado não leva dano", _assassin_hidden)
	await _case("profecia do imperador mira à frente do herói", _emperor_prophecy)
	await _case("altar sobe o atributo escolhido", _altar)
	await _case("matar inimigo solta essência", _essence)
	await _case("desbloqueio fica salvo", _meta_unlock)
	await _case("armas e habilidades carregam", _content_loads)
	await _case("gerador: 20 mapas com caminho do início à saída", _generator)
	await _case("sala do chefe carrega com o imperador", _boss_room)
	await _case("sala de treino carrega", _training_room)
	await _case("aparências: trancadas, compradas, feitos e salvas", _skins)
	await _case("fonte tem toda letra dos textos do jogo", _font_covers_text)

	print("")
	print("%d ok, %d falhas" % [_passed, _failures.size()])
	for f in _failures:
		print("  FALHOU: " + f)
	Meta.use_path("user://teste.save", true)
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
	level.rng.seed = 1
	add_child(level)
	level.build(text, false)
	input = ScriptedInput.new()
	level.player.pad = input
	Run.carry = {}
	Run.load_player(level.player)
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _run_until_idle(limit := 600) -> void:
	var n := 0
	while input.busy() and n < limit:
		await get_tree().physics_frame
		n += 1


func _calm(e: Enemy) -> Enemy:
	e.set_physics_process(false)
	return e


func _dealt(e: Enemy) -> int:
	return e.max_hp - e.hp if is_instance_valid(e) and e.alive() else e.max_hp


# --- movimento ------------------------------------------------------------------

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
	var hit := p.hurt(Damage.make(20, 1))
	_check(not hit and p.hp == p.max_hp, "levou dano rolando (hp %d)" % p.hp)


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


func _heal() -> void:
	await _load(FLAT)
	var p := level.player
	p.hp = 40
	var flasks := p.flasks
	input.then(["heal"], 2).wait(50)
	await _run_until_idle()
	_check(p.hp == 40 + roundi(p.max_hp * Player.FLASK_HEAL_RATIO) and p.flasks == flasks - 1,
		"hp %d, frascos %d" % [p.hp, p.flasks])


# --- combate -------------------------------------------------------------------

func _combo_damage() -> void:
	await _load(FLAT)
	var p := level.player
	var e := _calm(level.spawn("grunt", p.global_position + Vector2(20, 0)))
	for i in 3:
		input.then(["attack1"], 2).wait(14)
	input.wait(30)
	await _run_until_idle()
	_check(_dealt(e) == 48, "tirou %d de vida (esperado 10+12+26)" % _dealt(e))


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
	_check(p.hp < p.max_hp, "o penitente não acertou")


func _interrupt() -> void:
	await _load(FLAT)
	var p := level.player
	var e: Grunt = level.spawn("grunt", p.global_position + Vector2(22, 0))
	var n := 0
	while e.state != "windup" and n < 120:
		await get_tree().physics_frame
		n += 1
	input.then(["attack1"], 2).wait(20)
	await _frames(12)
	_check(e.state == "stun", "penitente em '%s', devia estar atordoado" % e.state)
	await _frames(20)
	_check(p.hp == p.max_hp, "levou o golpe mesmo interrompendo (hp %d)" % p.hp)


func _shard(from: Vector2, vel: Vector2) -> Projectile:
	var s := Projectile.new()
	s.room = level.room
	s.team = "enemy"
	s.style = "shard"
	s.position = from
	s.velocity = vel
	s.damage = Damage.make(12, -1, 100)
	level.add_child(s)
	return s


func _shard_hits() -> void:
	await _load(FLAT)
	var p := level.player
	_shard(p.center() + Vector2(70, 0), Vector2(-250, 0))
	input.wait(40)
	await _run_until_idle()
	_check(p.hp == p.max_hp - 12, "hp %d, esperado %d" % [p.hp, p.max_hp - 12])


func _shard_dodged() -> void:
	await _load(FLAT)
	var p := level.player
	_shard(p.center() + Vector2(70, 0), Vector2(-250, 0))
	input.then(["right", "roll"], 2).wait(40)
	await _run_until_idle()
	_check(p.hp == p.max_hp, "o estilhaço acertou rolando (hp %d)" % p.hp)


func _dive() -> void:
	await _load(FLAT)
	var p := level.player
	var e := _calm(level.spawn("grunt", p.global_position))
	p.global_position.y -= 70.0
	await _frames(2)
	input.then(["down", "attack1"], 3).wait(40)
	await _run_until_idle()
	_check(_dealt(e) >= int(Player.DIVE_DAMAGE), "mergulho tirou %d" % _dealt(e))


func _bow_far_crit() -> void:
	await _load(WIDE)
	var p := level.player
	var near := _calm(level.spawn("grunt", p.global_position + Vector2(60, 0)))
	input.then(["attack2"], 2).wait(50)
	await _run_until_idle()
	var near_dmg := _dealt(near)
	near.queue_free()
	await _frames(2)
	var far := _calm(level.spawn("grunt", p.global_position + Vector2(200, 0)))
	input.then(["attack2"], 2).wait(60)
	await _run_until_idle()
	_check(near_dmg == 12, "de perto tirou %d (esperado 12)" % near_dmg)
	_check(_dealt(far) > near_dmg, "de longe tirou %d, devia ser crítico" % _dealt(far))


func _bomb() -> void:
	await _load(WIDE)
	var p := level.player
	var e := _calm(level.spawn("grunt", p.global_position + Vector2(55, 0)))
	input.then(["skill1"], 2).wait(90)
	await _run_until_idle()
	_check(_dealt(e) >= 20, "granada tirou %d" % _dealt(e))
	_check(p.skill_cd[0] > 0.0, "sem recarga depois de usar")


func _stat_scaling() -> void:
	await _load(FLAT)
	var p := level.player
	p.levels["furia"] = 2
	var e := _calm(level.spawn("grunt", p.global_position + Vector2(20, 0)))
	input.then(["attack1"], 2).wait(30)
	await _run_until_idle()
	_check(_dealt(e) == roundi(10 * 1.3), "com Fúria 2 tirou %d (esperado 13)" % _dealt(e))


func _guard_shield() -> void:
	await _load(WIDE)
	var p := level.player
	var g: ShieldGuard = level.spawn_script("res://scripts/enemies/shield_guard.gd", p.global_position + Vector2(24, 0))
	g.facing = -1
	_calm(g)
	var front := Damage.make(10, 1, 50)
	_check(not g.hurt(front) and front.blocked and g.hp == g.max_hp, "levou dano de frente (hp %d)" % g.hp)
	var back := Damage.make(10, -1, 50)
	_check(g.hurt(back) and g.hp == g.max_hp - 10, "não levou dano pelas costas (hp %d)" % g.hp)


func _parry_reflects() -> void:
	await _load(WIDE)
	var p := level.player
	p.skills[1] = Gear.of(load("res://content/skills/egide_bronze.tres"))
	var archer := _calm(level.spawn("archer", p.global_position + Vector2(160, 0)))
	var s := _shard(p.center() + Vector2(40, 0), Vector2(-250, 0))
	s.source = archer
	s.damage.source = archer
	input.then(["right"], 1).then(["skill2"], 20).wait(60)
	await _run_until_idle()
	_check(p.hp == p.max_hp, "levou dano aparando (hp %d)" % p.hp)
	_check(_dealt(archer) > 0, "o estilhaço não voltou no atirador")


func _pilgrim() -> void:
	await _load(WIDE)
	var p := level.player
	var pil: Pilgrim = level.spawn_script("res://scripts/enemies/pilgrim.gd", p.global_position + Vector2(60, 0))
	var n := 0
	while is_instance_valid(pil) and n < 300:
		await get_tree().physics_frame
		n += 1
	_check(not is_instance_valid(pil), "não explodiu")
	_check(p.hp < p.max_hp, "a explosão não machucou")
	_check(p.has_status("burn") or p.hp <= p.max_hp - 22, "não queimou")


func _assassin_hidden() -> void:
	await _load(WIDE)
	var p := level.player
	var a: Assassin = level.spawn_script("res://scripts/enemies/assassin.gd", p.global_position + Vector2(150, 0))
	await _frames(3)
	_check(a.ghost and not a.hurt(Damage.make(50, 1, 0)) and a.hp == a.max_hp, "levou dano enterrado")
	var n := 0
	while a.state != "rise" and n < 300:
		await get_tree().physics_frame
		n += 1
	_check(a.state == "rise", "não emergiu perto do herói")
	_check(not a.ghost and a.hurt(Damage.make(5, 1, 0)), "emergiu mas continua intocável")


func _emperor_prophecy() -> void:
	await _load(WIDE)
	var p := level.player
	var boss: BlindEmperor = level.spawn_script("res://scripts/enemies/blind_emperor.gd", p.global_position + Vector2(300, 0))
	boss.arena = Rect2(16, 0, level.room.size_px().x - 32, level.room.size_px().y)
	_calm(boss)
	boss.set_state("idle")
	p.velocity.x = Player.RUN_SPEED
	var ahead := boss.predict()
	_check(ahead > p.global_position.x + 80.0, "previu %.0f para herói em %.0f indo à direita" % [ahead, p.global_position.x])
	p.velocity.x = 0.0
	_check(absf(boss.predict() - p.global_position.x) < 1.0, "parado, devia mirar onde ele está")
	var before := boss.hp
	boss.hurt(Damage.make(10, 1, 0))
	_check(boss.state != "stun", "golpe comum interrompeu o chefe")
	_check(boss.hp < before, "chefe não levou dano")


func _altar() -> void:
	await _load(FLAT)
	var p := level.player
	var menu := Menu.new()
	add_child(menu)
	var altar := Altar.new()
	altar.position = p.global_position
	level.add_child(altar)
	altar.interact(p)
	_check(menu.is_open(), "o menu do fragmento não abriu")
	menu.choose(2)
	_check(p.levels["vigor"] == 1 and p.max_hp == Player.BASE_HP + 20, "vigor %d, vida máx %d" % [p.levels["vigor"], p.max_hp])
	_check(not get_tree().paused, "o jogo ficou pausado")
	menu.queue_free()


func _essence() -> void:
	await _load(FLAT)
	var p := level.player
	var e := level.spawn("grunt", p.global_position + Vector2(18, 0))
	var least := e.essence_drop.x
	e.hurt(Damage.make(999, 1, 0))
	await _frames(90)
	_check(p.essence >= least and least > 0, "essência %d" % p.essence)


func _meta_unlock() -> void:
	Meta.unlock("lanca_peregrino")
	Meta.use_path("user://teste.save")
	_check(Meta.is_unlocked("lanca_peregrino"), "desbloqueio sumiu ao recarregar")
	var pool := Catalog.unlocked_pool().map(func(r: Resource) -> String: return r.id)
	_check(pool.has("lanca_peregrino") and not pool.has("machado_carrasco"), "pool errado: %s" % [pool])
	Meta.use_path("user://teste.save", true)


func _content_loads() -> void:
	for r in Catalog.all_gear():
		_check(r != null and r.id != "" and r.title != "", "item sem id/título")
		if r is WeaponData:
			var w: WeaponData = r
			_check(w.category == "bow" or w.moves.size() > 0, w.id + " sem golpes")
			_check(w.category != "bow" or w.shot.has("draw"), w.id + " sem tiro")
	var b := Catalog.biome("mar_de_cinzas")
	_check(b.enemies.size() >= 4 and b.lore.size() >= 5, "bioma incompleto")
	for e: Dictionary in b.enemies:
		_check(ResourceLoader.exists(e["script"]), "script faltando: " + e["script"])


func _generator() -> void:
	var b := Catalog.biome("mar_de_cinzas")
	var pool := LevelGen.load_dir(b.rooms_dir)
	for seed_value in 20:
		var lines := LevelGen.new().generate(pool, seed_value * 31 + 5, b.combat_rooms)
		if lines.is_empty():
			_check(false, "semente %d não gerou" % seed_value)
			return
		var why := _path_problem(lines)
		if why != "":
			_check(false, "semente %d: %s" % [seed_value, why])
			return


# Flood fill pelas células vazias: não é a física, mas pega sala sem saída e
# porta emparedada.
func _path_problem(lines: PackedStringArray) -> String:
	var start := Vector2i(-1, -1)
	var goal := Vector2i(-1, -1)
	for y in lines.size():
		var x := lines[y].find("P")
		if x >= 0:
			start = Vector2i(x, y)
		x = lines[y].find("X")
		if x >= 0:
			goal = Vector2i(x, y)
	if start.x < 0:
		return "sem início"
	if goal.x < 0:
		return "sem saída"
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if n.y < 0 or n.y >= lines.size() or n.x < 0 or n.x >= lines[n.y].length():
				continue
			if lines[n.y][n.x] == "#" or seen.has(n):
				continue
			seen[n] = true
			todo.append(n)
	return "" if seen.has(goal) else "a saída não é alcançável"


func _boss_room() -> void:
	if level:
		remove_child(level)
		level.queue_free()
	level = Level.new()
	add_child(level)
	level.build_boss(Catalog.biome("mar_de_cinzas"), 1, false)
	await _frames(3)
	_check(level.boss is BlindEmperor, "sem chefe")
	var gates := level.get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	_check(gates.size() == 3, "%d saídas" % gates.size())
	_check(gates.all(func(g: Node2D) -> bool: return not g.visible), "saída visível antes da vitória")
	level.boss.set_state("idle")
	level.boss.hurt(Damage.make(99999, 1, 0))
	await _frames(3)
	_check(gates.all(func(g: Node2D) -> bool: return g.visible), "saídas não abriram depois da vitória")


func _training_room() -> void:
	await _load(FileAccess.get_file_as_string("res://tests/salas/treino.txt"))
	_check(level.room.cols == 80 and level.room.rows == 22, "tamanho %dx%d" % [level.room.cols, level.room.rows])
	_check(level.enemies().size() == 5, "%d inimigos" % level.enemies().size())
	await _frames(30)
	_check(level.player.is_on_floor(), "herói não pousou no chão")


func _skins() -> void:
	Meta.use_path("user://teste.save", true)
	var all := Catalog.skins()
	_check(all.size() >= 6, "faltam aparências")
	_check(Meta.current_skin().id == "andarilho", "começa sem a inicial")
	var vidro := Catalog.skin("casca_vidro")
	var olhos := Catalog.skin("olhos_fechados")
	_check(not Meta.has_skin(vidro) and not Meta.has_skin(olhos), "trancada aparece liberada")
	Meta.wear("casca_vidro")
	_check(Meta.current_skin().id == "andarilho", "vestiu aparência que não tem")
	Meta.unlock("casca_vidro")
	Meta.record_run(true, 3)
	_check(Meta.has_skin(vidro) and Meta.has_skin(olhos), "compra ou feito não liberou")
	Meta.wear("olhos_fechados")
	Meta.use_path("user://teste.save")
	_check(Meta.current_skin().id == "olhos_fechados", "escolha não ficou salva")
	var p := Player.new()
	add_child(p)
	_check(p.skin.id == "olhos_fechados", "herói não usou a aparência")
	p.queue_free()
	Meta.use_path("user://teste.save", true)


func _font_covers_text() -> void:
	var texts: Array[String] = ["ÁÀÂÃÉÊÍÓÔÕÚÇ ÇÃO NÍVEL FÚRIA ASTÚCIA ESSÊNCIA", Screen.TITLE_OPTIONS.map(func(o: Array) -> String: return o[1]).reduce(func(a: String, b: String) -> String: return a + b, "")]
	var b := Catalog.biome("mar_de_cinzas")
	texts.append(b.title)
	texts.append(b.subtitle)
	for l in b.lore:
		texts.append(String(l))
	for r in Catalog.all_gear():
		texts.append(r.title)
		texts.append(r.lore)
	for k in Catalog.skins():
		texts.append(k.title + k.lore + k.how_to_get())
	for bl: Dictionary in Catalog.BLESSINGS:
		texts.append(String(bl["title"]) + String(bl["detail"]))
	var missing := {}
	for t in texts:
		for ch in t.to_upper():
			var base: String = PixelFont.ACCENTS[ch][0] if PixelFont.ACCENTS.has(ch) else ch
			if not PixelFont.BODY.has(base) or not PixelFont.GLYPHS.has(base) and base not in ["↑", "↓"]:
				missing[ch] = true
	_check(missing.is_empty(), "sem desenho: %s" % [missing.keys()])
