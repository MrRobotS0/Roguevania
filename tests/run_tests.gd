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

	await _case("todo script compila e a tela principal abre", _all_scripts)
	await _case("pulo sobe ~3,9 blocos", _jump_height)
	await _case("soltar o pulo cedo dá pulo curto", _short_hop)
	await _case("ainda pula logo depois de sair da beirada", _coyote)
	await _case("no ar, depois da tolerância, só sobra o pulo duplo", _no_air_jump)
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
	await _case("rota: Mar, passagem, escolha de andar, Trono", _route)
	await _case("gerador: os 3 andares com loja, cofre, runa e relógio", _generator_floors)
	await _case("passagem tem Vigia, altar e as saídas certas", _passage)
	await _case("altar de mutação e Sangue Quente", _mutations)
	await _case("baú maldito: qualquer golpe mata", _cursed_chest)
	await _case("porta do relógio abre a tempo e fecha atrasada", _timed_door)
	await _case("planta cai, a Vigia guarda e passa a vender", _blueprints)
	await _case("Asa de Cinza dá pulo duplo", _double_jump)
	await _case("parede rachada só cede com o Punho", _cracked_wall)
	await _case("brasas: inimigo mais forte e bate mais", _heat)
	await _case("final verdadeiro: as cadeiras, o desfecho e o Novo Jogo+", _true_ending)
	await _case("a Beira: renasce nela, escolhe, e só o arco começa a partida", _beira)
	await _case("Modo Waves: arena na tela, frasco de 2 usos, guardião e próximo domínio", _waves)
	await _case("Modo Waves: todo guardião e todo inimigo funcionam na arena", _waves_cast)
	await _case("Desafio da Semana: regras iguais para todos e cada uma vale", _weekly)
	await _case("mercador vende e o item aparece", _merchant)
	await _case("ferreiro, escória, lobo e sentinela acertam", _new_enemies)
	await _case("jato de fogo e estalactite machucam", _hazards)
	await _case("opções: volume, tremor e troca de tecla", _options)
	await _case("armadilha, torreta, espírito e corrente acertam", _new_skills)
	await _case("afixos: afiada dá mais dano, vampira cura", _affixes)
	await _case("sobe degrau de 3 blocos só com o pulo simples, e sai pelo vão do teto", _climb_stack)
	await _case("os 7 guardiões lutam e acertam o herói", _bosses)
	await _case("cada inimigo novo faz o que só ele faz", _new_behaviors)
	await _case("cada guardião novo tem a sua mecânica", _boss_mechanics)
	await _case("a barra de vida fica por cima e acima do desenho", _enemy_bar)
	await _case("inimigos dos domínios novos acertam", _domain_enemies)
	await _case("desafio do dia, estatísticas e recorde", _extras)
	await _case("os 6 elites dos domínios atacam e acertam", _elites)
	await _case("história: abertura, final, códice", _story)
	await _case("armas novas acertam (a foice dos dois lados)", _new_weapons)
	await _case("mutações novas: couraça, teimosia, barganha, passo, sede", _new_mutations)
	await _case("partida salva: sai, fecha e continua do mesmo andar", _save_resume)
	await _case("esquiva no ar anda reta, pulo emenda a rolagem, mergulho quica", _fluid_moves)
	await _case("inglês: textos fixos, com número e montados; fonte cobre tudo", _english)
	await _case("atualização: compara versões e fica quieta fora do jogo exportado", _updater)
	await _case("cromas: trancados, comprados na Vigia, vestidos e salvos", _chromas)
	await _case("dicas: aparecem na hora, somem ao aprender, uma vez só", _guide)
	await _case("HUD: cada domínio tem a sua pele e ela cabe na tela", _hud_skins)
	await _case("créditos: a arte CC-BY aparece no título, nos dois idiomas", _credits)

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
	_check(rise > 58.0 and rise < 64.0, "subiu %.1f px (esperado 58-64)" % rise)


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
	Meta.use_path("user://teste.save", true)
	await _walk_off_cliff(14)
	var p := level.player
	_check(p.velocity.y < 0.0, "o pulo duplo não saiu (vy %.0f)" % p.velocity.y)
	while p.velocity.y < 0.0:
		await get_tree().physics_frame
	input.clear().then(["right", "jump"], 6)
	await _frames(3)
	_check(p.velocity.y > 0.0, "pulou uma terceira vez sem a runa (vy %.0f)" % p.velocity.y)


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
	_check(gates.size() == 1, "%d saídas" % gates.size())
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
	var texts: Array[String] = ["ÁÀÂÃÉÊÍÓÔÕÚÇ ÇÃO NÍVEL FÚRIA ASTÚCIA ESSÊNCIA", (Screen.TITLE_OPTIONS + Screen.EXTRAS).map(func(o: Array) -> String: return o[1]).reduce(func(a: String, b: String) -> String: return a + b, "")]
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


# --- andares, passagem e o que se ganha no caminho ---------------------------------

const CRACK_ROOM := """
######################
#....................#
#....................#
#....................#
#..........K.........#
#..........K.........#
#..P.......K.........#
######################
"""


func _route() -> void:
	Run.new_run(5)
	_check(Run.current()["kind"] == "gerada" and Run.stage_id == "mar_de_cinzas", "não começou no Mar")
	Run.enter_passage()
	_check(Run.current()["kind"] == "passagem", "não entrou na passagem")
	_check(Run.next_options() == ["saloes", "forja_rubra", "necropole"], "saídas da passagem: %s" % [Run.next_options()])
	Run.go("forja_rubra")
	_check(Run.current()["biome"] == "forja_rubra" and Run.current()["kind"] == "gerada", "não foi para a Forja")
	Run.go(Run.boss_of("forja_rubra"))
	_check(Run.current()["kind"] == "chefe", "depois da Forja não veio o guardião")
	Run.enter_passage()
	_check(Run.next_options() == ["torre_babel", "jardim_primordial", "catedral"], "depois do Colosso: %s" % [Run.next_options()])
	Run.go("jardim_primordial")
	Run.go(Run.boss_of("jardim_primordial"))
	Run.enter_passage()
	Run.go("carcosa")
	Run.go(Run.boss_of("carcosa"))
	Run.enter_passage()
	_check(Run.next_options() == ["penhascos", "cavernas", "bosque"], "depois de Carcosa: %s" % [Run.next_options()])
	Run.go("bosque")
	Run.go(Run.boss_of("bosque"))
	Run.enter_passage()
	Run.go(Run.next_options()[0])
	_check(Run.stage_id == "trono" and Run.current()["kind"] == "chefe", "a rota não termina no Trono")
	_check(Run.path.size() == 10, "caminho %s" % [Run.path])


func _generator_floors() -> void:
	for id: String in Catalog.BIOMES:
		var b := Catalog.biome(id)
		var pool := LevelGen.load_dir(b.rooms_dir)
		var vaults := 0
		for seed_value in 12:
			var branches: Array = ["runa", ["cofre", "K"], "loja", "fragmento", "tesouro", "tesouro"]
			var lines := LevelGen.new().generate(pool, seed_value * 13 + 7, b.combat_rooms, branches)
			if lines.is_empty():
				_check(false, "%s semente %d não gerou" % [id, seed_value])
				return
			var why := _path_problem(lines)
			if why != "":
				_check(false, "%s semente %d: %s" % [id, seed_value, why])
				return
			var text := "\n".join(lines)
			_check(text.contains("T"), "%s sem Porta do Relógio" % id)
			if text.contains("K"):
				vaults += 1
		_check(vaults >= 6, "%s: cofre só apareceu %d de 12 vezes" % [id, vaults])


func _passage() -> void:
	Run.new_run(3)
	Run.enter_passage()
	if level:
		remove_child(level)
		level.queue_free()
	level = Level.new()
	add_child(level)
	level.build_passage(Catalog.biome("mar_de_cinzas"), 1, false)
	await _frames(3)
	var gates: Array = level.get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	var dests: Array = gates.map(func(g: ExitGate) -> String: return g.dest)
	_check(dests == ["saloes", "forja_rubra", "necropole"], "saídas %s" % [dests])
	_check(level.get_children().any(func(n: Node) -> bool: return n is Keeper), "sem Vigia na passagem")
	_check(level.get_children().any(func(n: Node) -> bool: return n is MutationAltar), "sem altar de mutação")


func _mutations() -> void:
	await _load(FLAT)
	var p := level.player
	var menu := Menu.new()
	add_child(menu)
	var altar := MutationAltar.new()
	altar.position = p.global_position
	level.add_child(altar)
	var first: String = altar.choices(p)[0]["id"]
	altar.interact(p)
	menu.choose(0)
	_check(p.has_mutation(first), "a mutação escolhida não entrou")
	p.mutations.assign(["sangue_quente"])
	p.hp = 50
	p.on_kill(null)
	_check(p.hp == 53, "Sangue Quente curou para %d" % p.hp)
	menu.queue_free()


func _cursed_chest() -> void:
	await _load(FLAT)
	var p := level.player
	var menu := Menu.new()
	add_child(menu)
	var chest := Chest.new()
	chest.cursed = true
	chest.level = level
	chest.position = p.global_position + Vector2(10, 0)
	level.add_child(chest)
	chest.interact(p)
	menu.choose(0)
	_check(p.curse == Chest.CURSE_KILLS, "maldição %d" % p.curse)
	await _frames(2)
	p.hurt(Damage.make(1, 1, 0))
	_check(p.hp == 0, "maldito sobreviveu com %d de vida" % p.hp)
	menu.queue_free()


