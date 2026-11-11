class_name Level
extends Node2D

# Um andar jogável: mapa, herói, inimigos, objetos, partículas e câmera.
# Monta a partir de um bioma (andar gerado, passagem ou sala do chefe) ou de
# um texto solto (testes). Não sabe nada de menus nem de save: só avisa
# quando o herói usa uma saída.

signal exit_used(dest: String)
signal boss_defeated
signal station_used(kind: String)
signal guardian_appeared(guardian: Enemy)

const AMBIENT := Color(0.56, 0.52, 0.6)
const PASSAGE_ROOM := "res://content/passagem.txt"
const HALL_ROOM := "res://content/sala_treze.txt"
const BEIRA_ROOM := "res://content/beira.txt"
const WAVES_ROOM := "res://content/ondas.txt"
const STATIONS := {"1": "mantos", "2": "poco", "3": "carroca", "4": "marcas", "5": "braseiro"}
const TIMED_LIMIT := 150.0
const BLUEPRINT_CHANCE := 0.035

var biome: BiomeData
var room: Room
var player: Player
var camera: CameraRig
var boss: Enemy
var rng := RandomNumberGenerator.new()
var tier := 0
var kind := "teste"          # gerada | passagem | chefe | teste
var is_boss_room := false
var explored := PackedByteArray()   # 1 = o herói já viu esta célula (mapa)
var _lore_index := 0
var _after_boss: Array[Node2D] = []
var _exit_index := 0
var _explore_clock := 0.0
var seats: Array[GodSeat] = []
var director: WaveDirector
static var _beira_named := false


func build(room_text: String, with_camera := true) -> void:
	_make_room(null)
	room.load_text(room_text)
	_populate(with_camera)


