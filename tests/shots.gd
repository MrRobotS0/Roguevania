extends Node

# Abre o jogo de verdade (com janela), encena situações e salva prints.
# Godot --fixed-fps 60 --path . res://tests/shots.tscn -- --out=<pasta>

const MAIN := preload("res://scenes/main.tscn")

var out := "user://shots"
var main: Node2D


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	seed(7)
	main = MAIN.instantiate()
	add_child(main)

	await _scene("01_inicio", Vector2(4.5, 18), [], 30)
	await _scene("02_corrida", Vector2(4.5, 18), [[["right"], 40], [["right", "jump"], 14]], 54)
	await _scene("03_aviso_brutamontes", Vector2(31.5, 18), [[["right"], 6]], 40, "windup")
	await _scene("04_combo_critico", Vector2(31.5, 18), [[["right"], 4], [["attack"], 2], [[], 12], [["attack"], 2], [[], 12], [["attack"], 2]], 44)
	await _scene("05_arqueiro_mirando", Vector2(46.5, 18), [], 30, "aim")
	await _scene("06_beirada", Vector2(18.5, 18), [[["right"], 14], [["right", "jump"], 30]], 34)
	Fx.debug = true
	await _scene("07_debug", Vector2(36.5, 18), [[["attack"], 2]], 8)
	get_tree().quit()


func _scene(name: String, tile: Vector2, steps: Array, frames: int, wait_state := "") -> void:
	Fx.debug = name.ends_with("debug")
	main.restart()
	await get_tree().physics_frame
	var level: Level = main.level
	var p := level.player
	p.global_position = tile * Room.TILE
	level.camera.follow(p, level.room.size_px())
	var pad := ScriptedInput.new()
	for s in steps:
		pad.then(s[0], s[1])
	p.pad = pad

	if wait_state != "":
		var n := 0
		while n < 200 and not level.enemies().any(func(e: Enemy) -> bool: return e.state == wait_state):
			await get_tree().physics_frame
			n += 1
		frames = 14 if wait_state != "aim" else 40
	for i in frames:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(out.path_join(name + ".png"))
	print("print: ", name)