func _timed_door() -> void:
	await _load(FLAT)
	var p := level.player
	Run.stage_time = 0.0
	var door := TimedDoor.new()
	door.player = p
	door.position = p.global_position + Vector2(24, 0)
	level.add_child(door)
	await _frames(3)
	_check(door.is_open, "chegou no tempo e a porta não abriu")
	var late := TimedDoor.new()
	late.player = p
	late.limit = 10.0
	late.position = p.global_position + Vector2(200, 0)
	level.add_child(late)
	Run.stage_time = 20.0
	await _frames(3)
	late.position = p.global_position + Vector2(20, 0)
	await _frames(3)
	_check(not late.is_open, "a porta abriu depois do tempo")


func _blueprints() -> void:
	Meta.use_path("user://teste.save", true)
	await _load(FLAT)
	var p := level.player
	_check(level.drop_blueprint(p.center()), "não caiu planta")
	await _frames(40)
	_check(p.blueprints.size() == 1, "planta não foi pega (%d)" % p.blueprints.size())
	var id: String = p.blueprints[0]
	var menu := Menu.new()
	add_child(menu)
	var keeper := Keeper.new()
	keeper.level = level
	keeper.position = p.global_position
	level.add_child(keeper)
	_check(not keeper._offers().any(func(o: Dictionary) -> bool: return o["id"] == id), "a Vigia vendia sem planta")
	keeper.interact(p)
	menu.close()
	_check(Meta.knows(id) and p.blueprints.is_empty(), "a Vigia não guardou a planta")
	_check(keeper._offers().any(func(o: Dictionary) -> bool: return o["id"] == id), "a Vigia não passou a vender")
	menu.queue_free()
	Meta.use_path("user://teste.save", true)


func _double_jump() -> void:
	Meta.use_path("user://teste.save", true)
	var tall := "#".repeat(12) + "
" + ("#..........#
").repeat(30) + "#....P.....#
" + "#".repeat(12)
	var heights: Array[float] = []
	for with_rune in [false, true]:
		if with_rune:
			Meta.add_rune("asa")
		await _load(tall)
		var p := level.player
		var ground := p.global_position.y
		input.then(["jump"], 14).wait(4).then(["jump"], 12).wait(4).then(["jump"], 12).wait(40)
		var top := ground
		for i in 90:
			await get_tree().physics_frame
			top = minf(top, p.global_position.y)
		heights.append(ground - top)
	_check(heights[0] > 80.0, "sem runa já tem pulo duplo: subiu só %.0f" % heights[0])
	_check(heights[1] > heights[0] + 20.0, "com a Asa subiu %.0f, sem subiu %.0f" % [heights[1], heights[0]])
	Meta.use_path("user://teste.save", true)


func _cracked_wall() -> void:
	Meta.use_path("user://teste.save", true)
	await _load(CRACK_ROOM)
	var p := level.player
	p.global_position.x = 11 * Room.TILE - 14
	await _frames(3)
	input.then(["attack1"], 2).wait(30)
	await _run_until_idle()
	_check(level.room.cell(11, 5) == "K", "a parede cedeu sem a runa")
	Meta.add_rune("punho")
	input.then(["attack1"], 2).wait(30)
	await _run_until_idle()
	_check(level.room.cell(11, 5) == ".", "a parede não cedeu com o Punho")
	Meta.use_path("user://teste.save", true)


func _true_ending() -> void:
	Meta.use_path("user://teste.save", true)
	_check(Story.SEATS.size() == 12 and Story.AFTER.size() == 13, "faltam deuses no desfecho")
	Lang.use("en")
	var texts: Array = []
	texts.append_array(Story.TRUE_ENDING)
	texts.append_array(Story.REVEAL)
	texts.append_array(Story.FINAL)
	texts.append_array(Story.PLUS_INTRO)
	texts.append_array(Story.PLUS_ENDING)
	texts.append_array(Story.KEEPER_AWAKE)
	for id: String in Story.SEATS:
		_check(Catalog.BIOMES.has(id), "domínio desconhecido: " + id)
		texts.append(Story.SEATS[id])
		texts.append(Story.god_name(id))
	for id: String in Story.AFTER:
		texts.append(Story.AFTER[id])
	texts.append(Story.god_name("mar_de_cinzas"))
	for t: String in texts:
		_check(Lang.t(t.to_upper()) != t.to_upper(), "sem inglês: " + t)
	_check(Lang.t("+50% DE VIDA E +30% DE DANO ALÉM DAS 4 BRASAS") == "+50% HEALTH AND +30% DAMAGE BEYOND THE 4 EMBERS", "ciclo: " + Lang.t("+50% DE VIDA E +30% DE DANO ALÉM DAS 4 BRASAS"))
	Lang.use("pt")

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await _frames(5)
	main.screen.close()
	# sem todas as brasas, o final continua igual e não há sala
	Run.new_run(7, 3)
	Run.stage_id = "trono"
	main._load_stage()
	await _frames(3)
	main._on_exit("fim")
	for i in Story.ENDING.size() * 2:
		main.cutscene.advance()
	_check(main.screen.mode == "victory" and not main.screen.to_title and not Meta.awake(), "o final comum mudou")
	main.screen.close()
	# com as quatro: a porta abre e o herói anda até as cadeiras
	Run.new_run(7, 4)
	Run.stage_id = "trono"
	main._load_stage()
	await _frames(3)
	main._on_exit("fim")
	for i in Story.ending_pages(4).size() * 2:
		main.cutscene.advance()
	await _frames(3)
	var hall: Level = main.level
	_check(Run.stage_id == Run.HALL and hall.kind == "sala" and hall.seats.size() == 12, "a sala não abriu (%s)" % Run.stage_id)
	_check(hall.get_children().filter(func(n: Node) -> bool: return n is Enemy).is_empty(), "tem inimigo na sala")
	_check(not Run.active, "o relógio andou na sala")
	_check(not Run.saved().is_empty() and Run.saved()["stage"] == Run.HALL, "sair na sala perde o lugar")
	var last: LastSeat = null
	for n in hall.get_children():
		if n is LastSeat:
			last = n
	_check(last != null, "falta a cadeira do herói")
	var hero: Player = hall.player
	_check(hero.is_on_floor() or hall.room.size_px().x > 1000.0, "sala pequena demais")
	last.interact(hero)
	await _frames(3)
	_check(main.level == hall and not main.cutscene.is_open(), "sentou antes de ver as outras cadeiras")
	var cold: GodSeat = hall.seats[hall.seats.size() - 1]
	_check(cold.cold and cold.prompt() == "OLHAR A CADEIRA FRIA", "a cadeira do que se escondia não está fria")
	for seat: GodSeat in hall.seats:
		seat.interact(hero)
		main.menu.close()
		_check(not seat.can_interact(hero), "a brasa não apagou")
	_check(hall.seats_left() == 0 and last.prompt() == "SENTAR", "a última cadeira não liberou")
	# sentar revela; o desfecho só vem depois de apagar a brasa da Vigia
	last.interact(hero)
	await _frames(3)
	_check(main.cutscene.is_open() and not Meta.awake() and get_tree().paused, "sentar não mostrou a virada")
	for i in Story.REVEAL.size() * 2:
		main.cutscene.advance()
	await _frames(3)
	_check(not get_tree().paused and main.level == hall and not last.can_interact(hero), "a virada não devolveu o jogo")
	_check(cold.last_ember and cold.can_interact(hero) and cold.prompt() == "APAGAR A BRASA", "a brasa da Vigia não acendeu")
	_check(not Run.saved().is_empty(), "o save sumiu antes do fim")
	cold.interact(hero)
	await _frames(3)
	_check(main.cutscene.is_open() and Meta.awake() and Run.saved().is_empty(), "apagar a última brasa não deu o desfecho")
	for i in Story.FINAL.size() * 2:
		main.cutscene.advance()
	_check(main.screen.mode == "victory" and main.screen.to_title, "o desfecho não fechou na vitória")
	_check(Meta.has_skin(Catalog.skin("desperto")), "a aparência não liberou")
	_check(main.brazier_options().any(func(o: Dictionary) -> bool: return int(o["plus"]) == 1), "o braseiro não oferece o Novo Jogo+")

	# Novo Jogo+: herói e inimigos mais fortes, e o ciclo fica salvo
	Run.new_run(9, 0, 0)
	var hp0 := Run.enemy_hp_mult()
	Run.new_run(9, 0, 2)
	_check(is_equal_approx(Run.enemy_hp_mult(), hp0 * 1.5), "vida do ciclo errada")
	Run.new_run(9, 4, 2)
	Run.suspend()
	var snap := Run.saved()
	Run.new_run(1, 0)
	Run.restore(snap)
	_check(Run.plus == 2 and Run.heat == 4, "o ciclo não voltou do save")
	main._load_stage()
	await _frames(3)
	var p: Player = main.level.player
	_check(p.levels["furia"] == 1 and p.levels["vigor"] == 1 and p.weapons[0].tier == 1, "o herói não começou mais forte")
	var before := p.essence
	p.add_essence(10)
	_check(p.essence - before == 15, "a essência do ciclo não rendeu")
	Run.discard_saved()
	Meta.record_plus_win(2)
	_check(int(Meta.data["plus"]) == 3, "vencer o ciclo não liberou o próximo")
	main.queue_free()
	await _frames(2)
	Run.new_run(1, 0)
	Meta.use_path("user://teste.save", true)


