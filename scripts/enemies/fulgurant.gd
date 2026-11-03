class_name Fulgurant
extends Node2D

# Fulgurante: criatura de vidro fundido que vive sob a cinza. Não aparece;
# quando o herói pisa perto, o chão estala embaixo dele e um espinho sobe.

const RANGE := 72.0
const COOLDOWN := 2.4

var player: Player
var room: Room
var _cd := 1.0
var _glint := 0.0


func _physics_process(delta: float) -> void:
	_cd -= delta
	_glint += delta
	queue_redraw()
	if _cd > 0.0 or not is_instance_valid(player) or not player.alive():
		return
	var d := player.global_position - global_position
	if absf(d.x) > RANGE or absf(d.y) > 20.0 or not player.is_on_floor():
		return
	_cd = COOLDOWN
	var spike := Hazard.new()
	spike.player = player
	spike.style = "glass"
	spike.position = Vector2(player.global_position.x, global_position.y)
	get_parent().add_child(spike)


func _draw() -> void:
	for i in 3:
		var x := -40.0 + i * 37.0
		var c := Palette.GLASS
		c.a = 0.25 + 0.25 * sin(_glint * 2.0 + i * 2.1)
		draw_rect(Rect2(x, -1, 2, 1), c)
