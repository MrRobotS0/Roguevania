extends Node2D

const ROOM_PATH := "res://rooms/treino.txt"

var level: Level
var hud: Hud


func _ready() -> void:
	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	back.add_child(Backdrop.new())

	var front := CanvasLayer.new()
	front.layer = 10
	add_child(front)
	hud = Hud.new()
	front.add_child(hud)

	restart()


func restart() -> void:
	Engine.time_scale = 1.0
	Fx.shake = 0.0
	if level:
		remove_child(level)
		level.queue_free()
	level = Level.new()
	add_child(level)
	level.build(FileAccess.get_file_as_string(ROOM_PATH))
	hud.bind(level.player)
	var current := level
	level.player.died.connect(func() -> void:
		await get_tree().create_timer(1.4).timeout
		if level == current:
			restart())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		restart()
	elif event.is_action_pressed("debug"):
		Fx.debug = not Fx.debug