func _heat() -> void:
	Run.heat = 2
	await _load(FLAT)
	var p := level.player
	var e := level.spawn("grunt", p.global_position + Vector2(200, 0))
	await _frames(2)
	_check(e.max_hp == roundi(60 * 1.8), "vida do penitente %d" % e.max_hp)
	var before := p.hp
	p.hurt(Damage.make(10, 1, 0))
	_check(before - p.hp == 15, "dano recebido %d (esperado 15)" % (before - p.hp))
	Run.heat = 0


func _merchant() -> void:
	await _load(FLAT)
	var p := level.player
	p.gold = 999
	var menu := Menu.new()
	add_child(menu)
	var m := Merchant.new()
	m.level = level
	m.position = p.global_position + Vector2(10, 0)
	level.add_child(m)
	m.interact(p)
	var cost: int = m.stock()[0]["cost"]
	menu.choose(0)
	await _frames(2)
	_check(p.gold == 999 - cost, "ouro %d" % p.gold)
	_check(level.get_children().any(func(n: Node) -> bool: return n is Pickup), "a compra não apareceu no chão")
	menu.close()
	menu.queue_free()


func _new_enemies() -> void:
	for path in ["res://scripts/enemies/smith.gd", "res://scripts/enemies/slag.gd",
			"res://scripts/enemies/wolf.gd", "res://scripts/enemies/ice_sentinel.gd"]:
		await _load(WIDE)
		var p := level.player
		p.max_hp = 9999
		p.hp = 9999
		var e := level.spawn_script(path, p.global_position + Vector2(70, 0))
		e.facing = -1
		for i in 360:
			await get_tree().physics_frame
			if p.hp < p.max_hp:
				break
		_check(p.hp < p.max_hp, "%s não acertou o herói" % path.get_file())
		e.hurt(Damage.make(99999, 1, 0))
		await _frames(2)
		_check(not is_instance_valid(e) or not e.alive(), "%s não morreu" % path.get_file())


func _hazards() -> void:
	for path in ["res://scripts/enemies/fire_vent.gd", "res://scripts/enemies/icicle.gd"]:
		await _load(FLAT)
		var p := level.player
		p.max_hp = 9999
		p.hp = 9999
		var hz: Node2D = load(path).new()
		hz.set("room", level.room)
		hz.set("player", p)
		hz.position = p.global_position
		level.add_child(hz)
		for i in 300:
			await get_tree().physics_frame
			p.velocity = Vector2.ZERO
			if p.hp < p.max_hp:
				break
		_check(p.hp < p.max_hp, "%s não machucou quem ficou parado" % path.get_file())


func _beira() -> void:
	Meta.use_path("user://teste.save", true)
	Meta.data["intro_seen"] = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await _frames(5)

	# do título, COMEÇAR leva à Beira, e nela não há partida nem relógio
	var ids: Array = main.screen._options.map(func(o: Array) -> String: return String(o[0]))
	_check(not ids.has("skins") and not ids.has("plus"), "o título ainda tem o que mora na Beira: %s" % [ids])
	main.screen.pick("start")
	await _frames(5)
	_check(Run.stage_id == Run.BEIRA and main.level.kind == "beira", "COMEÇAR não levou à Beira: " + Run.stage_id)
	_check(not Run.active and Run.path.is_empty() and Run.saved().is_empty(), "a Beira contou como partida")
	await _frames(30)
	_check(is_zero_approx(Run.time), "o relógio correu na Beira: %f" % Run.time)
	_check(main.level.get_children().filter(func(n: Node) -> bool: return n is Enemy).is_empty(), "tem inimigo na Beira")

	# as cinco estações, a Vigia e o arco estão de pé e cada menu abre
	var stations: Array = main.level.get_children().filter(func(n: Node) -> bool: return n is Station)
	_check(stations.size() == 5, "estações: %d" % stations.size())
	var hero: Player = main.level.player
	for s: Station in stations:
		_check(s.prompt() != "" and s.detail() != "", "estação sem texto: " + s.kind)
		s.interact(hero)
		await _frames(2)
		_check(main.menu.is_open(), "o menu não abriu: " + s.kind)
		main.menu.close()
		await _frames(2)
	var vigia: Keeper = main.level.get_children().filter(func(n: Node) -> bool: return n is Keeper)[0]
	vigia.interact(hero)
	await _frames(2)
	_check(main.menu.is_open(), "a Vigia não falou")
	main.menu.close()
	await _frames(2)

	# cada coisa se alcança a pé, sem pular: esse é o caminho de toda partida
	for s: Station in stations:
		hero.global_position.x = s.global_position.x - s.reach + 8.0
		await _frames(1)
		_check(hero.nearest_interactable() == s, "não dá para usar: " + s.kind)
	hero.global_position.x = main.level.room.player_spawn.x

	# trancado não se escolhe; conquista destranca, e vale para quem já tinha jogado
	_check(not Meta.has_advantage("lamina_afiada"), "vantagem veio aberta")
	_check(Meta.has_advantage("saco_moedas"), "vantagem básica trancada")
	_check(Meta.start_mutations().size() == 3 and not Meta.start_mutations().has("frieza"), "poço: %s" % [Meta.start_mutations()])
	Meta.note_mutation("frieza")
	_check(Meta.start_mutations().has("frieza"), "o poço não lembrou da mutação")
	Meta.data["stats"]["kills_by"] = {"O LOBO DA LONGA NOITE": 1}
	Meta.data["deaths"] = 1
	var fresh := Meta.check_feats()
	_check(fresh.size() == 2 and Meta.check_feats().is_empty(), "conquistas novas: %d" % fresh.size())
	_check(Meta.has_advantage("lamina_afiada"), "a conquista não liberou a vantagem")
	_check(Catalog.GUARDIANS.size() == 13, "guardiões: %d" % Catalog.GUARDIANS.size())
	for a: Dictionary in Catalog.ADVANTAGES:
		_check(not a.has("needs") or not Catalog.feat(a["needs"]).is_empty(), "vantagem presa a conquista que não existe: " + String(a["id"]))
	Lang.use("en")
	for f: Dictionary in Catalog.FEATS + Catalog.ADVANTAGES:
		for k in ["title", "detail"]:
			var t := String(f[k]).to_upper()
			_check(Lang.t(t) != t, "sem inglês: " + t)
	for line: String in Story.BEIRA_LINES:
		_check(Lang.t(line) != line, "sem inglês: " + line)
	Lang.use("pt")

	# escolhe e anda até o arco de verdade: a partida começa ao passar, sem botão
	Run.advantage = "lamina_afiada"
	Run.start_mutation = "frieza"
	Meta.pick("pick_advantage", "lamina_afiada")
	Meta.pick("pick_mutation", "frieza")
	var walker := ScriptedInput.new()
	hero.pad = walker
	walker.then(["right"], 900)
	for i in 900:
		await get_tree().physics_frame
		if Run.stage_id != Run.BEIRA:
			break
	walker.clear()
	_check(Run.stage_id == Run.FIRST, "andar até o arco não atravessou")
	await _frames(5)
	_check(Run.stage_id == Run.FIRST and main.level.kind == "gerada", "o mapa sorteado não veio: " + Run.stage_id)
	_check(Run.active and Run.path == [Run.FIRST], "a contagem não começou")
	await _frames(30)
	_check(Run.time > 0.0, "o relógio não correu depois do arco")
	_check(not Run.saved().is_empty(), "a partida não foi salva")
	hero = main.level.player
	_check(hero.has_mutation("frieza"), "a mutação do poço não veio")
	_check(hero.weapons[0].tier == 1, "a vantagem da carroça não veio")

	# morreu: renasce na Beira, com as escolhas de pé
	main._on_player_died()
	_check(main.screen.mode == "death" and Run.saved().is_empty(), "não contou a morte")
	main._on_screen_confirmed()
	await _frames(5)
	_check(Run.stage_id == Run.BEIRA and main.level.kind == "beira", "não renasceu na Beira: " + Run.stage_id)
	_check(Run.advantage == "lamina_afiada" and Run.start_mutation == "frieza", "as escolhas sumiram")
	_check(is_zero_approx(Run.time), "o relógio da partida anterior ficou")

	# desafio do dia é igual para todos: direto, sem o que se escolhe na Beira
	Run.new_daily()
	_check(Run.advantage == "" and Run.start_mutation == "", "o desafio do dia levou as escolhas")

	main.free()
	Run.active = false
	Meta.use_path("user://teste.save", true)
	await _frames(2)


