class_name Level
extends Node2D

# Uma fase jogável: mapa, herói, inimigos, objetos, partículas e câmera.
# Monta a partir de um bioma (gerada ou sala do chefe) ou de um texto solto
# (testes). Não sabe nada de menus nem de save: só avisa quando termina.

signal exit_used(dest: String)
signal boss_defeated

var biome: BiomeData
var room: Room
var player: Player
var camera: CameraRig
var boss: Enemy
var rng := RandomNumberGenerator.new()
var tier := 0
var is_boss_room := false
var _lore_index := 0
var _after_boss: Array[Node2D] = []

const AMBIENT := Color(0.56, 0.52, 0.6)


func build(room_text: String, with_camera := true) -> void:
	_make_room(null)
	room.load_text(room_text)
	_populate(with_camera)


func build_generated(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value
	tier = b.tier
	var gen := LevelGen.new()
	var lines := gen.generate(LevelGen.load_dir(b.rooms_dir), seed_value, b.combat_rooms)
	_make_room(b)
	room.load_grid(lines)
	_populate(with_camera)
	Fx.banner(b.title.to_upper(), b.subtitle.to_upper())


func build_boss(b: BiomeData, seed_value: int, with_camera := true) -> void:
	rng.seed = seed_value + 99
	tier = b.tier + 1
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
				Fx.banner(boss.title, "O QUE VIU O FIM DE TUDO")
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
			var f := Fulgurant.new()
			f.room = room
			f.position = at
			f.player = player
			add_child(f)


func _spawn_exit(at: Vector2) -> void:
	var gate := ExitGate.new()
	var index := 0
	for other in get_children():
		if other is ExitGate:
			index += 1
	var is_boss_room := room.markers_of("B").size() > 0
	if is_boss_room:
		var exits := [
			{"title": "Fim da demonstração", "to": "fim", "sealed": false},
			{"title": "A Forja Rubra", "to": "forja_rubra", "sealed": true},
			{"title": "Os Salões do Último Inverno", "to": "saloes", "sealed": true},
		]
		var e: Dictionary = exits[mini(index, exits.size() - 1)]
		gate.title = e["title"]
		gate.dest = e["to"]
		gate.sealed = e["sealed"]
		_hide_until_victory(gate)
	elif biome and not biome.exits.is_empty():
		var e: Dictionary = biome.exits[mini(index, biome.exits.size() - 1)]
		gate.title = e["title"]
		gate.dest = e["to"]
		gate.sealed = e.get("sealed", false)
	else:
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


func spawn(kind: String, at: Vector2) -> Enemy:
	var path := "res://scripts/enemies/grunt.gd" if kind == "grunt" else "res://scripts/enemies/archer.gd"
	return spawn_script(path, at)


func spawn_script(path: String, at: Vector2, elite := false) -> Enemy:
	var e: Enemy = load(path).new()
	e.room = room
	e.player = player
	e.position = at
	e.elite = elite
	e.facing = -1 if rng.randf() < 0.5 else 1
	add_child(e)
	e.killed.connect(_on_enemy_killed)
	return e


func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemies")


func _on_enemy_killed(e: Enemy) -> void:
	var n := rng.randi_range(e.essence_drop.x, e.essence_drop.y)
	for i in n:
		var orb := EssenceOrb.new()
		orb.player = player
		orb.room = room
		orb.position = e.center()
		add_child.call_deferred(orb)


func _on_elite_killed(e: Enemy) -> void:
	var p := Pickup.new()
	p.gear = Catalog.random_gear(rng, tier + 1)
	p.level = self
	p.position = e.global_position
	add_child.call_deferred(p)
	Fx.toast("O INQUISIDOR DEIXOU ALGO PARA TRÁS")


func _on_boss_killed(_e: Enemy) -> void:
	for n in _after_boss:
		n.visible = true
		Fx.burst(n.global_position + Vector2(0, -16), Palette.ESSENCE, 16, 100.0, 0.6, -40.0)
	Fx.banner("O IMPERADOR CEGO CAIU", "PELA PRIMEIRA VEZ EM MIL ANOS, ELE NÃO SABIA O QUE VINHA")
	boss_defeated.emit()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and room:
		room.reveal_near(player.center())
