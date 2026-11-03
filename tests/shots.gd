extends Node

# Abre o jogo de verdade (com janela), encena situações e salva prints.
#   Godot --fixed-fps 60 --path . res://tests/shots.tscn -- --out=<pasta> [--seed=N]
# Também salva mapa.png: a fase gerada inteira, 2 px por bloco.

const MAIN := preload("res://scenes/main.tscn")

var out := "user://shots"
var seed_value := 1234
var main: Node2D


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--seed="):
			seed_value = int(arg.trim_prefix("--seed="))
	DirAccess.make_dir_recursive_absolute(out)
	Meta.use_path("user://shots.save", true)
	seed(seed_value)
	main = MAIN.instantiate()
	add_child(main)

	await _frames(20)
	await _shot("01_titulo")
	main.screen.close()
	main.start_run(seed_value)
	var p: Player = main.level.player
	p.max_hp = 99999
	p.hp = 99999
	await _frames(50)
	await _shot("02_inicio")
	_save_map()

	await _near("ShieldGuard", "windup", "03_guarda_da_casa")
	await _near("Pilgrim", "ignite", "04_peregrino")
	await _near("Assassin", "rise", "05_assassino")
	await _near("Archer", "aim", "06_atirador")
	await _near("Inquisitor", "leap_windup", "07_inquisidor_elite", 120.0)

	main.weather._phase = "storm"
	main.weather.strength = 1.0
	main.weather.wind = 1.0
	await _frames(20)
	await _shot("08_tempestade")
	main.weather._phase = "calm"
	main.weather.strength = 0.0

	var altar := _first(func(n: Node) -> bool: return n is Altar)
	if altar:
		p.global_position = altar.global_position + Vector2(-14, 0)
		await _frames(10)
		await _shot("09_perto_do_altar")
		altar.interact(p)
		await _frames(4)
		await _shot("10_menu_fragmento")
		main.menu.close()

	var pick := _first(func(n: Node) -> bool: return n is Pickup)
	if pick:
		p.global_position = pick.global_position + Vector2(-12, 0)
		await _frames(10)
		await _shot("11_item_no_chao")

	Run.save_player(p)
	Run.advance()
	main._load_stage()
	p = main.level.player
	p.max_hp = 99999
	p.hp = 99999
	await _frames(40)
	await _shot("12_chefe_entrada")
	var boss: BlindEmperor = main.level.boss
	p.global_position.x = boss.global_position.x - 160.0
	var n := 0
	while boss.state != "cast" and n < 600:
		await get_tree().physics_frame
		n += 1
	await _frames(40)
	await _shot("13_chefe_profecia")
	boss.hurt(Damage.make(boss.hp - boss.max_hp / 2 + 5, 1, 0))
	await _frames(90)
	await _shot("14_chefe_fase_2")
	boss.hurt(Damage.make(99999, 1, 0))
	await _frames(70)
	await _shot("15_vitoria_saidas")
	var keeper := _first(func(k: Node) -> bool: return k is Keeper)
	if keeper:
		p.add_essence(80)
		keeper.interact(p)
		await _frames(4)
		await _shot("16_vigia")
		main.menu.close()
	main._pause()
	await _frames(4)
	await _shot("17_pausa")
	main.menu.close()
	p.hurt(Damage.make(999999, 1, 0))
	await _frames(100)
	await _shot("18_morte")
	Meta.use_path("user://shots.save", true)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _first(test: Callable) -> Node:
	for c in main.level.get_children():
		if test.call(c):
			return c
	return null


func _near(cls: String, wait_state: String, name: String, dist := 70.0) -> void:
	var target: Enemy = null
	for e in main.level.enemies():
		if e.get_script().get_global_name() == cls:
			target = e
			break
	if target == null:
		print("sem ", cls)
		return
	var p: Player = main.level.player
	p.global_position = target.global_position + Vector2(-dist, -2)
	p.velocity = Vector2.ZERO
	main.level.camera.follow(p, main.level.room.size_px())
	var n := 0
	while is_instance_valid(target) and target.state != wait_state and n < 400:
		await get_tree().physics_frame
		n += 1
	await _frames(8)
	await _shot(name)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(out.path_join(name + ".png"))
	print("print: ", name)


func _save_map() -> void:
	var room: Room = main.level.room
	var img := Image.create(room.cols * 2, room.rows * 2, false, Image.FORMAT_RGB8)
	var colors := {"#": Color("3a2f2a"), "=": Color("8a6242"), "F": Color("6a4fa0"), ".": Color("d8c8a8")}
	for y in room.rows:
		for x in room.cols:
			img.fill_rect(Rect2i(x * 2, y * 2, 2, 2), colors.get(room.grid[y][x], Color.WHITE))
	var marks := {"P": Color.GREEN, "e": Color.RED, "r": Color.ORANGE, "E": Color.MAGENTA, "i": Color.CYAN,
		"f": Color.YELLOW, "L": Color.WHITE, "X": Color.BLUE, "V": Color.BLUE, "w": Color.AQUA}
	for m in room.markers:
		var c: Vector2i = m["cell"]
		img.fill_rect(Rect2i(c.x * 2 - 1, c.y * 2 - 1, 4, 4), marks.get(m["ch"], Color.BLACK))
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(out.path_join("mapa.png"))