func _waves() -> void:
	Meta.use_path("user://teste.save", true)
	Meta.data["intro_seen"] = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await _frames(5)
	var ids: Array = main.screen._options.map(func(o: Array) -> String: return String(o[0]))
	_check(ids.has("modes"), "o título não tem MODOS: %s" % [ids])
	main.open_modes()
	await _frames(2)
	_check(main.menu.is_open(), "MODOS não abriu")
	main.menu.close()
	await _frames(2)
	main._on_title_option("waves")
	await _frames(5)
	_check(Run.mode == Run.WAVES and main.level.kind == "ondas", "o Modo Waves não abriu: " + main.level.kind)
	# a arena inteira cabe na tela: nada para a câmera percorrer
	var view: Vector2 = main.get_viewport().get_visible_rect().size
	var arena: Vector2 = main.level.room.size_px()
	_check(arena.x <= view.x and arena.y <= view.y + Room.TILE, "a arena não cabe na tela: %s em %s" % [arena, view])
	var hero: Player = main.level.player
	hero.max_hp = 999999
	hero.hp = 999999
	var flasks_start := hero.flasks
	_check(flasks_start == 0, "o herói já começou com frasco: %d" % flasks_start)

	# uma wave de cada vez até a 9, e o frasco só nas múltiplas de 5
	var d: WaveDirector = main.level.director
	for target in range(1, 10):
		await _next_wave(d, target)
		_check(Run.wave == target and d.state == "fight", "não chegou à wave %d: %d %s" % [target, Run.wave, d.state])
		_check(not d.is_guardian_wave(target), "guardião fora de hora na wave %d" % target)
		await _clear_field(d)
		_check(d.state == "wait", "a wave %d não terminou" % target)
		var want := 2 if target >= 5 else 0
		_check(hero.flasks == want, "wave %d: %d usos de frasco, esperava %d" % [target, hero.flasks, want])

	# cada frasco serve duas vezes, e não mais
	hero.hp = 500
	hero._start_heal()
	_check(hero.flasks == 1, "o primeiro gole gastou errado")
	await _frames(45)
	_check(hero.pad != null and hero.hp > 500, "o frasco não curou")
	hero._start_heal()
	await _frames(45)
	_check(hero.flasks == 0, "o frasco serviu mais de duas vezes")

	# na wave 10, o guardião
	await _next_wave(d, 10)
	_check(d.state == "guardian" and is_instance_valid(main.level.boss), "o guardião não veio na wave 10")
	_check(main.hud.boss == main.level.boss, "o HUD não mostra o guardião")
	var guardian: Enemy = main.level.boss
	await _frames(5)
	guardian._die()
	await _frames(5)
	_check(d.state == "stop", "vencer o guardião não abriu a parada")
	_check(hero.flasks == 2, "a wave 10 não deu frasco: %d" % hero.flasks)
	var kinds: Array = main.level.get_children().map(func(n: Node) -> String: return n.get_class() if n.get_script() == null else String((n.get_script() as Script).get_global_name()))
	for k in ["Keeper", "Merchant", "MutationAltar", "ExitGate"]:
		_check(kinds.has(k), "falta na parada: " + k)

	# nada na parada enche frasco nem vende frasco
	var keeper: Keeper = main.level.get_children().filter(func(n: Node) -> bool: return n is Keeper)[0]
	hero.flasks = 0
	keeper.interact(hero)
	await _frames(2)
	_check(hero.flasks == 0, "a Vigia encheu o frasco no Modo Waves")
	main.menu.close()
	await _frames(2)
	var shop: Merchant = main.level.get_children().filter(func(n: Node) -> bool: return n is Merchant)[0]
	_check(not shop.stock().any(func(o: Dictionary) -> bool: return o["kind"] == "flask" or o["kind"] == "heal"), "o mercador vende cura no Modo Waves")
	hero.flasks = 3

	# a porta leva ao domínio seguinte, com o que o herói tinha, e a contagem continua
	var before: String = main.level.biome.id
	main._on_exit("ondas")
	await _frames(5)
	_check(Run.wave_block == 1 and main.level.kind == "ondas", "não passou de bloco")
	_check(main.level.biome.id != before, "o domínio não mudou")
	_check(Run.WAVE_ROUTE[1].has(main.level.biome.id), "domínio fora da ordem: " + main.level.biome.id)
	_check(main.level.player.flasks == 3, "os frascos não passaram: %d" % main.level.player.flasks)
	await _next_wave(main.level.director, 11)
	_check(Run.wave == 11, "a contagem não continuou: %d" % Run.wave)
	var hp_now := Run.enemy_hp_mult()
	_check(hp_now > 1.4, "os inimigos não cresceram: %f" % hp_now)

	# salvar e continuar volta ao começo do bloco, no mesmo domínio
	var biome_now: String = main.level.biome.id
	var saved: Dictionary = Run.saved()
	_check(not saved.is_empty() and saved["mode"] == Run.WAVES, "a partida não foi salva")
	main._show_title()
	await _frames(2)
	main.continue_run()
	await _frames(5)
	_check(Run.mode == Run.WAVES and Run.wave_block == 1 and Run.wave == 10, "continuar errou: %d %d" % [Run.wave_block, Run.wave])
	_check(main.level.biome.id == biome_now, "continuar mudou o domínio")

	# morrer guarda o recorde e volta à Beira
	Run.wave = 14
	main.level.player.hp = 0
	main._on_player_died()
	_check(int(Meta.data["best_wave"]) == 14, "o recorde não ficou: %d" % int(Meta.data["best_wave"]))
	_check(main.screen.mode == "death" and Run.saved().is_empty(), "a morte não contou")
	main._on_screen_confirmed()
	await _frames(5)
	_check(Run.stage_id == Run.BEIRA and Run.mode == "", "não voltou à Beira depois das waves")
	_check(Meta.check_feats() != null, "conquistas quebraram")

	main.free()
	Run.active = false
	Meta.use_path("user://teste.save", true)
	await _frames(2)


func _next_wave(d: WaveDirector, target: int) -> void:
	for i in 900:
		if Run.wave == target:
			return
		d._clock = minf(d._clock, 0.0)
		await get_tree().physics_frame


func _clear_field(d: WaveDirector) -> void:
	for i in 3000:
		if d.state != "fight":
			return
		d._spawn_clock = 0.0
		for e in d._field:
			if is_instance_valid(e) and e.alive():
				e._die()
		await get_tree().physics_frame


# Arena menor que a de chefe e com inimigos de todos os domínios: ninguém pode quebrar,
# escapar da sala ou travar a wave.
func _waves_cast() -> void:
	Meta.use_path("user://teste.save", true)
	Run.new_waves()
	var bounds := Rect2(Vector2(-64, -96), Vector2(480 + 128, 272 + 192))
	var scripts := {}
	for group: Array in Run.WAVE_ROUTE:
		for id: String in group:
			var b := Catalog.biome(id)
			_check(b != null and b.boss_script != "", "domínio sem guardião: " + id)
			var lv := Level.new()
			add_child(lv)
			lv.build_waves(b, 7, 0, false)
			lv.director.set_physics_process(false)
			lv.player.max_hp = 999999
			lv.player.hp = 999999
			lv.player.set_physics_process(false)
			lv.spawn_guardian()
			await _frames(150)
			_check(is_instance_valid(lv.boss) and lv.boss.alive(), "%s sumiu na arena" % b.boss_script)
			if is_instance_valid(lv.boss):
				_check(bounds.has_point(lv.boss.global_position), "%s saiu da arena: %s" % [b.boss_script, lv.boss.global_position])
				lv.boss._die()
			await _frames(3)
			for e: Dictionary in b.enemies:
				scripts[e["script"]] = true
			lv.queue_free()
			await _frames(2)

	# todo inimigo comum, no pior caso: junto com os outros, e a rede de segurança limpa a wave
	var b := Catalog.biome("mar_de_cinzas")
	var lv := Level.new()
	add_child(lv)
	lv.build_waves(b, 7, 0, false)
	lv.player.max_hp = 999999
	lv.player.hp = 999999
	lv.player.set_physics_process(false)
	var d := lv.director
	d.set_physics_process(false)
	d._field.clear()
	var at := 0
	for path: String in scripts:
		var e := lv.spawn_script(path, d._spots[at % d._spots.size()])
		d._field.append(e)
		at += 7
	await _frames(120)
	_check(d._field.size() == scripts.size(), "faltam inimigos na arena")
	d.state = "fight"
	Run.wave = 1
	d.fight_time = WaveDirector.STALL + 1.0
	d.set_physics_process(true)
	for i in 900:
		if d.state != "fight":
			break
		await get_tree().physics_frame
	_check(d.state == "wait", "a rede de segurança não destravou a wave: %d restam" % d._field.size())
	lv.queue_free()
	Run.mode = ""
	Run.wave = 0
	Run.active = false
	await _frames(2)


