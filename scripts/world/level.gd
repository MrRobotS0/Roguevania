class_name Level
extends Node2D

# Monta uma sala jogável: cenário, herói, inimigos, partículas e câmera.
# O jogo e os testes usam o mesmo caminho.

var room: Room
var player: Player
var camera: CameraRig


func build(room_text: String, with_camera := true) -> void:
	room = Room.new()
	add_child(room)
	room.load_text(room_text)

	player = Player.new()
	player.room = room
	player.position = room.player_spawn

	for s in room.spawns:
		spawn(s["kind"], s["pos"])
	add_child(player)
	add_child(Sparks.new())

	if with_camera:
		camera = CameraRig.new()
		add_child(camera)
		camera.follow(player, room.size_px())


func spawn(kind: String, at: Vector2) -> Enemy:
	var e: Enemy = Grunt.new() if kind == "grunt" else Archer.new()
	e.room = room
	e.player = player
	e.position = at
	add_child(e)
	return e


func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemies")