func build_generated(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value
	tier = b.tier
	kind = "gerada"
	var gen := LevelGen.new()
	# em ordem de importância: as portas livres acabam
	var branches: Array = [["cofre", "K"], "loja", "fragmento", "tesouro", "tesouro"]
	if b.rune != "" and not Meta.has_rune(b.rune):
		branches.insert(0, "runa")
	var lines := gen.generate(LevelGen.load_dir(b.rooms_dir), seed_value, b.combat_rooms, branches)
	_note_pieces(gen)
	_make_room(b)
	room.load_grid(lines)
	_populate(with_camera)
	Fx.banner(b.title.to_upper(), b.subtitle.to_upper())


# De que sala do acervo veio cada pedaço do andar (para o robô e o debug
# dizerem onde algo aconteceu): [nome, retângulo em tiles do mapa montado]
var pieces: Array = []


func _note_pieces(gen: LevelGen) -> void:
	pieces.clear()
	if gen.placed.is_empty():
		return
	var box := Rect2i(gen.placed[0].rect())
	for p in gen.placed:
		box = box.merge(p.rect())
	box = box.grow(LevelGen.MARGIN)
	for p in gen.placed:
		pieces.append([String(p.t.name), Rect2i(p.pos - box.position, Vector2i(p.t.width, p.t.height))])


func piece_at(tile: Vector2i) -> String:
	for p in pieces:
		if (p[1] as Rect2i).has_point(tile):
			return p[0]
	return ""


# Entre um andar e outro: a Vigia, o altar de mutação e as saídas possíveis.
func build_passage(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value + 5
	tier = b.tier
	kind = "passagem"
	_make_room(b)
	room.load_file(PASSAGE_ROOM)
	_populate(with_camera)
	Fx.banner("A PASSAGEM", "A VIGIA ESPERA ONDE OS DOMÍNIOS SE TOCAM")


# Do outro lado da porta: as treze cadeiras. Sem inimigos.
func build_hall(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value
	tier = b.tier
	kind = "sala"
	_make_room(b)
	room.load_file(HALL_ROOM)
	_populate(with_camera)
	Fx.banner("A SALA DOS TREZE", "CADA BRASA É UM DEUS QUE NÃO CONSEGUE MORRER")


# Onde o herói renasce. Sem inimigos e sem relógio: a partida só começa no arco.
func build_beira(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value
	tier = 0
	kind = "beira"
	_make_room(b)
	room.load_file(BEIRA_ROOM)
	_populate(with_camera)
	# o nome do lugar só na primeira vez que o jogo abre: aqui se volta toda hora
	if not _beira_named:
		_beira_named = true
		Fx.banner("A BEIRA", "ONDE A CINZA VIRA VOCÊ DE NOVO")
	# o que está perto de sair: motivo para a próxima partida
	var next := Meta.closest_feat_text()
	if next != "" and int(Meta.data["runs"]) > 0:
		Fx.toast.call_deferred(next)


# Modo Waves: a arena cabe na tela, e quem manda nela é o diretor.
func build_waves(b: BiomeData, seed_value: int, block: int, with_camera := true) -> void:
	rng.seed = seed_value
	tier = mini(block, 6)
	kind = "ondas"
	_make_room(b)
	room.load_file(WAVES_ROOM)
	_populate(with_camera)
	director = WaveDirector.new()
	director.level = self
	add_child(director)


# O guardião do domínio, do lado oposto ao herói.
func spawn_guardian() -> void:
	var left := player.global_position.x > room.size_px().x * 0.5
	var at := Vector2(64.0 if left else room.size_px().x - 64.0, (room.rows - 4) * Room.TILE)
	boss = spawn_script(biome.boss_script, at)
	boss.set("arena", Rect2(Vector2(16, 0), room.size_px() - Vector2(32, 0)))
	boss.killed.connect(_on_boss_killed, CONNECT_DEFERRED)
	var sub: String = boss.get("subtitle") if boss.get("subtitle") else "O QUE VIU O FIM DE TUDO"
	Fx.banner(boss.title, sub)
	guardian_appeared.emit(boss)


func place_gate(title: String, dest: String, at: Vector2) -> void:
	var gate := ExitGate.new()
	gate.title = title
	gate.dest = dest
	gate.used.connect(func(d: String) -> void: exit_used.emit(d))
	_place(gate, at)


func seats_left() -> int:
	return seats.filter(func(s: GodSeat) -> bool: return not s.rested).size()


# Depois da virada: a Vigia senta na cadeira fria e sobra a última brasa.
func hall_reveal() -> void:
	seats[seats.size() - 1].light_up()


func build_boss(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value + 99
	tier = b.tier + 1 if Run.stage_id != "trono" else 7
	kind = "chefe"
	_make_room(b)
	is_boss_room = true
	# Chão extra embaixo: a câmera não cola o chão na borda da tela (o HUD fica ali).
	var lines := PackedStringArray()
	for line in FileAccess.get_file_as_string(b.boss_room).split("\n"):
		line = line.strip_edges(false, true)
		if line != "" and not line.begins_with(";"):
			lines.append(line)
	for i in 4:
		lines.append("#".repeat(lines[0].length()))
	room.load_grid(lines)
	_populate(with_camera)


func _make_room(b: BiomeData) -> void:
	biome = b
	room = Room.new()
	if b:
		room.colors = b.room_colors()
		room.tiles_id = b.id
	add_child(room)


func _populate(with_camera: bool) -> void:
	player = Player.new()
	player.room = room
	player.position = room.player_spawn
	explored.resize(room.cols * room.rows)
	explored.fill(0)

	var reserved: Variant = _pick_event()
	for m in room.markers:
		if is_same(m, reserved):
			_spawn_event(m["pos"])
		else:
			_spawn_marker(m)
	_maybe_thief()
	_name_portals()
	for spot in room.brazier_spots:
		var fire := Brazier.new()
		fire.position = spot
		add_child(fire)
	add_child(player)

	# O mundo fica na penumbra e as luzes (fogo, Essência, herói) devolvem a
	# cor. Partículas e números ficam numa camada própria, fora da sombra.
	var shade := CanvasModulate.new()
	shade.color = biome.sky.get("ambient", AMBIENT) if biome else AMBIENT
	add_child(shade)
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	overlay.follow_viewport_enabled = true
	add_child(overlay)
	overlay.add_child(Sparks.new())

	if with_camera:
		camera = CameraRig.new()
		add_child(camera)
		camera.follow(player, room.size_px())


# Evento: às vezes um Ladrão de Cinzas espera num canto do andar com um saco
# de ouro e Essência (só em andar gerado da partida normal ou dos desafios).
const THIEF_CHANCE := 0.45

# Evento do andar (no máximo um), no lugar de um inimigo longe do começo:
#   desafio: Pedra do Desafio (levas de inimigos por um item melhor)
#   pacto:   Altar do Pacto (vida por um item muito melhor)
#   errante: Mercador Errante (mais barato, aparece onde quer)
const EVENT_CHANCE := 0.6
const EVENTS := ["desafio", "pacto", "errante"]
var event := ""


func _pick_event() -> Variant:
	if kind != "gerada" or Run.mode == Run.WAVES or rng.randf() >= EVENT_CHANCE:
		return null
	var spots: Array = room.markers.filter(func(m: Dictionary) -> bool:
		return m["ch"] == "e" and (m["pos"] as Vector2).distance_to(room.player_spawn) > 320.0)
	if spots.is_empty():
		return null
	event = EVENTS[rng.randi_range(0, EVENTS.size() - 1)]
	return spots[rng.randi_range(0, spots.size() - 1)]


func _spawn_event(at: Vector2) -> void:
	match event:
		"desafio":
			_place(ChallengeStone.new(), at)
		"pacto":
			_place(PactAltar.new(), at)
		"errante":
			var m := Merchant.new()
			m.wandering = true
			_place(m, at)


func _maybe_thief() -> void:
	if kind != "gerada" or Run.mode == Run.WAVES or rng.randf() >= THIEF_CHANCE:
		return
	var spots: Array = room.markers.filter(func(m: Dictionary) -> bool:
		return m["ch"] == "e" and (m["pos"] as Vector2).distance_to(room.player_spawn) > 320.0)
	if spots.is_empty():
		return
	var at: Vector2 = spots[rng.randi_range(0, spots.size() - 1)]["pos"]
	var thief := spawn_script("res://scripts/enemies/ash_thief.gd", at + Vector2(10, 0))
	thief.killed.connect(func(e: Enemy) -> void:
		drop_gold(e.center(), 20 * (1 + tier))
		Fx.toast("SAQUE RECUPERADO"))


func _spawn_marker(m: Dictionary) -> void:
	var at: Vector2 = m["pos"]
	match m["ch"]:
		"g":
			spawn("grunt", at)
		"a":
			spawn("archer", at)
		"e", "r":
			if biome:
				var path := biome.pick_enemy(m["ch"], rng)
				if path != "":
					spawn_script(path, at, rng.randf() < Run.plus_elite_chance())
					if Run.has_rule("horda"):
						spawn_script(path, at + Vector2(-12.0 if rng.randf() < 0.5 else 12.0, 0.0))
		"E":
			if biome and not biome.elites.is_empty():
				var e := spawn_script(biome.elites[rng.randi_range(0, biome.elites.size() - 1)], at, true)
				e.killed.connect(_on_elite_killed)
		"B":
			if biome and biome.boss_script != "":
				boss = spawn_script(biome.boss_script, at)
				boss.set("arena", Rect2(Vector2(16, 0), room.size_px() - Vector2(32, 0)))
				boss.killed.connect(_on_boss_killed, CONNECT_DEFERRED)
				var sub: String = boss.get("subtitle") if boss.get("subtitle") else "O QUE VIU O FIM DE TUDO"
				Fx.banner(boss.title, sub)
		"i":
			var p := Pickup.new()
			p.gear = Catalog.random_gear(rng, tier)
			_place(p, at)
		"f":
			_place(Altar.new(), at)
		"L":
			var ins := Inscription.new()
			if biome and not biome.lore.is_empty():
				ins.text = biome.lore[_lore_index % biome.lore.size()]
				_lore_index += 1
				# Novo Jogo+: a primeira pedra conta como o domínio ficou
				if Run.plus > 0 and _lore_index == 1 and Story.AFTER.has(biome.id):
					ins.text = Story.AFTER[biome.id]
			_place(ins, at)
		"V":
			var k := Keeper.new()
			_place(k, at)
			if room.markers_of("B").size() > 0:
				_hide_until_victory(k)
		"X":
			_spawn_exit(at)
		"w":
			if biome and biome.hazard_script != "":
				var hz: Node2D = load(biome.hazard_script).new()
				hz.set("room", room)
				hz.set("player", player)
				hz.position = at
				add_child(hz)
		"M":
			_place(MutationAltar.new(), at)
		"c":
			var chest := Chest.new()
			chest.cursed = rng.randf() < 0.18 and tier > 0
			_place(chest, at)
		"$":
			_place(Merchant.new(), at)
		"T":
			var door := TimedDoor.new()
			door.level = self
			door.player = player
			door.limit = TIMED_LIMIT + 30.0 * tier
			door.position = at
			add_child(door)
		"O":
			_place(Portal.new(), at)
		"U":
			var altar := RuneAltar.new()
			altar.rune = biome.rune if biome and biome.rune != "" else "asa"
			_place(altar, at)
		"Y":
			var ids: Array = Story.SEATS.keys()
			if seats.size() < ids.size():
				var id: String = ids[seats.size()]
				var seat := GodSeat.new()
				seat.god = Story.god_name(id)
				seat.line = Story.SEATS[id]
				seat.color = Color(HudTheme.of(id)["accent"])
				seat.cold = id == "cavernas"
				seats.append(seat)
				_place(seat, at)
		"Z":
			_place(LastSeat.new(), at)
		"1", "2", "3", "4", "5":
			var station := Station.new()
			station.kind = STATIONS[m["ch"]]
			_place(station, at)
		"6":
			_place(Threshold.new(), at)
		"7":
			_scenery("poste", at, Color(1.0, 0.74, 0.4), Vector2(0, -92))
		"8":
			_scenery("estatua", at)
		"9":
			_scenery("cinzas", at)


# Cenário solto da Beira, atrás do herói.
func _scenery(anim: String, at: Vector2, glow := Color.TRANSPARENT, glow_at := Vector2.ZERO) -> void:
	var n := Node2D.new()
	n.position = at
	n.z_index = -1
	add_child(n)
	n.add_child(SpriteSheet.region_sprite("beira", PackedColorArray(), anim))
	if glow.a > 0.0:
		Glow.attach(n, glow, 70.0, 0.8, glow_at)


# Nome de cada portal pelo lugar: o do começo, o da saída e os do caminho.
func _name_portals() -> void:
	var list: Array[Portal] = []
	for n in get_children():
		if n is Portal:
			list.append(n)
	if list.is_empty():
		return
	var exits := room.markers_of("X")
	var goal: Vector2 = exits[0]["pos"] if not exits.is_empty() else room.size_px()
	var first := list[0]
	var last := list[0]
	for p in list:
		if p.position.distance_to(room.player_spawn) < first.position.distance_to(room.player_spawn):
			first = p
		if p.position.distance_to(goal) < last.position.distance_to(goal):
			last = p
	first.label = "O COMEÇO"
	first.found = true
	if last != first:
		last.label = "PERTO DA SAÍDA"
	var n := 0
	for p in list:
		if p.label == "":
			n += 1
			p.label = "PEDRA %s" % ["I", "II", "III", "IV", "V", "VI"][mini(n - 1, 5)]


func _spawn_exit(at: Vector2) -> void:
	var gate := ExitGate.new()
	var index := _exit_index
	_exit_index += 1
	match kind:
		"chefe":
			if index > 0:
				return
			var last := Run.stage_id == "trono"
			gate.title = "Fim da jornada" if last else "Seguir em frente"
			gate.dest = "fim" if last else "passagem"
			_hide_until_victory(gate)
		"passagem":
			var options := Run.next_options()
			if index >= options.size():
				return
			var dest: String = options[index]
			gate.dest = dest
			gate.title = Catalog.STAGE_NAMES.get(dest, dest)
			gate.hint = Catalog.STAGE_HINTS.get(dest, "")
		"gerada":
			var guardian := Run.boss_of(Run.stage_id)
			gate.title = "Enfrentar o guardião" if guardian != "" else "Seguir em frente"
			gate.dest = "boss" if guardian != "" else "passagem"
		_:
			gate.title = "Saída"
			gate.dest = "fim"
	gate.used.connect(func(dest: String) -> void: exit_used.emit(dest))
	_place(gate, at)


func _place(it: Interactable, at: Vector2) -> void:
	it.level = self
	it.position = at
	add_child(it)


func _hide_until_victory(n: Node2D) -> void:
	n.visible = false
	_after_boss.append(n)


func spawn(what: String, at: Vector2) -> Enemy:
	var path := "res://scripts/enemies/grunt.gd" if what == "grunt" else "res://scripts/enemies/archer.gd"
	return spawn_script(path, at)


func spawn_script(path: String, at: Vector2, elite := false) -> Enemy:
	var e: Enemy = load(path).new()
	e.room = room
	e.player = player
	e.position = at
	e.elite = elite
	e.facing = -1 if rng.randf() < 0.5 else 1
	if biome and biome.recolor.has(e.sheet) and e.look == "":
		e.look = biome.recolor[e.sheet]
	add_child(e)
	e.killed.connect(_on_enemy_killed)
	return e


func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemies")


# --- o que cai ---------------------------------------------------------------------

func _drop_mult() -> float:
	return 1.5 if is_instance_valid(player) and player.has_mutation("colecionador") else 1.0


func drop_orbs(pos: Vector2, n: int, what: String) -> void:
	for i in n:
		var orb := EssenceOrb.new()
		orb.kind = what
		orb.player = player
		orb.room = room
		orb.position = pos
		add_child.call_deferred(orb)


func drop_gold(pos: Vector2, n: int) -> void:
	drop_orbs(pos, roundi(n * _drop_mult() * (2.0 if Run.has_rule("fortuna") else 1.0)), "gold")


func drop_blueprint(pos: Vector2) -> bool:
	var carrying: Array = player.blueprints if is_instance_valid(player) else []
	var options := Catalog.unknown_blueprints(carrying)
	if options.is_empty():
		return false
	var bp := BlueprintDrop.new()
	bp.item = options[rng.randi_range(0, options.size() - 1)]
	bp.player = player
	bp.position = pos
	add_child.call_deferred(bp)
	return true


func _on_enemy_killed(e: Enemy) -> void:
	var n := roundi(rng.randi_range(e.essence_drop.x, e.essence_drop.y) * _drop_mult())
	drop_orbs(e.center(), n, "essence")
	drop_gold(e.center(), rng.randi_range(1, 3) * (1 + tier))
	if rng.randf() < BLUEPRINT_CHANCE:
		drop_blueprint(e.center())


func _on_elite_killed(e: Enemy) -> void:
	var p := Pickup.new()
	p.gear = Catalog.random_gear(rng, tier + 1)
	p.level = self
	p.position = e.global_position
	add_child.call_deferred(p)
	drop_blueprint(e.center() + Vector2(0, -8))


func _on_boss_killed(_e: Enemy) -> void:
	for n in _after_boss:
		n.visible = true
		Fx.burst(n.global_position + Vector2(0, -16), Palette.ESSENCE, 16, 100.0, 0.6, -40.0)
	drop_blueprint(_e.center())
	var after: String = _e.get("defeat_text") if _e.get("defeat_text") else "PELA PRIMEIRA VEZ EM MIL ANOS, ELE NÃO SABIA O QUE VINHA"
	Fx.banner(_e.title + " CAIU", after)
	boss_defeated.emit()


# --- mapa: o que o herói já viu ----------------------------------------------------

const SIGHT := 11


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or room == null:
		return
	room.reveal_near(player.center())
	_explore_clock -= delta
	if _explore_clock <= 0.0:
		_explore_clock = 0.15
		_explore(player.center())


func _explore(p: Vector2) -> void:
	var cx := floori(p.x / Room.TILE)
	var cy := floori(p.y / Room.TILE)
	for y in range(maxi(cy - SIGHT, 0), mini(cy + SIGHT + 1, room.rows)):
		for x in range(maxi(cx - SIGHT - 4, 0), mini(cx + SIGHT + 5, room.cols)):
			explored[y * room.cols + x] = 1


func seen(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < room.cols and y < room.rows and explored[y * room.cols + x] == 1