func _weekly() -> void:
	Meta.use_path("user://teste.save", true)
	# a mesma semana dá as mesmas regras; nunca um par proibido
	_check(Run.week_rules("S3000") == Run.week_rules("S3000"), "a regra da semana muda sozinha")
	var seen := {}
	for n in 400:
		var pair := Run.week_rules("S%d" % n)
		_check(pair.size() == 2 and pair[0] != pair[1], "regras repetidas: %s" % [pair])
		_check(not Run.RULE_CLASHES.any(func(c: Array) -> bool: return c.has(pair[0]) and c.has(pair[1])), "par proibido: %s" % [pair])
		seen[pair[0]] = true
		seen[pair[1]] = true
	_check(seen.size() == Run.RULES.size(), "alguma regra nunca sai: %d" % seen.size())
	Lang.use("en")
	for r: Dictionary in Run.RULES + [{"title": "Modo Waves", "detail": "ARENA FECHADA. FRASCO A CADA 5 WAVES, GUARDIÃO A CADA 10"}]:
		for k in ["title", "detail"]:
			var t := String(r[k]).to_upper()
			_check(Lang.t(t) != t or t == "ARSENAL", "sem inglês: " + t)    # Arsenal se escreve igual
	Lang.use("pt")

	# o desafio é da semana inteira: mesma semente até virar
	Run.new_weekly()
	var seed_one := Run.seed_value
	_check(Run.week == Run.this_week() and Run.rules.size() == 2, "o desafio da semana não começou")
	Run.new_weekly()
	_check(Run.seed_value == seed_one, "a semente da semana mudou")

	# cada regra faz o que diz
	var base_hp := 1.0
	var effect := func(rules: Array) -> void:
		Run.new_run(5)
		Run.rules = rules
	effect.call(["vidro"])
	_check(is_equal_approx(Run.hero_damage_mult(), 2.0) and is_equal_approx(Run.enemy_damage_mult(), 2.0), "vidro")
	effect.call(["brasa"])
	_check(is_equal_approx(Run.hero_damage_mult(), 1.3), "brasa")
	effect.call(["cacada"])
	_check(is_equal_approx(Run.plus_elite_chance(), 0.25), "caçada")
	effect.call(["horda"])
	_check(is_equal_approx(Run.enemy_hp_mult(), 0.6 * base_hp), "horda")
	effect.call(["fortuna"])
	_check(is_equal_approx(Run.enemy_hp_mult(), 1.3), "fortuna")
	effect.call(["lua"])
	_check(is_equal_approx(Run.gravity_mult(), 0.6), "lua")
	effect.call(["vampiro"])
	_check(is_equal_approx(Run.flask_heal_mult(), 0.5), "vampiro")

	var lv := Level.new()
	add_child(lv)
	effect.call(["seca"])
	lv.build(FLAT, false)
	Run.load_player(lv.player)
	_check(lv.player.flasks == 0 and lv.player.max_hp == Player.BASE_HP * 2, "seca: %d frascos, %d vida" % [lv.player.flasks, lv.player.max_hp])
	_check(not Run.flasks_for_sale(), "seca vende frasco")
	lv.queue_free()
	await _frames(1)

	lv = Level.new()
	add_child(lv)
	effect.call(["mutante", "arsenal"])
	lv.build(FLAT, false)
	Run.load_player(lv.player)
	_check(lv.player.mutations.size() == Catalog.MAX_MUTATIONS, "mutante: %d" % lv.player.mutations.size())
	_check(lv.player.weapons[0].data != lv.player.weapons[1].data, "arsenal deu a mesma arma")
	var first_pick: Array = [lv.player.weapons[0].data.id, lv.player.mutations.duplicate()]
	lv.queue_free()
	await _frames(1)
	lv = Level.new()
	add_child(lv)
	effect.call(["mutante", "arsenal"])
	lv.build(FLAT, false)
	Run.load_player(lv.player)
	_check(first_pick == [lv.player.weapons[0].data.id, lv.player.mutations], "o sorteio da regra muda entre jogadores")

	# golpe que passa por vários não acumula o bônus
	Run.rules = ["vidro"]
	var e := lv.spawn("grunt", Vector2(100, 100))
	await _frames(2)
	var hit := Damage.make(10.0)
	var hp_before := e.hp
	e.hurt(hit)
	_check(hp_before - e.hp == 20 and hit.value() == 10, "vidro acumulou no pacote: %d" % (hp_before - e.hp))
	lv.queue_free()
	await _frames(1)

	# salvar e continuar mantém as regras, e o recorde da semana fica separado
	Run.new_weekly()
	var kept := Run.rules.duplicate()
	var s := Run.snapshot()
	Run.new_run(1)
	Run.restore(s)
	_check(Run.rules == kept and Run.week == Run.this_week(), "continuar perdeu as regras")
	Meta.record_stats(false)
	_check(int(Meta.data["weekly"][Run.week]["tries"]) == 1, "tentativa da semana não contou")
	Run.new_run(1)
	Run.active = false
	Meta.use_path("user://teste.save", true)


func _options() -> void:
	Meta.use_path("user://teste.save", true)
	Options.reload()
	var screen := OptionsScreen.new()
	add_child(screen)
	screen.change("music", -10)
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "música não ficou muda no 0%")
	screen.change("shake", -10)
	Fx.shake = 0.0
	Fx.add_shake(8.0)
	_check(Fx.shake == 0.0, "tremor com 0%%: %.1f" % Fx.shake)
	Options.set_value("keys", {"jump": [KEY_W]})
	var keys: Array = InputMap.action_get_events("jump").filter(func(e: InputEvent) -> bool: return e is InputEventKey)
	_check(keys.size() == 1 and keys[0].physical_keycode == KEY_W, "pular não virou W")
	Meta.use_path("user://teste.save", true)
	Options.reload()
	_check(Controls.key_name("jump") == "SPACE", "a tecla padrão não voltou (%s)" % Controls.key_name("jump"))
	screen.queue_free()


func _new_skills() -> void:
	for id in ["armadilha_laminas", "torreta_vidro", "espirito_cinza", "corrente_ferreiro",
			"sino_carcosa", "raiz_viva", "estrela_cadente"]:
		await _load(WIDE)
		var p := level.player
		p.skills[0] = Gear.of(Catalog.find(id))
		var dist := 14.0 if id == "armadilha_laminas" else (40.0 if id == "sino_carcosa" else 90.0)
		var e := _calm(level.spawn("grunt", p.global_position + Vector2(dist, 0)))
		e.set_physics_process(true)
		e.set_process(false)
		var start_x := e.global_position.x
		input.then(["skill1"], 2).wait(5)
		for i in 240:
			await get_tree().physics_frame
			if is_instance_valid(e):
				e.velocity.x = 0.0 if id != "corrente_ferreiro" else e.velocity.x
				e.state = "idle"
			if not is_instance_valid(e) or e.hp < e.max_hp:
				break
		_check(not is_instance_valid(e) or e.hp < e.max_hp, "%s não machucou" % id)
		if id == "corrente_ferreiro" and is_instance_valid(e):
			await _frames(20)
			_check(e.global_position.x < start_x - 10.0, "a corrente não puxou (%.0f -> %.0f)" % [start_x, e.global_position.x])


func _affixes() -> void:
	await _load(FLAT)
	var p := level.player
	var plain := Gear.of(Catalog.find("espada_cerimonial"))
	var sharp := Gear.of(Catalog.find("espada_cerimonial"))
	sharp.affixes.assign(["afiada", "vampira"])
	_check(sharp.title().contains("Afiada"), "nome sem o afixo: " + sharp.title())
	var dummy := _calm(level.spawn("grunt", p.global_position + Vector2(300, 0)))
	var a := Damage.make(20, 1, 0)
	p._affix_before(plain, a, dummy)
	var b := Damage.make(20, 1, 0)
	p._affix_before(sharp, b, dummy)
	_check(is_equal_approx(b.amount, a.amount * 1.15), "afiada: %.1f vs %.1f" % [b.amount, a.amount])
	p.hp = 50
	p._affix_after(sharp, b, dummy)
	_check(p.hp == 51, "vampira não curou (%d)" % p.hp)


func _bosses() -> void:
	for path in ["boss_wolf_king", "boss_colossus", "boss_architect", "boss_mother_root",
			"boss_faceless_king", "boss_astronomer", "blind_emperor", "boss_forgotten", "boss_answer",
			"boss_insatiable", "boss_dragon", "boss_wyrm", "boss_fox"]:
		if level:
			remove_child(level)
			level.queue_free()
		level = Level.new()
		level.rng.seed = 1
		add_child(level)
		level.build(FileAccess.get_file_as_string("res://content/arena.txt").replace("B", "."), false)
		var p := level.player
		p.max_hp = 99999
		p.hp = 99999
		p.pad = ScriptedInput.new()
		var boss: Enemy = level.spawn_script("res://scripts/enemies/%s.gd" % path, p.global_position + Vector2(130, 0))
		boss.set("arena", Rect2(Vector2(16, 0), level.room.size_px() - Vector2(32, 0)))
		var hit_at := -1
		for i in 900:
			await get_tree().physics_frame
			if p.hp < p.max_hp:
				hit_at = i
				break
		_check(hit_at >= 0, "%s ficou 15 s sem acertar o herói" % path)
		# sem ajudantes e fora do golpe próprio (invisível não apanha; com os mortos de pé, quase não sente)
		for e in level.enemies():
			if e != boss:
				e.queue_free()
		await _frames(2)
		if boss is Boss:
			boss.custom_abort()
			boss.set_state("idle")
		var hp0: int = boss.hp
		boss.hurt(Damage.make(boss.max_hp * 0.55, 1, 0))
		await _frames(60)
		_check(boss.hp < hp0, "%s não apanhou" % path)
		if boss.get("phase") != null:
			_check(boss.get("phase") == 2, "%s não entrou na fase 2" % path)
		for e in level.enemies():
			e.queue_free()
		await _frames(2)


func _domain_enemies() -> void:
	for name in ["scribe", "gargoyle", "thorn_plant", "moss_beast", "masked", "herald", "automaton", "fallen_star",
			"mason", "seed_pod", "dancer", "lens", "mourner", "risen", "grave_cat", "drowned", "votive", "prayer",
			"maw_tentacle", "larva", "parasite", "nightmare", "incubus", "sleepwalker", "blind_lizard", "crevice_snake",
			"digger", "highwayman", "wanderer", "frogman", "elite_caller", "elite_priestess", "elite_glutton",
			"elite_reverie", "elite_hermit", "elite_bull"]:
		await _load(WIDE)
		var p := level.player
		p.max_hp = 9999
		p.hp = 9999
		var e := level.spawn_script("res://scripts/enemies/%s.gd" % name, p.global_position + Vector2(90, 0))
		e.facing = -1
		for i in 480:
			await get_tree().physics_frame
			if p.hp < p.max_hp:
				break
		_check(p.hp < p.max_hp, "%s não acertou o herói" % name)


