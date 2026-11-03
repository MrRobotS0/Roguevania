class_name Level
extends Node2D

# Um andar jogável: mapa, herói, inimigos, objetos, partículas e câmera.
# Monta a partir de um bioma (andar gerado, passagem ou sala do chefe) ou de
# um texto solto (testes). Não sabe nada de menus nem de save: só avisa
# quando o herói usa uma saída.

signal exit_used(dest: String)
signal boss_defeated

const AMBIENT := Color(0.56, 0.52, 0.6)
const PASSAGE_ROOM := "res://content/passagem.txt"
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
	_make_room(b)
	room.load_grid(lines)
	_populate(with_camera)
	Fx.banner(b.title.to_upper(), b.subtitle.to_upper())


# Entre um andar e outro: a Vigia, o altar de mutação e as saídas possíveis.
func build_passage(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value + 5
	tier = b.tier
	kind = "passagem"
	_make_room(b)
	room.load_file(PASSAGE_ROOM)
	_populate(with_camera)
	Fx.banner("A PASSAGEM", "A VIGIA ESPERA ONDE OS DOMÍNIOS SE TOCAM")


func build_boss(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value + 99
	tier = b.tier + 1 if Run.stage_id != "trono" else 6
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
	add_child(room)


func _populate(with_camera: bool) -> void:
	player = Player.new()
	player.room = room
	player.position = room.player_spawn
	explored.resize(room.cols * room.rows)
	explored.fill(0)

	for m in room.markers:
		_spawn_marker(m)
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
					spawn_script(path, at)
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
		"U":
			var altar := RuneAltar.new()
			altar.rune = biome.rune if biome and biome.rune != "" else "asa"
			_place(altar, at)


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
	drop_orbs(pos, roundi(n * _drop_mult()), "gold")


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
	Fx.toast("O ELITE DEIXOU ALGO PARA TRÁS")


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