# A física de verdade, não o verificador: pilha de plataformas de 3 em 3 blocos
# (como as escadas das salas), um pulo por degrau, sem gastar o pulo duplo.
const STACK := """
##########
#........#
#........#
####..####
####..####
#........#
#...==...#
#........#
#........#
#...==...#
#........#
#........#
#...==...#
#........#
#...P....#
##########
"""


func _climb_stack() -> void:
	await _load(STACK)
	var p := level.player
	p.global_position.x = 4.5 * Room.TILE + 4.0
	for i in 3:
		await get_tree().physics_frame
	var rows := [12, 9, 6]
	for top: int in rows:
		input.clear().then(["jump"], 30).wait(14)
		for i in 44:
			await get_tree().physics_frame
		_check(p.is_on_floor(), "não pousou no degrau da linha %d" % top)
		_check(absf(p.global_position.y - top * Room.TILE) < 2.0, "não chegou na linha %d (y = %.1f)" % [top, p.global_position.y])
	# do último degrau, um pulo só passa pelo vão de 2 blocos e pousa na sala de cima
	input.clear().then(["jump"], 8).then(["jump", "right"], 22).then(["right"], 10)
	for i in 60:
		await get_tree().physics_frame
	_check(p.is_on_floor() and absf(p.global_position.y - 3 * Room.TILE) < 2.0, "não saiu pelo vão do teto (y = %.1f)" % p.global_position.y)


func _hit_enemy(e: Enemy, amount: float) -> void:
	var d := Damage.make(amount, 1, 0.0)
	e.hurt(d)


func _new_behaviors() -> void:
	# Morto Desperto: a primeira morte não conta
	await _load(WIDE)
	var p := level.player
	p.max_hp = 9999
	p.hp = 9999
	var risen := level.spawn_script("res://scripts/enemies/risen.gd", p.global_position + Vector2(60, 0))
	for i in 3:
		await get_tree().physics_frame
	risen.ghost = false
	_hit_enemy(risen, 9999.0)
	_check(is_instance_valid(risen) and risen.alive() and risen.hp > 0, "o morto não levantou")
	risen.ghost = false
	_hit_enemy(risen, 9999.0)
	await get_tree().physics_frame
	_check(not is_instance_valid(risen) or not risen.alive(), "o morto não morreu na segunda vez")

	# Larva: vira duas pequenas, e as pequenas não se dividem
	await _load(WIDE)
	p = level.player
	var larva := level.spawn_script("res://scripts/enemies/larva.gd", p.global_position + Vector2(100, 0))
	for i in 3:
		await get_tree().physics_frame
	_hit_enemy(larva, 9999.0)
	for i in 3:
		await get_tree().physics_frame
	var kids := get_tree().get_nodes_in_group("larvas").filter(func(n: Node) -> bool: return is_instance_valid(n) and not n.is_queued_for_deletion())
	_check(kids.size() == 2, "a larva virou %d" % kids.size())
	for k in kids:
		_hit_enemy(k, 9999.0)
	for i in 3:
		await get_tree().physics_frame
	kids = get_tree().get_nodes_in_group("larvas").filter(func(n: Node) -> bool: return is_instance_valid(n) and not n.is_queued_for_deletion())
	_check(kids.is_empty(), "larva pequena se dividiu")

	# Parasita: gruda e rolar solta
	await _load(WIDE)
	p = level.player
	p.max_hp = 9999
	p.hp = 9999
	var par := level.spawn_script("res://scripts/enemies/parasite.gd", p.global_position + Vector2(70, 0))
	par.facing = -1
	var stuck := false
	for i in 300:
		await get_tree().physics_frame
		if par.state == "latched":
			stuck = true
			break
	_check(stuck, "a parasita não grudou")
	for i in 30:
		await get_tree().physics_frame
	_check(par.state == "latched", "a parasita soltou sozinha")
	input.then(["roll"], 3)
	for i in 30:
		await get_tree().physics_frame
	_check(par.state != "latched", "rolar não soltou a parasita")
	input.clear()

	# Salteador: leva ouro, e matar devolve
	await _load(WIDE)
	p = level.player
	p.max_hp = 9999
	p.hp = 9999
	p.gold = 100
	var thief := level.spawn_script("res://scripts/enemies/highwayman.gd", p.global_position + Vector2(90, 0))
	thief.facing = -1
	for i in 480:
		await get_tree().physics_frame
		if p.gold < 100:
			break
	_check(p.gold < 100, "o salteador não roubou")
	_check(thief.state == "flee", "o salteador não fugiu")
	_hit_enemy(thief, 9999.0)
	_check(p.gold == 100, "o ouro não voltou (%d)" % p.gold)

	# Lagarto Cego: quem fica parado longe não existe
	await _load(WIDE)
	p = level.player
	var liz := level.spawn_script("res://scripts/enemies/blind_lizard.gd", p.global_position + Vector2(120, 0))
	liz.set_state("chase")
	for i in 90:
		await get_tree().physics_frame
		if liz.state == "idle":
			break
	_check(liz.state == "idle", "o lagarto cego viu quem estava parado")


func _boss_mechanics() -> void:
	for name in ["boss_forgotten", "boss_answer", "boss_insatiable", "boss_dragon", "boss_wyrm", "boss_fox"]:
		await _load(WIDE)
		var p := level.player
		p.max_hp = 9999
		p.hp = 9999
		var b: Boss = level.spawn_script("res://scripts/enemies/%s.gd" % name, p.global_position + Vector2(120, 0))
		b.set_state("idle")
		var custom := {}
		for m: Dictionary in b.moves:
			if m["type"] == "custom":
				custom = m
		if not custom.is_empty():
			b._move = custom
			b.set_state("windup")
			var acted := false
			for i in 600:
				await get_tree().physics_frame
				if b.state == "act":
					acted = true
				if acted and b.state != "act" and b.state != "windup":
					break
			_check(acted and b.state != "act", "%s ficou preso no golpe próprio (%s)" % [name, b.state])
			_check(b._alpha >= 0.99, "%s terminou invisível" % name)
			_check(not b.ghost, "%s terminou intocável" % name)
			_check(b.uses_gravity, "%s terminou sem gravidade" % name)
			_check(p.inhale == 0.0, "%s não soltou o herói" % name)
	# Rei Esquecido: com mortos de pé, quase não sente
	await _load(WIDE)
	var pl := level.player
	var king: Boss = level.spawn_script("res://scripts/enemies/boss_forgotten.gd", pl.global_position + Vector2(160, 0))
	king.set_state("idle")
	var hp0 := king.hp
	_hit_enemy(king, 100.0)
	var alone := hp0 - king.hp
	level.spawn_script("res://scripts/enemies/mourner.gd", pl.global_position + Vector2(-80, -30))
	hp0 = king.hp
	_hit_enemy(king, 100.0)
	_check(hp0 - king.hp < alone, "os mortos não protegeram o rei")
	# O Que Responde: depois de 6 golpes, a resposta
	await _load(WIDE)
	pl = level.player
	var ans: Boss = level.spawn_script("res://scripts/enemies/boss_answer.gd", pl.global_position + Vector2(160, 0))
	ans.set_state("idle")
	for i in 6:
		_hit_enemy(ans, 1.0)
	await get_tree().physics_frame
	_check(ans.state == "windup" and ans._move.get("radial", false), "ele não respondeu")


func _enemy_bar() -> void:
	await _load(WIDE)
	var p := level.player
	for name in ["boss_wyrm", "maw_tentacle", "grave_cat", "penitent"]:
		var path := "res://scripts/enemies/%s.gd" % name
		if not ResourceLoader.exists(path):
			path = "res://scripts/enemies/grunt.gd"
		var e: Enemy = level.spawn_script(path, p.global_position + Vector2(200, 0))
		await get_tree().physics_frame
		var bar: EnemyBar = null
		for c in e.get_children():
			if c is EnemyBar:
				bar = c
		_check(bar != null, "%s sem barra" % name)
		_check(bar.z_index > e.body.z_index, "a barra de %s fica atrás do sprite" % name)
		_check(bar.get_index() > e.body.get_index(), "a barra de %s é desenhada antes do sprite" % name)
		_check(e.sprite_top() >= 8.0, "altura de %s não medida" % name)
		e.queue_free()


func _extras() -> void:
	Meta.use_path("user://teste.save", true)
	_check(Run.daily_seed("2026-11-03") == Run.daily_seed("2026-11-03"), "semente do dia muda")
	_check(Run.daily_seed("2026-11-03") != Run.daily_seed("2026-11-04"), "dias diferentes, mesma semente")
	Run.new_daily()
	_check(Run.daily == Run.today() and Run.seed_value == Run.daily_seed(Run.today()), "desafio não usou a semente do dia")
	Run.note_kill("PENITENTE", "espada_cerimonial")
	Run.note_kill("PENITENTE", "espada_cerimonial")
	Run.killer = "LOBO PÁLIDO"
	Run.time = 300.0
	Meta.record_stats(false)
	var st: Dictionary = Meta.data["stats"]
	_check(int(st["kills_by"]["PENITENTE"]) == 2, "abates não somaram")
	_check(int(st["deaths_by"]["LOBO PÁLIDO"]) == 1, "quem matou não ficou salvo")
	_check(int(Meta.data["daily"][Run.today()]["tries"]) == 1, "tentativa do dia não contou")
	_check(Meta.record_stats(true), "a primeira vitória não virou recorde")
	Run.time = 400.0
	_check(not Meta.record_stats(true), "vitória mais lenta virou recorde")
	_check(Meta.stats_text().contains("QUEM MAIS TE MATOU"), "tela de estatísticas incompleta")
	Meta.use_path("user://teste.save", true)


func _elites() -> void:
	for name in ["hunter", "forgemaster", "librarian", "thornkeeper", "duelist", "brass"]:
		await _load(WIDE)
		var p := level.player
		p.max_hp = 99999
		p.hp = 99999
		var e := level.spawn_script("res://scripts/enemies/elite_%s.gd" % name, p.global_position + Vector2(100, 0), true)
		_check(e.max_hp > 200, "elite_%s com pouca vida (%d)" % [name, e.max_hp])
		for i in 900:
			await get_tree().physics_frame
			if p.hp < p.max_hp:
				break
		_check(p.hp < p.max_hp, "elite_%s não acertou em 15 s" % name)


func _story() -> void:
	Meta.use_path("user://teste.save", true)
	var scene := Cutscene.new()
	add_child(scene)
	var done := [false]
	scene.play(PackedStringArray(Story.INTRO), func() -> void: done[0] = true)
	for i in Story.INTRO.size() * 2:
		scene.advance()
	_check(done[0] and not scene.is_open(), "a abertura não terminou")
	_check(Story.ending_pages(4).size() > Story.ending_pages(0).size(), "o final das 4 brasas não tem páginas a mais")
	_check(Meta.note_lore("teste de inscrição") and not Meta.note_lore("teste de inscrição"), "inscrição repetida no códice")
	Run.note_kill("LOBO PÁLIDO", "")
	Meta.record_stats(false)
	_check(Meta.known_creatures().has("LOBO PÁLIDO"), "bestiário não registrou")
	var missing: Array = []
	for path in DirAccess.get_files_at("res://scripts/enemies"):
		if not path.ends_with(".gd"):
			continue
		var script: GDScript = load("res://scripts/enemies/" + path)
		if not script.can_instantiate():
			continue
		var e = script.new()
		if e is Enemy and e.title != "INIMIGO" and not Story.BESTIARY.has(e.title):
			missing.append(e.title)
		if e is Node:
			e.free()
	_check(missing.is_empty(), "sem verbete no bestiário: %s" % [missing])
	scene.queue_free()
	Meta.use_path("user://teste.save", true)


func _new_weapons() -> void:
	for id in ["chicote_espinhos", "foice_inverno", "punhos_bronze", "besta_carcosa", "cetro_astronomo",
			"lamina_luto", "cetro_nomes", "espada_rei", "arco_ossos", "tridente_afogado", "clava_votiva", "arco_prece",
			"cutelo_glutao", "garras_parasita", "dentes_ventre", "lamina_devaneio", "arco_sonho", "lanca_pesadelo",
			"picareta_escavador", "sacola_bombas", "punhal_cego", "espada_estrada", "machado_touro", "arco_raposa",
			"bordao_andarilho"]:
		await _load(WIDE)
		var p := level.player
		p.weapons[0] = Gear.of(Catalog.find(id))
		var data: WeaponData = p.weapons[0].data
		var dist := 120.0 if data.category == "bow" else 16.0
		if id == "chicote_espinhos":
			dist = 50.0
		var side := -1.0 if id == "foice_inverno" else 1.0
		var e := _calm(level.spawn("grunt", p.global_position + Vector2(dist * side, 0)))
		input.then(["attack1"], 2).wait(4).then(["attack1"], 2).wait(30)
		for i in 120:
			await get_tree().physics_frame
			if is_instance_valid(e):
				e.state = "idle"
				e.velocity.x = 0.0
			if not is_instance_valid(e) or e.hp < e.max_hp:
				break
		_check(not is_instance_valid(e) or e.hp < e.max_hp, "%s não machucou" % id)


func _new_mutations() -> void:
	# toda arma e habilidade tem ícone em pixel art (32 px e a versão de 16 px)
	for r in Catalog.all_gear():
		_check(GearIcon.of(r) != null and GearIcon.of(r, false) != null, "%s sem ícone" % r.id)
	await _load(FLAT)
	var p := level.player
	p.add_mutation("pele_de_pedra")
	p.hurt(Damage.make(20, 1, 0))
	var stone := p.max_hp - p.hp
	await _load(FLAT)
	p = level.player
	p.hurt(Damage.make(20, 1, 0))
	_check(stone < p.max_hp - p.hp, "pele de pedra não reduziu o dano (%d)" % stone)
	await _load(FLAT)
	p = level.player
	p.add_mutation("luto")
	var hp0 := p.max_hp
	p.on_kill(null)
	_check(p.max_hp == hp0 + 1, "luto não deu vida máxima")
	await _load(FLAT)
	p = level.player
	p.add_mutation("couraca")
	var near := _calm(level.spawn("grunt", p.global_position + Vector2(20, 0)))
	var far := _calm(level.spawn("grunt", p.global_position + Vector2(200, 0)))
	p.hurt(Damage.make(20, 1, 0))
	_check(near.hp < near.max_hp, "a couraça não estourou em quem estava colado")
	_check(far.hp == far.max_hp, "a couraça acertou quem estava longe")

	await _load(FLAT)
	p = level.player
	p.add_mutation("ultimo_folego")
	p.hurt(Damage.make(9999, 1, 0))
	_check(p.hp == 1 and p.alive(), "teimosia não segurou (%d)" % p.hp)
	await _frames(60)
	p.hurt(Damage.make(9999, 1, 0))
	_check(p.hp == 0, "teimosia valeu duas vezes no mesmo andar")

	await _load(FLAT)
	p = level.player
	var shop := Merchant.new()
	var item := {"kind": "heal", "cost": 100}
	_check(shop.price(item, p) == 100, "preço sem mutação mudou")
	p.add_mutation("barganha")
	_check(shop.price(item, p) == 70, "barganha não deu desconto (%d)" % shop.price(item, p))
	shop.free()

	p.add_mutation("passo_ligeiro")
	var wolf := _calm(level.spawn("grunt", p.global_position + Vector2(200, 0)))
	p._dodge = 0.2
	var swing := Damage.make(10, 1, 0)
	swing.source = wolf
	p.hurt(swing)
	_check(p.wolf_step, "esquiva perfeita não carregou o crítico")
	var next := Damage.make(10, 1, 0)
	p.boost(next)
	_check(next.crit and not p.wolf_step, "o crítico do Passo do Lobo não saiu (ou não gastou)")

	p.add_mutation("sede")
	p.skill_cd[0] = 5.0
	var dummy := _calm(level.spawn("grunt", p.global_position + Vector2(300, 0)))
	p.on_kill(dummy)
	_check(p.skill_cd[0] <= 4.05, "sede não adiantou a recarga (%.2f)" % p.skill_cd[0])


func _save_resume() -> void:
	Meta.use_path("user://teste.save", true)
	await _load(FLAT)
	var p := level.player
	Run.new_run(4242, 1)
	var axe := Gear.of(Catalog.find("machado_carrasco"), 2)
	axe.affixes.assign(["vampira", "eco"])
	p.weapons[1] = axe
	p.skills[1] = Gear.of(Catalog.find("sino_carcosa"))
	p.gold = 77
	p.add_mutation("couraca")
	p.levels["vigor"] = 2
	p.blueprints.assign(["foice_inverno"])
	Run.save_player(p)
	Run.go("saloes")
	Run.note_kill("PENITENTE", "machado_carrasco")
	Run.time = 321.0
	Run.suspend()
	Run.new_run(1, 0)
	Meta.use_path("user://teste.save")
	_check(not Run.saved().is_empty(), "a partida não ficou no disco")
	Run.restore(Run.saved())
	_check(Run.stage_id == "saloes" and Run.heat == 1 and Run.seed_value == 4242, "lugar ou semente errados: %s %d" % [Run.stage_id, Run.heat])
	_check(Run.path.size() == 2 and is_equal_approx(Run.time, 321.0), "caminho ou tempo perdidos")
	await _load(FLAT)
	Run.restore(Run.saved())
	var q := level.player
	Run.load_player(q)
	var w: Gear = q.weapons[1]
	_check(w != null and w.data.id == "machado_carrasco" and w.tier == 2 and w.has("eco"), "arma voltou diferente")
	_check(q.skills[1] != null and q.skills[1].data.id == "sino_carcosa", "habilidade não voltou")
	_check(q.gold == 77 and q.has_mutation("couraca") and q.levels["vigor"] == 2, "ouro, mutação ou atributo perdidos")
	_check(q.blueprints.has("foice_inverno"), "planta carregada se perdeu")
	Run.discard_saved()
	Meta.use_path("user://teste.save")
	_check(Run.saved().is_empty(), "desistir não apagou a partida salva")
	Meta.use_path("user://teste.save", true)


func _guide() -> void:
	Meta.use_path("user://teste.save", true)
	await _load(WIDE)
	var p := level.player
	var guide := Guide.new()
	add_child(guide)
	guide.bind(level)
	var e := _calm(level.spawn("grunt", p.global_position + Vector2(120, 0)))
	await _frames(10)
	_check(guide.showing() == "atacar", "a dica de ataque não apareceu (%s)" % guide.showing())
	await _frames(100)
	input.then(["attack1"], 2).wait(10)
	await _frames(6)
	_check(guide.showing() == "atacar", "a dica sumiu sem esmaecer")
	await _frames(30)
	_check(guide.showing() == "", "atacou e a dica não saiu (%s)" % guide.showing())
	_check(guide.seen("atacar"), "a dica não ficou marcada como vista")
	guide.bind(level)
	await _frames(10)
	_check(guide.showing() != "atacar", "a mesma dica voltou")
	Options.set_value("hints", false)
	p.hp = 10
	await _frames(10)
	_check(guide.showing() == "", "com as dicas desligadas ainda mostrou")
	Options.set_value("hints", true)
	e.queue_free()
	guide.queue_free()
	Meta.use_path("user://teste.save", true)
	Options.reload()


func _fluid_moves() -> void:
	var tall := "#".repeat(40) + "
" + ("#" + ".".repeat(38) + "#
").repeat(14) + "#..P" + ".".repeat(35) + "#
" + "#".repeat(40)
	await _load(tall)
	var p := level.player
	input.then(["jump"], 10).then(["right", "roll"], 2).wait(4)
	await _frames(12)
	var y0 := p.global_position.y
	var x0 := p.global_position.x
	await _frames(6)
	_check(p.global_position.x - x0 > 25.0, "a esquiva no ar não andou (%.0f)" % (p.global_position.x - x0))
	_check(absf(p.global_position.y - y0) < 3.0, "a esquiva no ar caiu (%.0f)" % (p.global_position.y - y0))

	await _load(tall)
	p = level.player
	input.then(["right", "roll"], 2).then(["right"], 8).then(["right", "jump"], 10).wait(20)
	await _frames(16)
	_check(not p.is_on_floor() and absf(p.velocity.x) > Player.RUN_SPEED, "o pulo não emendou o embalo da rolagem (%.0f)" % p.velocity.x)

	await _load(tall)
	p = level.player
	var e := _calm(level.spawn("grunt", p.global_position + Vector2(0, 0)))
	p.global_position.y -= 90.0
	input.wait(4).then(["down", "attack1"], 3).wait(20)
	var bounced := false
	for i in 40:
		await get_tree().physics_frame
		if p.velocity.y < -150.0:
			bounced = true
			break
	_check(bounced and e.hp < e.max_hp, "o mergulho não quicou no inimigo")


func _english() -> void:
	Lang.use("en")
	_check(Lang.t("Espada Cerimonial") == "CEREMONIAL SWORD", "nome de arma: " + Lang.t("Espada Cerimonial"))
	_check(Lang.t("12 INIMIGOS DERROTADOS") == "12 ENEMIES DEFEATED", "com número: " + Lang.t("12 INIMIGOS DERROTADOS"))
	_check(Lang.t("ARMA DE FÚRIA") == "FURY WEAPON", "ordem invertida: " + Lang.t("ARMA DE FÚRIA"))
	_check(Lang.t("ENTRAR: SEGUIR EM FRENTE") == "ENTER: PRESS ON", "montado: " + Lang.t("ENTRAR: SEGUIR EM FRENTE"))
	_check(Lang.t("MOKSHA") == "MOKSHA", "o nome do jogo mudou")
	var missing := {}
	for line in FileAccess.get_file_as_string("res://content/lang/en.txt").split("
"):
		if line.begins_with(";") or not line.contains(" = "):
			continue
		for ch in line.substr(line.find(" = ") + 3).to_upper():
			var base: String = PixelFont.ACCENTS[ch][0] if PixelFont.ACCENTS.has(ch) else ch
			if not PixelFont.BODY.has(base) and ch != " " and ch != "{" and ch != "}" and not "0123456789%".contains(ch):
				missing[ch] = true
	_check(missing.is_empty(), "letras sem desenho na fonte: " + str(missing.keys()))
	Lang.use("pt")
	_check(Lang.t("Espada Cerimonial") == "Espada Cerimonial", "voltar ao português não voltou")


func _updater() -> void:
	_check(Updater.newer("0.2.0", "0.1.0") and Updater.newer("v1.0.0", "0.9.9") and Updater.newer("0.1.10", "0.1.9"), "versão mais nova não reconhecida")
	_check(not Updater.newer("0.1.0", "0.1.0") and not Updater.newer("0.1.0", "0.2.0"), "versão igual ou mais velha passou por nova")
	_check(Updater.version == String(ProjectSettings.get_setting("application/config/version")), "versão do pacote não lida")
	_check(Updater.pending == "" and Updater.get_child_count() == 0, "o atualizador foi à rede nos testes")


func _chromas() -> void:
	Meta.use_path("user://teste.save", true)
	var s := Catalog.skin("andarilho")
	_check(s.chromas.size() == 4, "andarilho sem os 4 cromas")
	_check(Meta.has_chroma(s, "") and not Meta.has_chroma(s, "geada"), "croma veio liberado de graça")
	Meta.wear("andarilho", "geada")
	_check(Meta.chroma_of(s) == "", "vestiu croma que não tinha")
	await _load(FLAT)
	var keeper := Keeper.new()
	var offered := keeper._offers().map(func(o: Dictionary) -> String: return String(o["id"]))
	_check(offered.has("andarilho:geada"), "a Vigia não vende o croma")
	_check(not offered.has("manto_cinza:geada"), "a Vigia vende croma de aparência que não tem")
	keeper.free()
	Meta.unlock("andarilho:geada")
	Meta.wear("andarilho", "geada")
	Meta.use_path("user://teste.save")
	var look := Meta.current_look()
	var near := func(a: Color, b: Color) -> bool: return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.02
	_check(near.call(look["cloak"], Color("#9fc4dc")) and near.call(look["eye"], s.eye), "a cor do croma não chegou ao herói (ou trocou o olho)")
	_check(Meta.current_look()["closed_eyes"] == s.closed_eyes, "o croma mexeu no que não é cor")
	Meta.use_path("user://teste.save", true)


# Os testes de jogo não passam pela tela principal; este pega erro de
# compilação em qualquer script (um nome que colide com o do Godot, por exemplo).
func _all_scripts() -> void:
	var broken: Array[String] = []
	var dirs: Array[String] = ["res://scripts"]
	while not dirs.is_empty():
		var dir: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			dirs.append(dir.path_join(sub))
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".gd"):
				var script := load(dir.path_join(file)) as GDScript
				if script == null or not script.can_instantiate():
					broken.append(file)
	_check(broken.is_empty(), "não compilam: " + ", ".join(broken))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await _frames(5)
	_check(main.get("hud") != null and main.get("screen") != null, "a tela principal não montou")
	main.queue_free()
	await _frames(2)


# A pele de cada domínio carrega, tem todas as peças, a barra tem miolo onde
# pintar a vida, e o HUD desenha com ela sem erro.
func _hud_skins() -> void:
	var ids: Array = Catalog.BIOMES.keys()
	var seen := {}
	for id: String in ids:
		var s := HudSkin.of(id)
		_check(s.id == id, "%s caiu na pele padrão" % id)
		_check(s.tex != null, "%s sem textura" % id)
		for part: String in ["panel", "bar", "boss", "header", "slot", "gem"]:
			_check(s.part_size(part).x > 1.0, "%s sem a peça %s" % [id, part])
		var inner := s.inner_of("bar", Vector2.ZERO, Hud.BAR_W)
		_check(inner.size.x > Hud.BAR_W * 0.7 and inner.size.y >= 3.0, "%s: miolo da vida pequeno demais %s" % [id, inner])
		_check(s.part_size("slot").x <= 34.0, "%s: slot largo demais" % id)
		seen[s.tex.get_rid()] = true
	_check(seen.size() == ids.size(), "domínios repetindo a mesma pele")
	_check(HudSkin.of("nao_existe").id == HudSkin.FALLBACK, "domínio sem pele não caiu na padrão")
	await _load(FLAT)
	var hud := Hud.new()
	add_child(hud)
	hud.bind(level.player)
	for id: String in ids:
		hud.use_theme(id)
		hud.queue_redraw()
		await _frames(2)
	hud.queue_free()


func _credits() -> void:
	# a tecla que abre/fecha uma tela não vale para a próxima (Opções ligava a tela cheia; Esc começava a partida)
	Controls.lock_ui()
	_check(not Controls.ui_ready(), "a trava de interface não segurou a tecla")
	await _frames(5)
	_check(Controls.ui_ready(), "a trava de interface não soltou")
	var ids := Screen.TITLE_OPTIONS.map(func(o: Array) -> String: return String(o[0]))
	var extras := Screen.EXTRAS.map(func(o: Array) -> String: return String(o[0]))
	_check(ids.has("extras") and extras.has("credits"), "CRÉDITOS não está em EXTRAS no título")
	_check(ids.size() <= 8, "o menu do título voltou a crescer: %d itens" % ids.size())
	for f in ["res://content/creditos.txt", "res://content/creditos_en.txt"]:
		var text := FileAccess.get_file_as_string(f)
		for who in ["ANSIMUZ", "THEBLACKSWORD", "REDSHRIKE", "EMCEE FLESHER", "BALMER", "CALCIUMTRICE", "TIOPALADA", "CHIERIT", "LUIZ MELO", "PULSARCP", "CRAFTPIX"]:
			_check(text.contains(who), "%s sem crédito para %s" % [f, who])
	# todo inimigo com arte nova tem a folha colorida e os nomes que o script pede
	for sheet in ["penitent", "emperor", "colossus", "mother_root", "architect", "faceless_king", "astronomer", "wolf_king"]:
		_check(SpriteSheet.meta(sheet).get("color", false), "%s ainda é a folha antiga" % sheet)
